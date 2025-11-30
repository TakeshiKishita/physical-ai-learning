# AWS CloudFormation による環境構築ガイド

AWS CloudFormationを使用してIsaac Sim環境を構築する方法です。

**注意**: このガイドでは、東京リージョン（`ap-northeast-1`）を使用します。AWS CLIのデフォルト設定（`~/.aws/config`）でリージョンが設定されている場合は、`--region` オプションは省略可能です。他のリージョンを使用する場合は、AMI IDやリージョン指定を適宜変更してください。

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

## 前提条件: AWS CLIの設定

このガイドでは、AWS CLIを使用してCloudFormationスタックを管理します。以下の設定が必要です。

### AWS CLIのインストール

AWS CLIがインストールされていない場合は、以下のコマンドでインストールしてください。

**macOS (Homebrew)**
```bash
brew install awscli
```

**Linux**
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

**Windows**
```powershell
# Chocolateyを使用する場合
choco install awscli
```

**インストール確認**
```bash
aws --version
```

### AWS認証情報の設定

AWS CLIを使用するには、AWS認証情報（アクセスキーIDとシークレットアクセスキー）を設定する必要があります。

#### 方法A: `aws configure` コマンドを使用（推奨）

```bash
aws configure
```

以下の情報を入力します：

1. **AWS Access Key ID**: IAMユーザーのアクセスキーID
2. **AWS Secret Access Key**: IAMユーザーのシークレットアクセスキー
3. **Default region name**: `ap-northeast-1`（東京リージョン）
4. **Default output format**: `json`（推奨）または `table`、`text`

このコマンドにより、以下のファイルが作成・更新されます：
- `~/.aws/credentials`: 認証情報を保存
- `~/.aws/config`: デフォルトリージョンと出力形式を保存

#### 方法B: 環境変数を使用

```bash
export AWS_ACCESS_KEY_ID="your-access-key-id"
export AWS_SECRET_ACCESS_KEY="your-secret-access-key"
export AWS_DEFAULT_REGION="ap-northeast-1"
```

#### 方法C: 認証情報ファイルを手動で作成

```bash
# 認証情報ファイルを作成
mkdir -p ~/.aws
cat > ~/.aws/credentials <<EOF
[default]
aws_access_key_id = your-access-key-id
aws_secret_access_key = your-secret-access-key
EOF

# 設定ファイルを作成
cat > ~/.aws/config <<EOF
[default]
region = ap-northeast-1
output = json
EOF

# ファイルのパーミッションを設定（セキュリティのため）
chmod 600 ~/.aws/credentials
chmod 600 ~/.aws/config
```

### IAMユーザーとアクセスキーの作成

AWS認証情報を取得するには、IAMユーザーとアクセスキーを作成する必要があります。

