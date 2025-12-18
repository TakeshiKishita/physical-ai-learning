# Isaac Sim AWS環境構築 - ベストプラクティス 2025

NVIDIAとAWSの最新ベストプラクティスに基づいた、Isaac Sim環境構築ガイドです。

## 最新の推奨事項（2025年）

## 0. 事前準備：AWS クォータ（制限）の確認と緩和【重要】

**このテンプレートを実行する前に、必ず以下の「サービス制限緩和申請」が必要です。**
新規のAWSアカウントでは、GPUインスタンス（Gシリーズ）の使用枠（vCPU）が「0」に設定されていることが多く、そのままではエラー（`CREATE_FAILED`）になります。

### 申請手順

1. AWSコンソールの **[Service Quotas](https://console.aws.amazon.com/servicequotas/home/services/ec2/quotas)** ページを開く。
2. 以下の項目を検索し、クォータ引き上げリクエストを行います。
   - **オンデマンド利用の場合**: `Running On-Demand G and VT instances`
   - **スポット利用の場合**: `All G and VT Spot Instance Requests`
3. **申請値**: `8` 以上 (g4dn.2xlarge は 8 vCPU 必要)
4. 承認されるまで待機（数分〜数時間）。

---

## 1. インスタンスタイプの選択（詳細）

#### NVIDIA推奨: G6eインスタンス（L40S GPU）

**最新の推奨構成**:

- **g6e.xlarge**: NVIDIA L40S GPU搭載
- **性能**: g4dnの約2倍
- **用途**: 本番環境、高性能が必要な場合

**個人学習用推奨**:

- **g4dn.2xlarge**: T4 GPU搭載, 32GB RAM（Deep Learning AMI使用時）
- **性能**: 基本的な学習には十分
- **用途**: 個人学習・開発環境（推奨）

**※AMIに関する重要事項**:
現在のIsaac Sim公式AMIはg4dnをサポートしていないため、**Deep Learning OSS Nvidia Driver AMI**を使用し、Isaac Simを手動インストールする構成を推奨します。

### 1.1 Isaac Sim インストール手順 (Deep Learning AMI 利用時)

Deep Learning AMI には Isaac Sim が含まれていないため、インスタンス起動後に以下のいずれかの方法でインストールが必要です。

#### A. Container Installation (推奨: 軽量・高速)

Docker コンテナとして実行する方法です。学習用途に最適です。

1. **NVIDIA Container Toolkit の確認**:

   ```bash
   nvidia-smi
   # Deep Learning AMI にはドライバとToolkitが含まれています
   ```

2. **NGC カタログから Pull**:

   ```bash
   # NGC API Key が必要です (NVIDIA NGCで無料取得可能)
   docker login nvcr.io
   docker pull nvcr.io/nvidia/isaac-sim:2023.1.1 # バージョンは最新を確認
   ```

3. **実行**:

   ```bash
   docker run --name isaac-sim --entrypoint ./runheadless.native.sh --gpus all -e "ACCEPT_EULA=Y" --rm -v /home/ubuntu/isaac-sim/cache/ov:/root/.cache/ov:rw -v /home/ubuntu/isaac-sim/cache/pip:/root/.cache/pip:rw -v /home/ubuntu/isaac-sim/logs:/root/.nvidia-omniverse/logs:rw -v /home/ubuntu/isaac-sim/config:/root/.nvidia-omniverse/config:rw -v /home/ubuntu/isaac-sim/data:/root/.local/share/ov/data:rw -v /home/ubuntu/isaac-sim/documents:/root/Documents:rw -p 4700-4900:4700-4900/tcp -p 4700-4900:4700-4900/udp nvcr.io/nvidia/isaac-sim:2023.1.1
   ```

   > 詳細は [Isaac Sim Container Installation Guide](https://docs.omniverse.nvidia.com/isaacsim/latest/installation/install_container.html) を参照。

#### B. Omniverse Launcher Installation (GUI必要)

VNC 等でデスクトップ接続し、GUI ランチャーからインストールする方法です。

1. **Omniverse Launcher のダウンロード**:
   公式サイトから Linux 版をダウンロード。
2. **インストールとログイン**:
   ランチャーを起動し、NVIDIA アカウントでログイン。
3. **Isaac Sim のインストール**:
   "Exchange" タブから Isaac Sim を検索してインストール。

---

#### インスタンス比較

| タイプ | GPU | VRAM | コスト/時間 | 推奨用途 |
|--------|-----|------|------------|---------|
| g4dn.2xlarge | T4 | 16GB | ~$0.71 | ⭐ 個人学習（DL AMI） |
| g5.2xlarge | A10G | 24GB | ~$1.21 | 性能重視 |
| g6e.xlarge | L40S | 48GB | ~$1.60+ | 本番環境 |

### 2. Isaac Simの最適化

#### 起動時間の最適化

NVIDIAフォーラムで推奨されている最適化:

1. **カスタムAMIの使用**
   - Isaac SimプリインストールAMIを使用
   - 初回起動時間を短縮

2. **キャッシュの永続化**
   - EBSボリュームにキャッシュを保存
   - 再起動時の起動時間を短縮

3. **カスタムフォルダの使用**
   - `/home/ubuntu/.nvidia-omniverse` をEBSにマウント

### 3. AWSとNVIDIAの統合

#### NVIDIA Omniverse Cloud

- AWS上でOmniverseアプリケーションを実行
- クラウドネイティブなワークフロー
- スケーラブルなシミュレーション環境

#### AWS Systems Manager統合

- SSH不要でセキュアに接続
- パッチ管理の自動化
- セッション管理

### 4. コスト最適化（個人学習用）

#### 必須の最適化

1. **スポットインスタンス**: 最大90%削減
2. **自動停止**: 使用していない時は停止
3. **適切なインスタンスサイズ**: g4dn.2xlarge (DL AMI使用)

#### 推奨設定

```yaml
InstanceType: g4dn.2xlarge
UseSpotInstance: true
AutoShutdownEnabled: true
VolumeSize: 150 # 推奨、最小128GB
```

## プロジェクトの準拠状況

### ✅ 準拠している項目

1. **CloudFormationテンプレート**: 最新のベストプラクティス準拠
2. **セキュリティ**: IMDSv2、EBS暗号化、適切なIAMロール
3. **コスト最適化**: スポットインスタンス、自動停止機能
4. **モニタリング**: CloudWatch統合
5. **最新インスタンスタイプ**: G6eオプション追加

### 🔄 改善済み項目

1. **スポットインスタンスサポート**: 追加済み
2. **自動停止機能**: 追加済み（CloudWatch Alarm → EC2 Stop Action）
3. **最新インスタンスタイプ**: G6e追加
4. **コスト最適化ドキュメント**: 作成済み

### 📋 今後の検討事項

1. **Isaac Orbit統合**: 学習フレームワークの統合
2. **S3バックアップ自動化**: USDファイルの自動バックアップ
3. **複数環境サポート**: Week1-4用の環境分離

## ベストプラクティスチェックリスト

### セキュリティ

- [x] IMDSv2の強制
- [x] EBS暗号化
- [x] 適切なセキュリティグループ
- [x] IAMロールの最小権限
- [x] CIDR制限（推奨）

### コスト最適化

- [x] スポットインスタンスオプション
- [x] 自動停止機能
- [x] 適切なインスタンスサイズ
- [x] EBS最適化（gp3）
- [x] リソースタグ付け

### 運用性

- [x] CloudFormationテンプレート
- [x] 自動化スクリプト
- [x] CloudWatchモニタリング
- [x] Systems Manager統合
- [x] ドキュメント整備

### パフォーマンス

- [x] 最新インスタンスタイプオプション（G6e）
- [x] 詳細モニタリング
- [x] EBS IOPS最適化

## 個人学習用の推奨構成

### 最小コスト構成

```json
{
  "InstanceType": "g4dn.2xlarge",
  "UseSpotInstance": "true",
  "AutoShutdownEnabled": "true",
  "VolumeSize": "150"
}
```

**月額コスト**: 約 $40-60（1日2-3時間使用）

### バランス構成

```json
{
  "InstanceType": "g4dn.2xlarge",
  "UseSpotInstance": "false",
  "AutoShutdownEnabled": "true",
  "VolumeSize": "150"
}
```

**月額コスト**: 約 $120-160（1日4-5時間使用）

### 高性能構成（必要時のみ）

```json
{
  "InstanceType": "g6e.xlarge",
  "UseSpotInstance": "true",
  "AutoShutdownEnabled": "true",
  "VolumeSize": "150"
}
```

**月額コスト**: 約 $40-60（スポット使用、1日2-3時間）

## 参考資料

- [NVIDIA Isaac Sim Documentation](https://docs.nvidia.com/isaac/isaac-sim/index.html)
- [AWS EC2 Best Practices](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-best-practices.html)
- [NVIDIA Omniverse on AWS](https://www.nvidia.com/ja-jp/omniverse/enterprise/aws/)
- [AWS Cost Optimization](https://aws.amazon.com/jp/aws-cost-management/)

## まとめ

現在のプロジェクトは、**個人学習用として最適化された、最新のベストプラクティスに準拠したソリューション**です。

### 主な特徴

1. ✅ **コスト最適化**: スポットインスタンス + 自動停止
2. ✅ **最新技術**: G6eインスタンスオプション、IMDSv2
3. ✅ **セキュリティ**: ベストプラクティス準拠
4. ✅ **運用性**: 完全自動化、ドキュメント整備
5. ✅ **学習効率**: 最小コストで最大の学習効果

**個人学習用としては最強のソリューション**と言えます。
