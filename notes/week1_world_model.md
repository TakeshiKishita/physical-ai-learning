# Week 1：World Model ─ シミュレーションとしての「世界」を理解する

## 目的

- NVIDIA Isaac Sim をクラウド上で起動できるようにする
- Ground / Box / Robot / Camera を含む **最小の仮想世界** を構築する
- 物理シミュレーション（重力・衝突）の挙動を観察する
- 「AIにとっての世界 = 物理シミュレータ」という感覚を掴む

---

## 前提条件

- AWS アカウント & AWS CLI 設定済み
- GPU付きインスタンス（最小: `g4dn.2xlarge`、T4 GPU / 32GB RAM）を利用可能
- Deep Learning OSS Nvidia Driver AMI（Ubuntu 22.04）を使用
- Isaac Sim は Docker コンテナとしてインストール（[手順](../docs/BEST_PRACTICES.md)）
- CloudFormation テンプレート・パラメータファイルが準備済み

> **Note（GPU要件について）**: Isaac Sim の公式最小要件は RTX 3070（8GB VRAM）です。
> T4（g4dn）は公式最小要件を下回りますが、ヘッドレスモードでの基本的な物理シミュレーションや
> RL学習には利用実績があります。レンダリング品質やストリーミング性能には制限が生じる場合があります。
> より安定した環境が必要な場合は `g5.2xlarge`（A10G GPU）の利用を検討してください。

---

## タスク一覧

### Task 1-1：Isaac Sim 用 EC2 インスタンスの起動（CloudFormation）

**ゴール:** CloudFormation を使って GPU 付き EC2 インスタンスを自動構築する。

#### 1. パラメータファイルの確認・編集

`cloudformation/parameters.json` を確認・編集：

```json
[
  {
    "ParameterKey": "InstanceType",
    "ParameterValue": "g4dn.2xlarge"
  },
  {
    "ParameterKey": "AMIId",
    "ParameterValue": "ami-089e22c42ee7843a2"
  },
  {
    "ParameterKey": "KeyPairName",
    "ParameterValue": "isaac-sim-keypair"
  },
  {
    "ParameterKey": "AllowedSSHCIDR",
    "ParameterValue": "0.0.0.0/0"
  },
  {
    "ParameterKey": "AllowedVNCCIDR",
    "ParameterValue": "0.0.0.0/0"
  },
  {
    "ParameterKey": "VolumeSize",
    "ParameterValue": "150"
  },
  {
    "ParameterKey": "UseSpotInstance",
    "ParameterValue": "false"
  },
  {
    "ParameterKey": "SpotInstanceMaxPrice",
    "ParameterValue": ""
  },
  {
    "ParameterKey": "AutoShutdownEnabled",
    "ParameterValue": "true"
  }
]
```

> **Note**:
> - `AMIId`: Deep Learning OSS Nvidia Driver AMI（東京リージョン）。最新の AMI ID は AWS Marketplace で確認してください。
> - `AllowedSSHCIDR` / `AllowedVNCCIDR`: セキュリティのため自分のIP/32を推奨。
> - `UseSpotInstance`: 初回は安定性のためオンデマンド（`false`）推奨。

#### 2. CloudFormation スタックのデプロイ

```bash
# プロジェクトルートディレクトリで実行
cd ~/physical-ai-learning

# デプロイスクリプトを実行
./scripts/cloudformation_deploy.sh
```

#### 3. デプロイ完了の確認

```bash
# スタック情報の確認
./scripts/cloudformation_info.sh
```

出力例：

```bash
Instance ID: i-0123456789abcdef0
Public IP: 203.0.113.42
SSH Command: ssh -i ~/.ssh/isaac-sim-keypair.pem ubuntu@203.0.113.42
```

#### 4. ログへ記録

```bash
# インスタンス情報をログに記録
echo "## Week 1 環境構築" > logs/week1_env_checklist.md
echo "" >> logs/week1_env_checklist.md
./scripts/cloudformation_info.sh >> logs/week1_env_checklist.md
```

