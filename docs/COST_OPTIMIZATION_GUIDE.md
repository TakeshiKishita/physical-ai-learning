# コスト最適化ガイド - 個人学習用

個人学習用のIsaac Sim環境でコストを抑えつつ、効率的にPhysical AIを学ぶための最適化ガイドです。

## コスト削減の基本戦略

### 1. インスタンスタイプの選択

| インスタンスタイプ | GPU | 性能 | コスト/時間（東京） | 推奨用途 |
|------------------|-----|------|-------------------|---------|
| **g4dn.xlarge** | T4 | 標準 | ~$0.526 | ⭐ **学習用推奨**（コストパフォーマンス最良） |
| g4dn.2xlarge | T4 | 高 | ~$0.752 | より大きなシミュレーション |
| g5.xlarge | A10G | 高 | ~$1.006 | 高性能が必要な場合 |
| **g6e.xlarge** | L40S | 最高 | ~$1.20+ | 最新機能・最高性能が必要な場合 |

**推奨**: 個人学習では `g4dn.xlarge` が最適です。
- 十分な性能でIsaac Simが動作
- コストが最も低い
- 学習目的には過不足なし

### 2. スポットインスタンスの活用 ⭐ 最大90%削減

スポットインスタンスを使用すると、最大90%のコスト削減が可能です。

#### メリット
- **大幅なコスト削減**: 通常の10-30%の価格
- **学習用途に最適**: 中断されても問題ない作業に適している

#### デメリット
- **中断の可能性**: AWSが必要に応じてインスタンスを停止
- **データ損失リスク**: 中断時に保存していないデータは失われる

#### 使用方法

`cloudformation/parameters.json` で設定：

```json
{
  "ParameterKey": "UseSpotInstance",
  "ParameterValue": "true"
},
{
  "ParameterKey": "SpotInstanceMaxPrice",
  "ParameterValue": "0.10"
}
```

#### 中断への対策

1. **定期的な保存**: 作業は定期的に保存
2. **USDファイルのバックアップ**: シーンファイルをS3に保存
3. **中断通知の設定**: CloudWatchで中断を監視

### 3. 自動停止機能 ⭐ 必須

使用していない時にインスタンスを自動停止することで、大幅なコスト削減が可能です。

#### 設定方法

デフォルトで有効になっています（`AutoShutdownEnabled: true`）。

- **動作**: CPU使用率が5%未満が2時間続くと自動停止
- **再起動**: `scripts/cloudformation_info.sh` で確認後、手動で再起動

#### コスト削減効果

| 使用パターン | 月額コスト（g4dn.xlarge） |
|------------|-------------------------|
| 24時間稼働 | ~$380 |
| 1日8時間使用 | ~$127 |
| **自動停止あり（実質4時間/日）** | **~$63** |

### 4. 使用時間の最適化

#### 推奨パターン

1. **集中学習時間を設定**: 1日2-4時間の集中学習
2. **作業前に起動**: 必要な時だけ起動
3. **作業後は即停止**: 作業終了後はすぐに停止

#### スクリプト活用

```bash
# 起動
./scripts/cloudformation_deploy.sh

# 作業...

# 停止（課金停止）
./scripts/cloudformation_destroy.sh  # または stop_instance.sh
```

### 5. EBSボリュームの最適化

- **最小サイズ**: 20GBから開始（必要に応じて拡張）
- **gp3タイプ**: デフォルトでgp3（コスト効率が良い）
- **削除設定**: `DeleteOnTermination: true` で不要なボリュームを自動削除

### 6. リージョンの選択

| リージョン | コスト（g4dn.xlarge/時間） | レイテンシ |
|-----------|-------------------------|-----------|
| 東京（ap-northeast-1） | $0.526 | 低（日本） |
| 米国東部（us-east-1） | $0.526 | 中 |
| 米国西部（us-west-2） | $0.526 | 中 |

**推奨**: 日本在住なら東京リージョン（レイテンシが低い）

## コスト削減シナリオ

### シナリオ1: 最小コスト（スポット + 自動停止）

```json
{
  "InstanceType": "g4dn.xlarge",
  "UseSpotInstance": "true",
  "SpotInstanceMaxPrice": "0.10",
  "AutoShutdownEnabled": "true"
}
```

**月額コスト**: 約 $20-30（1日2-3時間使用の場合）

### シナリオ2: バランス型（オンデマンド + 自動停止）

```json
{
  "InstanceType": "g4dn.xlarge",
  "UseSpotInstance": "false",
  "AutoShutdownEnabled": "true"
}
```

**月額コスト**: 約 $60-80（1日4-5時間使用の場合）

### シナリオ3: 高性能が必要な場合

```json
{
  "InstanceType": "g6e.xlarge",
  "UseSpotInstance": "true",
  "AutoShutdownEnabled": "true"
}
```

**月額コスト**: 約 $40-60（スポット使用、1日2-3時間）

## コスト監視

### AWS Cost Explorer

1. AWSコンソール → Cost Explorer
2. フィルタ: EC2-Instance
3. 日次/月次コストを確認

### 予算アラートの設定

```bash
# AWS CLIで予算アラートを設定（例: 月額$100）
aws budgets create-budget \
  --account-id YOUR_ACCOUNT_ID \
  --budget file://budget.json
```

## ベストプラクティスまとめ

### ✅ 推奨設定（個人学習用）

1. **インスタンスタイプ**: `g4dn.xlarge`
2. **スポットインスタンス**: `true`（コスト削減）
3. **自動停止**: `true`（必須）
4. **使用時間**: 1日2-4時間に集中
5. **リージョン**: 東京（ap-northeast-1）

### ❌ 避けるべき設定

1. **24時間稼働**: 不要な課金
2. **g6e/g5の常時使用**: 学習には過剰
3. **自動停止無効**: コストが高くなる
4. **大きなEBSボリューム**: 必要以上に大きくしない

## トラブルシューティング

### スポットインスタンスが中断された

1. インスタンス状態を確認: `./scripts/cloudformation_info.sh`
2. 再起動: `./scripts/cloudformation_deploy.sh`
3. データ復旧: S3バックアップから復元

### 自動停止が動作しない

1. CloudWatchアラームを確認
2. IAM権限を確認
3. Lambda関数のログを確認

### コストが予想より高い

1. Cost Explorerで詳細を確認
2. 使用時間を確認
3. 不要なリソースを削除
4. 自動停止が有効か確認

## 参考リンク

- [AWS EC2 料金](https://aws.amazon.com/jp/ec2/pricing/)
- [AWS Spot インスタンス](https://aws.amazon.com/jp/ec2/spot/)
- [AWS Cost Management](https://aws.amazon.com/jp/aws-cost-management/)

