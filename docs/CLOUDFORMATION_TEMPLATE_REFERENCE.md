# CloudFormation テンプレート完全リファレンス

`cloudformation/isaac-sim-stack.yaml` の完全解説（YAML記載順）

---

## 📊 サマリ

### このテンプレートの目的

NVIDIA Isaac Sim を実行するための **GPU 搭載 EC2 インスタンス環境** を自動構築します。

### 作成されるリソース

| # | リソース名 | タイプ | 用途 |
|---|-----------|--------|------|
| 1 | IsaacSimSecurityGroup | セキュリティグループ | SSH/VNC アクセス制御 |
| 2 | IsaacSimInstanceRole | IAM ロール | Systems Manager / CloudWatch 権限 |
| 3 | IsaacSimInstanceProfile | IAM インスタンスプロファイル | ロールをEC2にアタッチ |
| 4 | IsaacSimInstance | EC2 インスタンス | Isaac Sim 実行環境（GPU付き） |
| 5 | AutoShutdownAlarm | CloudWatch アラーム | 自動シャットダウン（条件付き） |

**合計**: 4リソース（必須）+ 1リソース（オプション）

### 主要機能

#### 🎯 コア機能

- ✅ **GPU インスタンス** - g4dn/g5/g6e シリーズから選択可能
- ✅ **SSH/VNC アクセス** - リモート接続対応
- ✅ **Systems Manager** - キーペア不要のブラウザ接続
- ✅ **暗号化 EBS** - データ保護

#### 💰 コスト最適化

- 🔧 **自動シャットダウン** - CPU低使用率2時間で自動停止
- 🔧 **スポットインスタンス対応** - 最大90%割引（中断リスクあり）
- 🔧 **gp3 ストレージ** - gp2より20%安価

#### 🔒 セキュリティ

- 🔐 **IMDSv2 強制** - SSRF攻撃対策
- 🔐 **EBS 暗号化** - データ保護
- 🔐 **アクセス制限** - SSH/VNC を CIDR で制限可能
- 🔐 **最小権限** - IAM ロールは必要最小限

### 設定可能なパラメータ（9個）

| カテゴリ | パラメータ | デフォルト値 |
|---------|-----------|-------------|
| **インスタンス** | InstanceType | `g5.2xlarge` |
| | AMIId | `ami-XXXXX`（要変更） |
| | KeyPairName | （必須入力） |
| | VolumeSize | `150` GB |
| **セキュリティ** | AllowedSSHCIDR | `0.0.0.0/0` |
| | AllowedVNCCIDR | `0.0.0.0/0` |
| **コスト最適化** | UseSpotInstance | `false` |
| | SpotInstanceMaxPrice | `0.10` |
| | AutoShutdownEnabled | `true` |
| | AutoShutdownEnabled | `true` |

### 🚀 ポストデプロイ設定（Deep Learning AMI 利用時）

現在推奨されている **Deep Learning AMI** には Isaac Sim がプリインストールされていないため、スタック作成後に以下の手順が必要です。

1. **インスタンスへの接続**: Output の `SSHCommand` を使用して接続。
2. **コンテナの実行 (推奨)**:
   Docker コマンドを使用して Isaac Sim コンテナを実行します。
   > 詳細は `docs/BEST_PRACTICES_2025.md` の「1.1 Isaac Sim インストール手順」を参照してください。

### 🚀 ポストデプロイ設定（Deep Learning AMI 利用時）

現在推奨されている **Deep Learning AMI** には Isaac Sim がプリインストールされていないため、スタック作成後に以下の手順が必要です。

1. **インスタンスへの接続**: Output の `SSHCommand` を使用して接続。
2. **コンテナの実行 (推奨)**:
   Docker コマンドを使用して Isaac Sim コンテナを実行します。
   > 詳細は `docs/BEST_PRACTICES_2025.md` の「1.1 Isaac Sim インストール手順」を参照してください。
>
### 推奨デプロイ前変更

> [!WARNING]
> セキュリティのため、以下を変更してからデプロイしてください：

```json
{
  "AllowedSSHCIDR": "0.0.0.0/0" → "<自分のIP>/32",
  "AllowedVNCCIDR": "0.0.0.0/0" → "<自分のIP>/32"
}
```

### 月額コスト概算（東京リージョン）

