# Week 1：World Model ─ シミュレーションとしての「世界」を理解する

## 目的

- NVIDIA Isaac Sim をクラウド上で起動できるようにする
- Ground / Box / Robot / Camera を含む **最小の仮想世界** を構築する
- 物理シミュレーション（重力・衝突）の挙動を観察する
- 「AIにとっての世界 = 物理シミュレータ」という感覚を掴む

---

## 前提条件

- AWS アカウント & AWS CLI 設定済み
- GPU付きインスタンス（例: `g4dn.xlarge`）を利用可能
- NVIDIA Isaac Sim / Omniverse 用 AMI を把握している
- CloudFormation テンプレート・パラメータファイルが準備済み

---

## タスク一覧

### Task 1-1：Isaac Sim 用 EC2 インスタンスの起動（CloudFormation）

**ゴール:** CloudFormation を使って GPU 付き EC2 インスタンスを自動構築する。

#### 1. パラメータファイルの確認・編集

`cloudformation/parameters.json` を編集：

```json
[
  {
    "ParameterKey": "InstanceType",
    "ParameterValue": "g4dn.xlarge"
  },
  {
    "ParameterKey": "AMIId",
    "ParameterValue": "ami-083436b6b99e9e44e"  // 東京リージョンのIsaac Sim AMI
  },
  {
    "ParameterKey": "KeyPairName",
    "ParameterValue": "isaac-sim-keypair"  // 既存のキーペア名
  },
  {
    "ParameterKey": "AllowedSSHCIDR",
    "ParameterValue": "0.0.0.0/0"  // セキュリティのため自分のIP/32推奨
  },
  {
    "ParameterKey": "AllowedVNCCIDR",
    "ParameterValue": "0.0.0.0/0"  // セキュリティのため自分のIP/32推奨
  },
  {
    "ParameterKey": "VolumeSize",
    "ParameterValue": "150"
  },
  {
    "ParameterKey": "UseSpotInstance",
    "ParameterValue": "false"  // 初回は安定性のためオンデマンド推奨
  },
  {
    "ParameterKey": "SpotInstanceMaxPrice",
    "ParameterValue": "0.10"
  },
  {
    "ParameterKey": "AutoShutdownEnabled",
    "ParameterValue": "true"  // コスト削減のため有効化推奨
  }
]
```

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

### Task 1-2：Isaac Sim GUI の起動とシンプルな物理シミュレーション

**ゴール:** Isaac Sim の GUI を開き、Box が落下するシンプルなシミュレーションを実行する。

#### 1. EC2 インスタンスにリモート接続

##### 方法A: SSH + VNC（推奨）

```bash
# SSH接続
ssh -i ~/.ssh/isaac-sim-keypair.pem ubuntu@<PUBLIC_IP>

# VNCサーバーの起動（インスタンス内で実行）
vncserver :1 -geometry 1920x1080 -depth 24
```

ローカルPCから VNC クライアント（TigerVNC, RealVNC等）で接続：

- アドレス: `<PUBLIC_IP>:5901`

##### 方法B: AWS Systems Manager Session Manager

```bash
# SSH鍵不要でブラウザから接続
aws ssm start-session --target <INSTANCE_ID>
```

#### 2. Isaac Sim を起動

```bash
cd ~/isaac-sim
./isaac-sim.sh &
```

> **Note**: 初回起動は数分かかる場合があります。

#### 3. GUI操作

1. `File > New` で新規シーン作成
2. `Create > Physics` から **Ground Plane** を追加
3. `Create > Mesh > Cube` で **Box** を追加（床の上・少し上に配置）
4. **Play** ボタン（▶）を押し、Box が重力で落下・床と衝突する様子を確認

#### 4. 観察内容を記録

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

- **Ground Plane**: 床
- **Table**: 机（`Create > Mesh > Cube` をスケールして机に見立てる、または既存アセット）
- **Box**: 机の上に配置
- **Robot Arm**: 例: Franka Emika（`Isaac Examples > Franka` から追加）
- **Camera**: 机とロボットを俯瞰できる位置に配置

#### 2. カメラビュー調整

カメラビューで机・ロボット・Box が視界に入るように調整。

#### 3. シーンを保存

- `File > Save As`
- ファイル名: `week1_minimal_world.usd`
- 保存先: `~/isaac-sim/scenes/` など

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

echo "Stopped instance: <INSTANCE_ID>" >> logs/week1_env_checklist.md
```

#### オプション2: スタック完全削除（完全にクリーンアップ）

```bash
# すべてのリソースを削除
./scripts/cloudformation_destroy.sh

echo "Terminated CloudFormation stack" >> logs/week1_env_checklist.md
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

### VNC接続ができない

1. セキュリティグループでポート5900-5910が開いているか確認
2. `parameters.json` の `AllowedVNCCIDR` を確認
3. VNCサーバーが起動しているか確認: `vncserver -list`

### Isaac Sim が起動しない

1. GPU ドライバーを確認: `nvidia-smi`
2. Isaac Sim のログを確認: `~/isaac-sim/logs/`
3. AMI が正しいか確認（Isaac Sim プリインストール版）

### 自動停止されてしまった

- CPU使用率が5%未満が2時間続くと自動停止します
- `AutoShutdownEnabled: false` に設定するか、定期的に作業して CPU を使用してください

---

## 参考リソース

- [CloudFormation テンプレートリファレンス](../docs/CLOUDFORMATION_TEMPLATE_REFERENCE.md)
- [AWS CloudFormation ガイド](../docs/AWS_CLOUDFORMATION_GUIDE.md)
- [コスト最適化ガイド](../docs/COST_OPTIMIZATION_GUIDE.md)