---

### Task 1-2：Isaac Sim の起動とシンプルな物理シミュレーション

**ゴール:** Isaac Sim を起動し、Box が落下するシンプルなシミュレーションを実行する。

#### 1. EC2 インスタンスに接続

```bash
# SSH接続
ssh -i ~/.ssh/isaac-sim-keypair.pem ubuntu@<PUBLIC_IP>
```

#### 2. Isaac Sim コンテナを起動

```bash
# NGC にログイン（初回のみ）
# ユーザー名: $oauthtoken / パスワード: NGC API Key
docker login nvcr.io

# Isaac Sim コンテナを pull & 起動
docker pull nvcr.io/nvidia/isaac-sim:4.5.0
docker run --name isaac-sim \
  --entrypoint bash \
  --gpus all \
  -e "ACCEPT_EULA=Y" \
  -e "PRIVACY_CONSENT=Y" \
  --rm --network=host \
  -v ~/isaac-sim/cache/kit:/isaac-sim/kit/cache:rw \
  -v ~/isaac-sim/cache/ov:/root/.cache/ov:rw \
  -v ~/isaac-sim/cache/pip:/root/.cache/pip:rw \
  -v ~/isaac-sim/cache/glcache:/root/.cache/nvidia/GLCache:rw \
  -v ~/isaac-sim/cache/computecache:/root/.nv/ComputeCache:rw \
  -v ~/isaac-sim/logs:/root/.nvidia-omniverse/logs:rw \
  -v ~/isaac-sim/config:/root/.nvidia-omniverse/config:rw \
  -v ~/isaac-sim/data:/root/.local/share/ov/data:rw \
  -v ~/isaac-sim/documents:/root/Documents:rw \
  nvcr.io/nvidia/isaac-sim:4.5.0 \
  -c "./runheadless.sh"
```