| 構成 | EC2料金/月 | EBS料金/月 | 合計/月 |
|------|-----------|-----------|---------|
| **g5.2xlarge（常時稼働）** | ~¥190,000 | ~¥2,000 | ~¥192,000 |
| **g5.2xlarge（8h/日）** | ~¥64,000 | ~¥2,000 | ~¥66,000 |
| **スポット + 自動停止** | ~¥20,000-¥60,000 | ~¥2,000 | **~¥22,000-¥62,000** |

> [!TIP]
> スポットインスタンス + 自動シャットダウンで **最大95%削減** 可能

---

## 📋 テンプレート基本情報

### AWSTemplateFormatVersion

- **値**: `2010-09-09`
- CloudFormation テンプレート形式のバージョン（現在これのみ）

### Description

```
Isaac Sim EC2 Instance Stack for Physical AI Learning - Latest best practices
```

スタックの説明文。コンソールに表示される。

---

## 🎨 Metadata

### AWS::CloudFormation::Interface

AWS コンソールでパラメータ入力画面のUI配置を定義

#### ParameterGroups（グループ化）

1. **Instance Configuration**
   - `InstanceType`
   - `AMIId`
   - `KeyPairName`
   - `VolumeSize`

2. **Security Settings**
   - `AllowedSSHCIDR`
   - `AllowedVNCCIDR`

#### ParameterLabels（表示名）

コンソール上での各パラメータの表示ラベルを定義（説明は後述のParametersセクション参照）

---

## ⚙️ Parameters

### 1. InstanceType

| 項目 | 値 |
|------|-----|
| **Type** | `String` |
| **Default** | `g5.2xlarge` |
| **AllowedValues** | `g5.2xlarge`, `g5.4xlarge`, `g5.8xlarge`, `g6e.xlarge`, `g6e.2xlarge` |

**説明:**

```
EC2 instance type for Isaac Sim.
- **g4dn.2xlarge**: コスト効率の良い選択肢 (T4 GPU, 32GB RAM)。Deep Learning AMIでサポートされます。
- **g5.2xlarge**: より高性能 (A10G GPU)。

※重要: GPUインスタンスを使用するには、事前にAWS Service Quotasで「Running On-Demand G and VT instances」または「All G and VT Spot Instance Requests」の緩和申請が必要です。
※Deep Learning AMIを使用する場合、g4dnシリーズは完全にサポートされます。
```

---

### 2. AMIId

| 項目 | 値 |
|------|-----|
| **Type** | `String` |
| **Default** | `ami-XXXXX` |
| **Description** | `AMI ID for Isaac Sim (region-specific)` |

> [!IMPORTANT]
> リージョンごとに異なるAMI IDを指定する必要があります。

---

### 3. KeyPairName

| 項目 | 値 |
|------|-----|
| **Type** | `AWS::EC2::KeyPair::KeyName` |
| **Description** | `Name of an existing EC2 KeyPair to enable SSH access` |

CloudFormation が自動的に既存キーペアの存在を検証します。

---

### 4. AllowedSSHCIDR

| 項目 | 値 |
|------|-----|
| **Type** | `String` |
| **Default** | `0.0.0.0/0` |
| **AllowedPattern** | `^([0-9]{1,3}\.){3}[0-9]{1,3}(\/([0-9]|[1-2][0-9]|3[0-2]))?$` |
| **ConstraintDescription** | `Must be a valid CIDR block (e.g., 203.0.113.0/24 or 0.0.0.0/0)` |
| **Description** | `CIDR block allowed to SSH access (recommend your IP/32 for security)` |

正規表現でCIDR形式を検証。セキュリティのため`<自分のIP>/32`を推奨。

---

### 5. AllowedVNCCIDR

| 項目 | 値 |
|------|-----|
| **Type** | `String` |
| **Default** | `0.0.0.0/0` |
| **AllowedPattern** | `^([0-9]{1,3}\.){3}[0-9]{1,3}(\/([0-9]|[1-2][0-9]|3[0-2]))?$` |
| **ConstraintDescription** | `Must be a valid CIDR block (e.g., 203.0.113.0/24 or 0.0.0.0/0)` |
| **Description** | `CIDR block allowed to VNC/DCV access (recommend your IP/32 for security)` |

VNC/DCV（ポート5900-5910）へのアクセス許可範囲。

---

### 6. VolumeSize

| 項目 | 値 |
|------|-----|
| **Type** | `Number` |
| **Default** | `150` |
| **MinValue** | `128` |
| **MaxValue** | `1000` |

**説明:**

```
Size of the root EBS volume in GB.
Minimum 128GB required for Isaac Sim AMI.
Recommended: 150GB for comfortable usage.
```

---

### 7. UseSpotInstance

