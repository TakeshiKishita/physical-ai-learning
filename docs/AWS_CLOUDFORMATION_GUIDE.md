# AWS CloudFormation による環境構築ガイド

AWS CloudFormationを使用してIsaac Sim環境を構築する方法です。

## AWS CloudFormationとは

**AWS CloudFormation**は、Infrastructure as Code (IaC) のサービスで、JSONまたはYAML形式のテンプレートを使用してAWSリソースを定義・管理できます。

### メリット

- ✅ **テンプレート化**: 環境をコードとして管理
- ✅ **再現性**: 同じ環境を何度でも作成可能
- ✅ **バージョン管理**: Gitで管理できる
- ✅ **自動化**: スタックの作成・更新・削除を自動化
- ✅ **依存関係の管理**: リソース間の依存関係を自動処理
- ✅ **ロールバック**: 問題発生時に自動ロールバック

### その他のAWSサービスとの比較

| サービス | 用途 | 特徴 |
|---------|------|------|
| **CloudFormation** | インフラ全体の管理 | YAML/JSONテンプレート、AWS標準 |
| **AWS CDK** | プログラミング言語で定義 | TypeScript/Python等、より柔軟 |
| **AWS Launch Templates** | EC2起動設定のみ | シンプル、EC2専用 |
| **AWS Systems Manager** | インスタンス管理 | 既存インスタンスの管理 |

## セットアップ手順

### ステップ1: パラメータファイルの編集

`cloudformation/parameters.json` を編集して、実際の値を設定：

```json
[
  {
    "ParameterKey": "InstanceType",
    "ParameterValue": "g4dn.xlarge"
  },
  {
    "ParameterKey": "AMIId",
    "ParameterValue": "ami-0123456789abcdef0"
  },
  {
    "ParameterKey": "KeyPairName",
    "ParameterValue": "isaac-sim-keypair"
  },
  {
    "ParameterKey": "AllowedSSHCIDR",
    "ParameterValue": "YOUR_IP/32"
  },
  {
    "ParameterKey": "AllowedVNCCIDR",
    "ParameterValue": "YOUR_IP/32"
  },
  {
    "ParameterKey": "VolumeSize",
    "ParameterValue": "100"
  }
]
```

### ステップ2: スタックのデプロイ

```bash
./scripts/cloudformation_deploy.sh
```

または、手動でデプロイ：

```bash
aws cloudformation create-stack \
  --stack-name isaac-sim-stack \
  --template-body file://cloudformation/isaac-sim-stack.yaml \
  --parameters file://cloudformation/parameters.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region ap-northeast-1
```

### ステップ3: スタック情報の確認

```bash
./scripts/cloudformation_info.sh
```

または、AWS CLIで確認：

```bash
aws cloudformation describe-stacks \
  --stack-name isaac-sim-stack \
  --query 'Stacks[0].Outputs' \
  --output table
```

### ステップ4: インスタンスへの接続

スタックの出力からPublicIPを取得し、SSH接続：

```bash
# 出力からSSHコマンドを取得
aws cloudformation describe-stacks \
  --stack-name isaac-sim-stack \
  --query 'Stacks[0].Outputs[?OutputKey==`SSHCommand`].OutputValue' \
  --output text
```

### ステップ5: スタックの削除

```bash
./scripts/cloudformation_destroy.sh
```

または、手動で削除：

```bash
aws cloudformation delete-stack \
  --stack-name isaac-sim-stack \
  --region ap-northeast-1
```

## CloudFormationテンプレートの構成

### リソース

- **IsaacSimSecurityGroup**: セキュリティグループ（SSH、VNCポート開放）
- **IsaacSimInstanceRole**: IAMロール（Systems Manager用）
- **IsaacSimInstanceProfile**: IAMインスタンスプロファイル
- **IsaacSimInstance**: EC2インスタンス

### パラメータ

- `InstanceType`: インスタンスタイプ（g4dn.xlarge等）
- `AMIId`: Isaac Sim用AMI ID
- `KeyPairName`: キーペア名
- `AllowedSSHCIDR`: SSH接続許可CIDR
- `AllowedVNCCIDR`: VNC接続許可CIDR
- `VolumeSize`: EBSボリュームサイズ（GB）

### 出力

- `InstanceId`: EC2インスタンスID
- `PublicIP`: パブリックIPアドレス
- `SecurityGroupId`: セキュリティグループID
- `SSHCommand`: SSH接続コマンド

## 高度な使い方

### パラメータの動的指定

```bash
aws cloudformation create-stack \
  --stack-name isaac-sim-stack \
  --template-body file://cloudformation/isaac-sim-stack.yaml \
  --parameters \
    ParameterKey=AMIId,ParameterValue=ami-0123456789abcdef0 \
    ParameterKey=KeyPairName,ParameterValue=my-keypair \
  --capabilities CAPABILITY_NAMED_IAM
```

### 既存VPCの使用

テンプレートを編集して、VPC IDパラメータを追加：

```yaml
Parameters:
  VPCId:
    Type: AWS::EC2::VPC::Id
    Description: VPC ID to use
```

### スタックの更新

```bash
aws cloudformation update-stack \
  --stack-name isaac-sim-stack \
  --template-body file://cloudformation/isaac-sim-stack.yaml \
  --parameters file://cloudformation/parameters.json \
  --capabilities CAPABILITY_NAMED_IAM
```

## トラブルシューティング

### エラー: スタックが作成できない

**原因1: IAM権限不足**
- CloudFormation、EC2、IAMの権限が必要
- `CAPABILITY_NAMED_IAM` を指定

**原因2: リソース制限**
- インスタンスタイプのクォータ制限
- セキュリティグループ数の制限

**原因3: AMI IDが無効**
- リージョンとAMI IDが一致しているか確認

### エラー: スタックがロールバックする

```bash
# イベントを確認
aws cloudformation describe-stack-events \
  --stack-name isaac-sim-stack \
  --max-items 10 \
  --query 'StackEvents[*].[Timestamp,ResourceStatus,ResourceStatusReason]' \
  --output table
```

### スタックの状態確認

```bash
aws cloudformation describe-stacks \
  --stack-name isaac-sim-stack \
  --query 'Stacks[0].StackStatus' \
  --output text
```

## その他のAWSサービス

### AWS Launch Templates

EC2起動設定のみをテンプレート化する場合：

```bash
aws ec2 create-launch-template \
  --launch-template-name isaac-sim-template \
  --launch-template-data file://launch-template-data.json
```

### AWS Systems Manager

既存インスタンスの管理：

```bash
# インスタンスにSSM Agentがインストールされている場合
aws ssm start-session --target i-0123456789abcdef0
```

## 参考リンク

- [AWS CloudFormation Documentation](https://docs.aws.amazon.com/cloudformation/)
- [CloudFormation Template Reference](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-reference.html)
- [AWS CDK Documentation](https://docs.aws.amazon.com/cdk/)

