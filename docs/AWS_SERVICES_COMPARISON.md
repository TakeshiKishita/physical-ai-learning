# AWS環境構築サービス比較

Isaac Sim環境を構築するためのAWSサービスの比較です。

## 主要なAWSサービス

### 1. AWS CloudFormation ⭐ 推奨

**概要**: Infrastructure as Code (IaC) サービス。YAML/JSONテンプレートでAWSリソースを定義。

**メリット**:

- ✅ テンプレート化で環境をコード管理
- ✅ 再現性が高い
- ✅ 依存関係の自動管理
- ✅ ロールバック機能
- ✅ AWS標準サービス

**デメリット**:

- ❌ 学習コスト（YAML/JSONの記述）
- ❌ テンプレートが複雑になりやすい

**用途**:

- インフラ全体の管理
- 複数環境の再現
- チームでの共有

**ファイル**: `cloudformation/isaac-sim-stack.yaml`

---

### 2. AWS CDK (Cloud Development Kit)

**概要**: TypeScript、Python、Java等のプログラミング言語でインフラを定義。

**メリット**:

- ✅ プログラミング言語で記述（型安全性）
- ✅ 再利用可能なコンポーネント
- ✅ テストが書きやすい
- ✅ IDEサポート

**デメリット**:

- ❌ 学習コストが高い
- ❌ 言語の知識が必要

**用途**:

- 複雑なインフラの管理
- 開発チームでの使用
- 大規模プロジェクト

**例**:

```typescript
const vpc = new ec2.Vpc(this, 'VPC');
const instance = new ec2.Instance(this, 'Instance', {
  instanceType: ec2.InstanceType.of(ec2.InstanceClass.G4DN, ec2.InstanceSize.XLARGE2),
  machineImage: ec2.MachineImage.lookup({
    name: 'isaac-sim-*'
  })
});
```

---

### 3. AWS Launch Templates

**概要**: EC2インスタンスの起動設定をテンプレート化。

**メリット**:

- ✅ シンプルで理解しやすい
- ✅ EC2起動設定のみに特化
- ✅ Auto Scalingと統合可能

**デメリット**:

- ❌ EC2のみ（他のリソースは管理できない）
- ❌ セキュリティグループ等は別途管理が必要

**用途**:

- EC2インスタンスの起動設定のみ
- Auto Scaling Groupとの組み合わせ

**例**:

```bash
aws ec2 create-launch-template \
  --launch-template-name isaac-sim-template \
  --launch-template-data '{
    "ImageId": "ami-0123456789abcdef0",
    "InstanceType": "g4dn.2xlarge",
    "KeyName": "my-keypair"
  }'
```

---

### 4. AWS Systems Manager (SSM)

**概要**: インスタンスの管理・操作を自動化。

**メリット**:

- ✅ 既存インスタンスの管理
- ✅ パッチ適用の自動化
- ✅ Session Manager（SSH不要）
- ✅ Parameter Storeとの統合

**デメリット**:

- ❌ インスタンス作成はできない
- ❌ SSM Agentのインストールが必要

**用途**:

- 既存インスタンスの管理
- パッチ管理
- セキュアな接続（SSH不要）

**例**:

```bash
# Session Managerで接続（SSH不要）
aws ssm start-session --target i-0123456789abcdef0
```

---

### 5. AWS Proton

**概要**: 環境・サービスのテンプレートを管理・公開。

**メリット**:

- ✅ テンプレートの標準化
- ✅ セルフサービスプロビジョニング
- ✅ ガバナンスの強化

**デメリット**:

- ❌ セットアップが複雑
- ❌ 小規模プロジェクトには過剰

**用途**:

- 大規模組織での標準化
- 複数チームでのテンプレート共有

---

## 推奨アプローチ

### 学習・個人プロジェクト

**推奨**: **AWS CloudFormation** または **シェルスクリプト**

理由:

- シンプルで理解しやすい
- テンプレートファイルをGitで管理できる
- AWS標準サービスで情報が多い

### 開発チーム・本番環境

**推奨**: **AWS CloudFormation** または **AWS CDK**

理由:

- コードレビューが可能
- バージョン管理が容易
- 再現性が高い

### 既存インスタンスの管理

**推奨**: **AWS Systems Manager**

理由:

- パッチ管理
- セキュアな接続
- 操作の自動化

## 実装例

### CloudFormation（推奨）

```bash
# デプロイ
./scripts/cloudformation_deploy.sh

# 情報確認
./scripts/cloudformation_info.sh

# 削除
./scripts/cloudformation_destroy.sh
```

### シェルスクリプト（シンプル）

```bash
# セットアップ
./scripts/setup_aws_env.sh

# 起動
./scripts/launch_instance.sh

# 接続
./scripts/connect_instance.sh
```

## 選択の指針

| 要件 | 推奨サービス |
|------|------------|
| シンプルに始めたい | シェルスクリプト |
| テンプレート化したい | CloudFormation |
| プログラミング言語で定義 | AWS CDK |
| EC2起動設定のみ | Launch Templates |
| 既存インスタンス管理 | Systems Manager |
| 大規模組織 | AWS Proton |

## 参考リンク

- [AWS CloudFormation](https://aws.amazon.com/cloudformation/)
- [AWS CDK](https://aws.amazon.com/cdk/)
- [AWS Systems Manager](https://aws.amazon.com/systems-manager/)
- [AWS Launch Templates](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-launch-templates.html)