| 項目 | 値 |
|------|-----|
| **Type** | `String` |
| **Default** | `'false'` |
| **AllowedValues** | `'true'`, `'false'` |

**説明:**

```
Use Spot Instance for cost savings (up to 90% discount).
Warning: Spot instances can be interrupted. Recommended for learning/testing.
```

---

### 8. SpotInstanceMaxPrice

| 項目 | 値 |
|------|-----|
| **Type** | `String` |
| **Default** | `'0.10'` |

**説明:**

```
Maximum price per hour for Spot Instance (USD).
Leave empty to use current On-Demand price.
Only used when UseSpotInstance is 'true'
```

空文字列の場合、オンデマンド価格が自動使用されます。

---

### 9. AutoShutdownEnabled

| 項目 | 値 |
|------|-----|
| **Type** | `String` |
| **Default** | `'true'` |
| **AllowedValues** | `'true'`, `'false'` |

**説明:**

```
Enable automatic shutdown after idle time to save costs.
Uses CloudWatch alarm to stop instance after 2 hours of low CPU usage.
```

---

## 🔀 Conditions

### 1. UseSpotInstance

```yaml
!Equals [!Ref UseSpotInstance, 'true']
```

スポットインスタンス機能の有効化判定。

### 2. HasSpotPrice

```yaml
!Not [!Equals [!Ref SpotInstanceMaxPrice, '']]
```

スポット価格上限の設定有無を判定。

### 3. AutoShutdownEnabled

```yaml
!Equals [!Ref AutoShutdownEnabled, 'true']
```

自動シャットダウンアラームの作成判定。

---

## 🏗️ Resources

### 1. IsaacSimSecurityGroup

**Type:** `AWS::EC2::SecurityGroup`

#### Properties

| プロパティ | 値 |
|-----------|-----|
| `GroupDescription` | `Security group for Isaac Sim EC2 instance` |
| `GroupName` | `${AWS::StackName}-sg` |

#### SecurityGroupIngress（インバウンドルール）

**ルール1: SSH**

```yaml
- IpProtocol: tcp
  FromPort: 22
  ToPort: 22
  CidrIp: !Ref AllowedSSHCIDR
  Description: SSH access for instance management
```

**ルール2: VNC**

```yaml
- IpProtocol: tcp
  FromPort: 5900
  ToPort: 5910
  CidrIp: !Ref AllowedVNCCIDR
  Description: VNC/DCV access for remote desktop
```

#### Tags (Security Group)

- `Name: ${AWS::StackName}-sg`
- `Project: physical-ai-learning`
- `ManagedBy: CloudFormation`

> [!NOTE]
> SecurityGroupEgress（アウトバウンド）は未定義。デフォルトVPCでは全アウトバウンドが自動許可されます。

---

### 2. IsaacSimInstanceRole

**Type:** `AWS::IAM::Role`

#### Properties

| プロパティ | 値 |
|-----------|-----|
| `RoleName` | `${AWS::StackName}-instance-role` |

#### AssumeRolePolicyDocument

```yaml
Version: '2012-10-17'
Statement:
  - Effect: Allow
    Principal:
      Service: ec2.amazonaws.com
    Action: sts:AssumeRole
```

EC2サービスがこのロールを引き受け可能。

#### ManagedPolicyArns

```yaml
- arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
```

Systems Manager Session Manager でのアクセスを許可。

#### Policies

**PolicyName:** `CloudWatchAgentServerPolicy`

**許可されるアクション:**

- `cloudwatch:PutMetricData` - メトリクス送信
- `cloudwatch:GetMetricStatistics` - メトリクス取得
- `cloudwatch:ListMetrics` - メトリクス一覧
- `logs:CreateLogGroup` - ロググループ作成
- `logs:CreateLogStream` - ログストリーム作成
- `logs:PutLogEvents` - ログ送信
- `logs:DescribeLogStreams` - ログストリーム情報取得

**Resource:** `*`（すべてのリソース）

#### Tags (IAM Role)

- `Project: physical-ai-learning`
- `ManagedBy: CloudFormation`

---

### 3. IsaacSimInstanceProfile

**Type:** `AWS::IAM::InstanceProfile`

#### Properties

| プロパティ | 値 |
|-----------|-----|
| `InstanceProfileName` | `${AWS::StackName}-instance-profile` |
| `Roles` | `[!Ref IsaacSimInstanceRole]` |

IAMロールをEC2インスタンスにアタッチするためのラッパーリソース。

---