> **Note**:
> - バージョンは [NGC Isaac Sim カタログ](https://catalog.ngc.nvidia.com/orgs/nvidia/containers/isaac-sim) で最新版を確認してください。
> - 初回起動はシェーダーコンパイル等で数分〜十数分かかる場合があります。
> - `--network=host` を使用するため、ポートマッピングは不要です。セキュリティグループ側でポート制御を行います。

#### 3. ブラウザから WebRTC Streaming で接続

Isaac Sim 4.5.0 以降では、ブラウザベースの WebRTC ストリーミングで GUI を操作できます。

```
http://<PUBLIC_IP>:8211/streaming/webrtc-client?server=<PUBLIC_IP>
```

> **Note**: セキュリティグループでポート 8211 が許可されている必要があります。

#### 4. GUI操作

1. `File > New` で新規シーン作成
2. `Create > Physics` から **Ground Plane** を追加
3. `Create > Shape > Cube` で **Box** を追加（床の上・少し上に配置）
4. **Play** ボタンを押し、Box が重力で落下・床と衝突する様子を確認

#### 5. 観察内容を記録

```markdown
## 物理シミュレーション観察メモ

- 重力方向: -Z（デフォルト）
- Box と Ground の衝突時の挙動: [自分の観察内容]
- Box の反発 / 滑り具合（摩擦・反発係数の初期値）: [自分の観察内容]
- シミュレーション速度: Real-time / Slow-motion / Fast-forward
```

これを `logs/week1_physics_observation.md` に保存。

---

### Task 1-3：最小 Digital Twin シーンの構築

**ゴール:** 床・机・箱・ロボット・カメラを含む「ミニ世界」を構築し、USD として保存する。

#### 1. Isaac Sim GUI 上で以下を配置

- **Ground Plane**: 床（`Create > Physics > Ground Plane`）
- **Table**: 机（`Create > Shape > Cube` をスケールして机に見立てる、または既存アセット）
- **Box**: 机の上に配置（`Create > Shape > Cube`）
- **Robot Arm**: 例: Franka Emika（`Create > Robots > Franka Emika Panda Arm`）
- **Camera**: 机とロボットを俯瞰できる位置に配置

#### 2. カメラビュー調整

カメラビューで机・ロボット・Box が視界に入るように調整。

#### 3. シーンを保存

- `File > Save As`
- ファイル名: `week1_minimal_world.usd`
- 保存先: `~/isaac-sim/documents/` など（コンテナのボリュームマウント先）

#### 4. シーン構成メモ

```markdown
## week1_minimal_world.usd の構成

- Ground Plane: (0, 0, 0)
- Table: 原点付近に設置、高さ ~0.75m
- Box: Table の上、ロボットの可動範囲内
- Robot: Table の側面に設置（Franka）
- Camera: 上部からの俯瞰視点（Table + Robot + Box が見える）
```

これを `logs/week1_scene_structure.md` に保存。

---

### Task 1-4：EC2 の停止 / 終了

**ゴール:** 不要な課金を防ぐため、インスタンスを停止または終了する。

#### オプション1: インスタンス停止（再利用可能）

```bash
# インスタンスIDを確認
./scripts/cloudformation_info.sh

# 停止（EBS料金のみ発生、EC2料金は0円）
aws ec2 stop-instances --instance-ids <INSTANCE_ID>
```

#### オプション2: スタック完全削除（完全にクリーンアップ）

```bash
# すべてのリソースを削除
./scripts/cloudformation_destroy.sh
```

> **Note**:
>
> - **停止**: データ保持、再起動可能、EBS料金のみ
> - **削除**: すべて削除、データ消失、課金完全停止

---

## Week 1 のふりかえりテンプレ

```markdown
### Week 1 ふりかえり

- Isaac Sim 起動で詰まった点:
- シミュレーション環境で驚いた / 気づいた点:
- Physical AI（世界モデル）観点で理解が深まったこと:
- 来週（Week 2）で意識したいこと:
```

これを `logs/week1_reflection.md` に保存。

---

## トラブルシューティング

### WebRTC Streaming で接続できない

1. セキュリティグループでポート 8211 が開いているか確認
2. `parameters.json` の `AllowedVNCCIDR` を確認（Streaming用ポートもこのCIDRで制御）
3. Isaac Sim コンテナが正常に起動しているか確認: `docker logs isaac-sim`
4. ブラウザの URL が正しいか確認: `http://<IP>:8211/streaming/webrtc-client?server=<IP>`

### VNC接続ができない

1. セキュリティグループでポート5900-5910が開いているか確認
2. `parameters.json` の `AllowedVNCCIDR` を確認
3. VNCサーバーが起動しているか確認: `vncserver -list`

### Isaac Sim が起動しない

1. GPU ドライバーを確認: `nvidia-smi`
2. Docker コンテナのログを確認: `docker logs isaac-sim`
3. NVIDIA Container Toolkit がインストールされているか確認: `docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi`
4. T4 GPU の場合、レンダリング負荷が高いシーンで問題が起きやすい。ヘッドレスモードを試す。

### 自動停止されてしまった

- CPU使用率が5%未満が2時間続くと自動停止します
- `AutoShutdownEnabled: false` に設定するか、定期的に作業して CPU を使用してください

---

## 参考リソース

- [Isaac Sim Container Installation Guide](https://docs.isaacsim.omniverse.nvidia.com/latest/installation/install_container.html)
- [Isaac Sim Requirements](https://docs.isaacsim.omniverse.nvidia.com/latest/installation/requirements.html)
- [環境構築ベストプラクティス](../docs/BEST_PRACTICES.md)
- [CloudFormation テンプレートリファレンス](../docs/CLOUDFORMATION_TEMPLATE_REFERENCE.md)
- [AWS CloudFormation ガイド](../docs/AWS_CLOUDFORMATION_GUIDE.md)
- [コスト最適化ガイド](../docs/COST_OPTIMIZATION_GUIDE.md)
