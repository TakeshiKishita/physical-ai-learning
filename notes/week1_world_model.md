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

---

## タスク一覧

### Task 1-1：Isaac Sim 用 EC2 インスタンスの起動

**ゴール:** GPU付きEC2インスタンスを起動し、ログに記録する。

1. `configs/aws_instance_config.json` を作成：

   ```json
   {
     "ImageId": "ami-XXXXX",
     "InstanceType": "g4dn.xlarge",
     "KeyName": "your-keypair-name",
     "SecurityGroupIds": ["sg-xxxxxxxx"],
     "SubnetId": "subnet-xxxxxxxx",
     "MinCount": 1,
     "MaxCount": 1
   }
   ```

2. EC2 インスタンスを起動し、インスタンスIDをログへ出力：

   ```bash
   INSTANCE_JSON=configs/aws_instance_config.json

   INSTANCE_ID=$(aws ec2 run-instances      --cli-input-json file://$INSTANCE_JSON      --query 'Instances[0].InstanceId'      --output text)

   echo "Launched instance: $INSTANCE_ID" >> logs/week1_env_checklist.md
   ```

3. パブリックIPを取得し、ログへ出力：

   ```bash
   PUBLIC_IP=$(aws ec2 describe-instances      --instance-ids $INSTANCE_ID      --query 'Reservations[0].Instances[0].PublicIpAddress'      --output text)

   echo "Public IP: $PUBLIC_IP" >> logs/week1_env_checklist.md
   ```

---

### Task 1-2：Isaac Sim GUI の起動とシンプルな物理シミュレーション

**ゴール:** Isaac Sim の GUI を開き、Boxが落下するシンプルなシミュレーションを実行する。

1. EC2 インスタンスにリモート接続（SSH + VNC / DCVなど）

2. Isaac Sim を起動：

   ```bash
   cd ~/isaac-sim
   ./isaac-sim.sh &
   ```

3. GUI操作：

   - `File > New` で新規シーン作成
   - `Create > Physics` から Ground Plane を追加
   - `Create > Mesh` などで Box を追加（床の上・少し上に配置）
   - `Play` ボタンを押し、Box が重力で落下・床と衝突する様子を確認

4. 観察内容を記録：

   ```markdown
   ## 物理シミュレーション観察メモ

   - 重力方向: -Z（デフォルト）
   - Box と Ground の衝突時の挙動
   - Box の反発 / 滑り具合（摩擦・反発係数の初期値）
   ```

---

### Task 1-3：最小 Digital Twin シーンの構築

**ゴール:** 床・机・箱・ロボット・カメラを含む「ミニ世界」を構築し、USDとして保存する。

1. Isaac Sim GUI 上で以下を配置：

   - Ground Plane
   - 机（Table もしくは単純なBoxをスケールして机に見立てる）
   - 机の上に Box を1つ配置
   - ロボットアーム（例: Franka Emika）
   - カメラ（机とロボットを俯瞰できる位置に配置）

2. カメラビューで机・ロボット・Box が視界に入るように調整。

3. シーンを保存：

   - `File > Save As`
   - ファイル名: `week1_minimal_world.usd`

4. シーン構成メモ：

   ```markdown
   ## week1_minimal_world.usd の構成

   - Ground Plane: (0, 0, 0)
   - Table: 原点付近に設置、高さ ~0.75m
   - Box: Table の上、ロボットの可動範囲内
   - Robot: Table の側面に設置（Franka）
   - Camera: 上部からの俯瞰視点（Table + Robot + Box が見える）
   ```

---

### Task 1-4：EC2 の停止 / 終了

**ゴール:** 不要な課金を防ぐため、インスタンスを停止または終了する。

1. インスタンス停止：

   ```bash
   aws ec2 stop-instances --instance-ids $INSTANCE_ID
   echo "Stopped instance: $INSTANCE_ID" >> logs/week1_env_checklist.md
   ```

2. 完全に不要な場合は終了：

   ```bash
   aws ec2 terminate-instances --instance-ids $INSTANCE_ID
   echo "Terminated instance: $INSTANCE_ID" >> logs/week1_env_checklist.md
   ```

---

## Week 1 のふりかえりテンプレ

```markdown
### Week 1 ふりかえり

- Isaac Sim 起動で詰まった点:
- シミュレーション環境で驚いた / 気づいた点:
- Physical AI（世界モデル）観点で理解が深まったこと:
- 来週（Week 2）で意識したいこと:
```