### 4. IsaacSimInstance

**Type:** `AWS::EC2::Instance`

#### Properties

| プロパティ | 値 |
|-----------|-----|
| `ImageId` | `!Ref AMIId` |
| `InstanceType` | `!Ref InstanceType` |
| `KeyName` | `!Ref KeyPairName` |
| `SecurityGroupIds` | `[!Ref IsaacSimSecurityGroup]` |
| `IamInstanceProfile` | `!Ref IsaacSimInstanceProfile` |

#### InstanceMarketOptions（条件付き）

```yaml
!If
  - UseSpotInstance
  - MarketType: spot
  - !Ref AWS::NoValue
```

`UseSpotInstance='true'` の場合のみスポットインスタンスとして起動。

#### BlockDeviceMappings

```yaml
- DeviceName: /dev/sda1
  Ebs:
    VolumeSize: !Ref VolumeSize
    VolumeType: gp3
    Iops: 3000
    Encrypted: true
    DeleteOnTermination: true
```

| EBS設定 | 値 | 説明 |
|---------|-----|------|
| `VolumeSize` | パラメータ値 | GB単位 |
| `VolumeType` | `gp3` | 汎用SSD（最新世代） |
| `Iops` | `3000` | 1秒あたりのI/O操作数 |
| `Encrypted` | `true` | EBS暗号化有効 |
| `DeleteOnTermination` | `true` | インスタンス削除時にボリュームも削除 |

#### Monitoring

```yaml
Monitoring: true
```

詳細モニタリング有効（1分間隔のメトリクス収集）。

#### MetadataOptions

```yaml
HttpEndpoint: enabled
HttpTokens: required
HttpPutResponseHopLimit: 1
```

| 設定 | 値 | 説明 |
|------|-----|------|
| `HttpEndpoint` | `enabled` | メタデータサービス有効 |
| `HttpTokens` | `required` | **IMDSv2強制**（セキュリティ強化） |
| `HttpPutResponseHopLimit` | `1` | コンテナからのアクセス制限 |

> [!IMPORTANT]
> IMDSv2 必須化により、SSRF攻撃のリスクを軽減します。

#### Tags (Instance)

| キー | 値 |
|------|-----|
| `Name` | `${AWS::StackName}-instance` |
| `Project` | `physical-ai-learning` |
| `Week` | `week1` |
| `ManagedBy` | `CloudFormation` |
| `CreatedBy` | `${AWS::StackName}` |
| `AutoShutdown` | `!Ref AutoShutdownEnabled` |
| `SpotInstance` | `!Ref UseSpotInstance` |

---

### 5. AutoShutdownAlarm

**Type:** `AWS::CloudWatch::Alarm`  
**Condition:** `AutoShutdownEnabled`（`AutoShutdownEnabled='true'` の場合のみ作成）

#### Properties

| プロパティ | 値 |
|-----------|-----|
| `AlarmName` | `${AWS::StackName}-auto-shutdown` |
| `AlarmDescription` | `Automatically stop instance after 2 hours of low CPU usage` |

#### メトリクス監視設定

| 項目 | 値 | 説明 |
|------|-----|------|
| `MetricName` | `CPUUtilization` | CPU使用率 |
| `Namespace` | `AWS/EC2` | EC2メトリクス |
| `Statistic` | `Average` | 平均値 |
| `Period` | `300` | 5分（秒単位） |
| `EvaluationPeriods` | `24` | 24回評価 = 2時間 |
| `Threshold` | `5` | 閾値5% |
| `ComparisonOperator` | `LessThanThreshold` | 閾値未満 |

#### Dimensions

```yaml
- Name: InstanceId
  Value: !Ref IsaacSimInstance
```

監視対象インスタンスを指定。

#### AlarmActions

```yaml
- !Sub 'arn:aws:automate:${AWS::Region}:ec2:stop'
```

アラーム発動時にEC2インスタンスを**停止**（終了ではない）。

#### TreatMissingData

```yaml
TreatMissingData: notBreaching
```

メトリクスデータが欠損している場合、アラーム状態とみなさない。

> [!NOTE]
> **動作:** CPU使用率5%未満が2時間（24回×5分）連続で続くと、インスタンスが自動停止します。停止中はEBS料金のみ発生し、EC2料金は0円です。

---

## 📤 Outputs

### 1. InstanceId

| 項目 | 値 |
|------|-----|
| **Description** | `EC2 Instance ID` |
| **Value** | `!Ref IsaacSimInstance` |
| **Export Name** | `${AWS::StackName}-InstanceId` |