1. [IAMコンソール](https://console.aws.amazon.com/iam/)にアクセス
2. 左メニューから「ユーザー」を選択
3. 「ユーザーを追加」をクリック
4. ユーザー名を入力（例: `cloudformation-user`）
5. 「プログラムによるアクセス」を選択
6. 「既存のポリシーを直接アタッチ」を選択し、以下のポリシーをアタッチ：
   - `CloudFormationFullAccess`
   - `AmazonEC2FullAccess`
   - `IAMFullAccess`（IAMロール作成のため）
7. ユーザーを作成
8. **アクセスキーID**と**シークレットアクセスキー**を保存（表示されるのは一度だけです）

**注意**: セキュリティのため、最小権限の原則に従い、必要最小限の権限のみを付与することを推奨します。

### 設定の確認

以下のコマンドで設定が正しく行われているか確認できます：

```bash
# 現在の設定を確認
aws configure list

# 認証情報の確認（IAMユーザー名が表示される）
aws sts get-caller-identity

# リージョンの確認
aws configure get region
```

### トラブルシューティング

**エラー: Unable to locate credentials**

認証情報が設定されていない場合に発生します。`aws configure` を実行して認証情報を設定してください。

**エラー: An error occurred (AccessDenied) when calling the ... operation**

IAMユーザーに必要な権限が付与されていない可能性があります。IAMポリシーを確認してください。

**リージョンが正しく設定されていない**

```bash
# リージョンを確認
aws configure get region

# リージョンを設定
aws configure set region ap-northeast-1
```

## セットアップ手順

### ステップ1: 必要なリソースの準備

#### 1-1. EC2キーペアの作成（新規作成が必要な場合）

EC2インスタンスにSSH接続するために、キーペアが必要です。既存のキーペアがある場合はスキップしてください。

**方法A: AWS CLIで作成（推奨）**

```bash
# キーペア名を指定（例: isaac-sim-keypair）
KEYPAIR_NAME="isaac-sim-keypair"

# キーペアを作成
aws ec2 create-key-pair \
  --key-name $KEYPAIR_NAME \
  --query 'KeyMaterial' \
  --output text > ~/.ssh/$KEYPAIR_NAME.pem

# パーミッションを設定（重要！）
chmod 400 ~/.ssh/$KEYPAIR_NAME.pem

# 作成されたキーペアを確認
aws ec2 describe-key-pairs \
  --key-names $KEYPAIR_NAME
```

**方法B: AWSマネジメントコンソールで作成**

1. [EC2コンソール](https://ap-northeast-1.console.aws.amazon.com/ec2/)にアクセス
2. 左メニューから「キーペア」を選択
3. 「キーペアを作成」をクリック
4. キーペア名を入力（例: `isaac-sim-keypair`）
5. 「プライベートキーファイル形式」で「pem」を選択
6. 「キーペアを作成」をクリック
7. ダウンロードされた`.pem`ファイルを`~/.ssh/`に保存し、パーミッションを`400`に設定

**既存のキーペアを確認**

```bash
# 利用可能なキーペア一覧を表示
aws ec2 describe-key-pairs \
  --query 'KeyPairs[*].KeyName' \
  --output table
```

#### 1-2. Isaac Sim AMI IDの取得

Isaac Sim用のAMI IDは、リージョンごとに異なります。以下の方法で取得できます。

**方法A: AWS Marketplaceから取得**

1. [AWS Marketplace - NVIDIA Omniverse Isaac Sim](https://aws.amazon.com/marketplace/pp/prodview-xxxxxxxxxxxxx)にアクセス
2. 使用するリージョン（例: ap-northeast-1）を選択
3. 「Continue to Subscribe」→「Continue to Configuration」をクリック
4. 「Fulfillment option」で「CloudFormation」を選択
5. 「Usage Instructions」タブでAMI IDを確認

**方法B: AWS CLIで検索**

```bash
# Isaac Sim関連のAMIを検索（リージョン: ap-northeast-1）
aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=*Isaac*Sim*" \
            "Name=state,Values=available" \
  --query 'Images[*].[ImageId,Name,CreationDate]' \
  --output table \
  --sort-by CreationDate
```

**方法C: 公式ドキュメントを確認**

- [NVIDIA Isaac Sim on AWS](https://docs.nvidia.com/isaac/isaac-sim/setup_python_aws.html)の公式ドキュメントで最新のAMI IDを確認

**注意**: AMI IDはリージョン固有です。`ap-northeast-1`で使用する場合は、そのリージョンのAMI IDを使用してください。

#### 1-3. 自分のIPアドレスの取得

セキュリティのため、SSHとVNC接続を自分のIPアドレスのみに制限することを推奨します。

```bash
# 現在のパブリックIPアドレスを取得
MY_IP=$(curl -s https://checkip.amazonaws.com)
echo "Your IP address: $MY_IP"
echo "CIDR format: $MY_IP/32"
```

**手動で確認する場合**

- [What Is My IP Address](https://www.whatismyip.com/)などのサービスで確認
- 取得したIPアドレスに`/32`を付けてCIDR形式にする（例: `203.0.113.1/32`）

**注意**: 自宅やオフィスから接続する場合、IPアドレスが変わる可能性があります。その場合は`0.0.0.0/0`（すべてのIPを許可）を使用できますが、セキュリティリスクが高くなります。

#### 1-4. インスタンスタイプの選択

テンプレートで利用可能なインスタンスタイプ：

- `g4dn.xlarge`: コスト効率が良い、旧世代（T4 GPU）- **学習用途に推奨**
- `g4dn.2xlarge`: g4dn.xlargeの2倍の性能
- `g5.xlarge`: 新世代（A10G GPU）
- `g6e.xlarge`: 最新世代（L40S GPU、2倍の性能、高コスト）
- `g6e.2xlarge`: g6e.xlargeの2倍の性能

**コスト比較（参考）**

```bash
# インスタンスタイプごとの料金を確認（ap-northeast-1）
aws pricing get-products \
  --service-code AmazonEC2 \
  --filters "Type=TERM_MATCH,Field=instanceType,Value=g4dn.xlarge" \
            "Type=TERM_MATCH,Field=location,Value=Asia Pacific (Tokyo)" \
  --query 'PriceList[0]' \
  --output json | jq -r '.terms.OnDemand | to_entries[0].value.priceDimensions | to_entries[0].value.pricePerUnit.USD'
```

### ステップ2: パラメータファイルの編集

`cloudformation/parameters.json` を編集して、実際の値を設定します。

**パラメータの説明**

| パラメータ | 説明 | 取得方法 | デフォルト値 |
|-----------|------|---------|------------|
| `InstanceType` | EC2インスタンスタイプ | 上記1-4を参照 | `g4dn.xlarge` |
| `AMIId` | Isaac Sim用AMI ID | 上記1-2を参照 | `ami-XXXXX`（要変更） |
| `KeyPairName` | EC2キーペア名 | 上記1-1を参照 | 要設定 |
| `AllowedSSHCIDR` | SSH接続許可CIDR | 上記1-3を参照 | `0.0.0.0/0`（全許可） |
| `AllowedVNCCIDR` | VNC接続許可CIDR | 上記1-3を参照 | `0.0.0.0/0`（全許可） |
| `VolumeSize` | EBSボリュームサイズ（GB） | 20-1000の範囲で指定 | `100` |
| `UseSpotInstance` | スポットインスタンス使用 | `true`（コスト削減）または`false` | `false` |
| `SpotInstanceMaxPrice` | スポットインスタンス最大価格（USD/時） | 現在のオンデマンド価格を確認 | `0.10` |
| `AutoShutdownEnabled` | 自動シャットダウン有効化 | `true`（推奨）または`false` | `true` |

**編集例**

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
    "ParameterValue": "203.0.113.1/32"
  },
  {
    "ParameterKey": "AllowedVNCCIDR",
    "ParameterValue": "203.0.113.1/32"
  },
  {
    "ParameterKey": "VolumeSize",
    "ParameterValue": "100"
  },
  {
    "ParameterKey": "UseSpotInstance",
    "ParameterValue": "false"
  },
  {
    "ParameterKey": "SpotInstanceMaxPrice",
    "ParameterValue": "0.10"
  },
  {
    "ParameterKey": "AutoShutdownEnabled",
    "ParameterValue": "true"
  }
]
```

**パラメータ値の自動取得スクリプト（参考）**

```bash
#!/bin/bash
# パラメータ値を自動取得してparameters.jsonを生成
# リージョン: ap-northeast-1 (東京) - AWS CLIのデフォルト設定で指定

MY_IP=$(curl -s https://checkip.amazonaws.com)
KEYPAIR_NAME="isaac-sim-keypair"
AMI_ID="ami-XXXXX"  # 実際のAMI IDに置き換え

cat > cloudformation/parameters.json <<EOF
[
  {
    "ParameterKey": "InstanceType",
    "ParameterValue": "g4dn.xlarge"
  },
  {
    "ParameterKey": "AMIId",
    "ParameterValue": "$AMI_ID"
  },
  {
    "ParameterKey": "KeyPairName",
    "ParameterValue": "$KEYPAIR_NAME"
  },
  {
    "ParameterKey": "AllowedSSHCIDR",
    "ParameterValue": "$MY_IP/32"
  },
  {
    "ParameterKey": "AllowedVNCCIDR",
    "ParameterValue": "$MY_IP/32"
  },
  {
    "ParameterKey": "VolumeSize",
    "ParameterValue": "100"
  },
  {
    "ParameterKey": "UseSpotInstance",
    "ParameterValue": "false"
  },
  {
    "ParameterKey": "SpotInstanceMaxPrice",
    "ParameterValue": "0.10"
  },
  {
    "ParameterKey": "AutoShutdownEnabled",
    "ParameterValue": "true"
  }
]
EOF

echo "parameters.json を生成しました"
```

### ステップ3: スタックのデプロイ

```bash
./scripts/cloudformation_deploy.sh
```

または、手動でデプロイ：

```bash
aws cloudformation create-stack \
  --stack-name isaac-sim-stack \
  --template-body file://cloudformation/isaac-sim-stack.yaml \
  --parameters file://cloudformation/parameters.json \
  --capabilities CAPABILITY_NAMED_IAM
```

### ステップ4: スタック情報の確認

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

### ステップ5: インスタンスへの接続

スタックの出力からPublicIPを取得し、SSH接続：

```bash
# 出力からSSHコマンドを取得
aws cloudformation describe-stacks \
  --stack-name isaac-sim-stack \
  --query 'Stacks[0].Outputs[?OutputKey==`SSHCommand`].OutputValue' \
  --output text
```

### ステップ6: スタックの削除

```bash
./scripts/cloudformation_destroy.sh
```

または、手動で削除：

```bash
aws cloudformation delete-stack \
  --stack-name isaac-sim-stack
```

## CloudFormationテンプレートの構成

### リソース

- **IsaacSimSecurityGroup**: セキュリティグループ（SSH、VNCポート開放）
- **IsaacSimInstanceRole**: IAMロール（Systems Manager用）
- **IsaacSimInstanceProfile**: IAMインスタンスプロファイル
- **IsaacSimInstance**: EC2インスタンス

### パラメータ

- `InstanceType`: インスタンスタイプ（g4dn.xlarge等）
- `AMIId`: Isaac Sim用AMI ID（リージョン固有）
- `KeyPairName`: キーペア名（既存のキーペアが必要）
- `AllowedSSHCIDR`: SSH接続許可CIDR（推奨: 自分のIP/32）
- `AllowedVNCCIDR`: VNC接続許可CIDR（推奨: 自分のIP/32）
- `VolumeSize`: EBSボリュームサイズ（GB、20-1000の範囲）
- `UseSpotInstance`: スポットインスタンス使用（`true`/`false`）
- `SpotInstanceMaxPrice`: スポットインスタンス最大価格（USD/時）
- `AutoShutdownEnabled`: 自動シャットダウン有効化（`true`/`false`）

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