---

### 2. PublicIP

| 項目 | 値 |
|------|-----|
| **Description** | `Public IP address of the instance` |
| **Value** | `!GetAtt IsaacSimInstance.PublicIp` |
| **Export Name** | `${AWS::StackName}-PublicIP` |

---

### 3. PrivateIP

| 項目 | 値 |
|------|-----|
| **Description** | `Private IP address of the instance` |
| **Value** | `!GetAtt IsaacSimInstance.PrivateIp` |
| **Export Name** | `${AWS::StackName}-PrivateIP` |

---

### 4. SecurityGroupId

| 項目 | 値 |
|------|-----|
| **Description** | `Security Group ID` |
| **Value** | `!Ref IsaacSimSecurityGroup` |
| **Export Name** | `${AWS::StackName}-SecurityGroupId` |

---

### 5. SSHCommand

| 項目 | 値 |
|------|-----|
| **Description** | `SSH command to connect to the instance` |
| **Value** | `ssh -i ~/.ssh/${KeyPairName}.pem ubuntu@${IsaacSimInstance.PublicIp}` |

SSH接続コマンドを自動生成。

---

### 6. SSMCommand

| 項目 | 値 |
|------|-----|
| **Description** | `AWS Systems Manager Session Manager command (no SSH key needed)` |
| **Value** | `aws ssm start-session --target ${IsaacSimInstance}` |

SSHキー不要でブラウザから接続できるコマンド。

---

### 7. CloudFormationConsole

| 項目 | 値 |
|------|-----|
| **Description** | `Link to view this stack in the AWS CloudFormation console` |
| **Value** | `https://${AWS::Region}.console.aws.amazon.com/cloudformation/home?region=${AWS::Region}#/stacks/stackinfo?stackId=${AWS::StackId}` |

AWSコンソールでスタックを直接開くリンク。

---

### 8. InstanceType

| 項目 | 値 |
|------|-----|
| **Description** | `Instance type used` |
| **Value** | `!Ref InstanceType` |

使用したインスタンスタイプを出力。

---

### 9. SpotInstanceStatus（条件付き）

| 項目 | 値 |
|------|-----|
| **Condition** | `UseSpotInstance` |
| **Description** | `Spot Instance is enabled for cost savings` |
| **Value** | `'Enabled'` |

`UseSpotInstance='true'` の場合のみ表示。

---

### 10. AutoShutdownStatus（条件付き）

| 項目 | 値 |
|------|-----|
| **Condition** | `AutoShutdownEnabled` |
| **Description** | `Auto shutdown is enabled to save costs` |
| **Value** | `'Enabled - Instance will stop after 2 hours of low CPU usage'` |

`AutoShutdownEnabled='true'` の場合のみ表示。

---

## 📚 補足情報

### エクスポート機能について

出力1-4は `Export.Name` を持ち、他のCloudFormationスタックから `!ImportValue` で参照可能です。

**例:**

```yaml
# 別スタックから参照
SecurityGroups:
  - !ImportValue isaac-sim-stack-SecurityGroupId
```

### 条件付きリソース・出力

以下は `Condition` により動的に作成・表示されます：

| リソース/出力 | 条件 |
|-------------|------|
| `AutoShutdownAlarm` | `AutoShutdownEnabled='true'` |
| `SpotInstanceStatus` | `UseSpotInstance='true'` |
| `AutoShutdownStatus` | `AutoShutdownEnabled='true'` |

---

## 🔒 セキュリティ考察

### 実装されているセキュリティ機能

1. **EBS暗号化** - データ保護
2. **IMDSv2強制** - SSRF攻撃対策
3. **CIDR制限** - ネットワークアクセス制御
4. **最小権限の原則** - IAMロールは必要最小限

### 推奨設定変更

デプロイ前に以下を変更してください：

```json
{
  "AllowedSSHCIDR": "0.0.0.0/0" → "<自分のIP>/32",
  "AllowedVNCCIDR": "0.0.0.0/0" → "<自分のIP>/32"
}
```

---

## 💰 コスト最適化の仕組み

### 1. 自動シャットダウン（AutoShutdownAlarm）

- CPU 5%未満 × 2時間 → 自動停止
- 停止中: EC2料金 ¥0、EBS料金のみ

### 2. スポットインスタンス（InstanceMarketOptions）

- 最大90%割引
- 中断リスクあり（2分前通知）

### 3. gp3 EBS

- gp2より20%安価
- 3000 IOPSを追加料金なしで提供
