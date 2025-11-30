# Week 2：Embodiment & Manipulation ─ ロボットの身体性と行動

## 目的

- Isaac Sim 上で Pick & Place タスクを実行できるようにする
- タスク条件（位置・個数・制約）を変えたときの挙動を観察する
- ロボットの身体制約（関節リミット・干渉・可到達範囲）を整理する

---

## 前提条件

- Week 1 で Isaac Sim 環境がセットアップ済み
- `week1_minimal_world.usd` が保存済み
- EC2 インスタンスを再起動できる

---

## タスク一覧

### Task 2-1：EC2 再起動 & 前週シーン読み込み

**ゴール:** Week1 の環境を再現する。

1. EC2 インスタンスを起動（停止していた場合）：

   ```bash
   aws ec2 start-instances --instance-ids $INSTANCE_ID
   ```

2. パブリックIPを確認し、リモート接続  
3. Isaac Sim 起動 → `week1_minimal_world.usd` を読み込む

---

### Task 2-2：Pick & Place Example の実行

**ゴール:** 標準の Pick & Place Example を動かして、基本挙動を把握する。

1. Isaac Sim GUI で Example を開く（例）：

   - メニューから `Examples > Robotics > Manipulation > Pick and Place` を選択

2. シミュレーションを再生：
   - ロボットが箱を掴む
   - 箱を持ち上げる
   - 指定場所に置く

3. `logs/week2_tasks.md` に記録：

   ```markdown
   ## Task 2-2: Pick & Place Example 実行結果

   - 使用ロボット: Franka Emika
   - 把持対象: Box
   - 試行回数: 3回
   - 成功/失敗:
     - Run1: 成功
     - Run2: 成功
     - Run3: 成功
   - 観察メモ:
     - グリッパの開閉タイミング
     - Z方向からのアプローチが基本
   ```

---

### Task 2-3：タスク条件の改造と挙動比較

**ゴール:** 環境やパラメータを少し変えることで、挙動や成功率の変化を体感する。

**変更例：**

- 置き場所の座標を X 方向に +10cm
- 箱を2つに増やし、順番に運ぶ
- わざとロボットの可到達範囲ギリギリに箱を配置

**手順：**

1. 各条件パターンごとにシーンを調整  
2. シミュレーションを複数回実行  
3. 結果をこのファイルに記録：

   ```markdown
   ## 条件変更パターンと結果

   ### パターンA: 置き場所を X+10cm に変更
   - 結果: 3/3 成功
   - メモ: Joint5 の回転量が増加、パスは安定

   ### パターンB: 箱を2つに増やして左→右の順に運搬
   - 結果: 1個目成功、2個目で把持位置ずれ（2/3回）
   - 仮説:
     - 2個目の初期位置が視野ギリギリ
     - グリッパの閉じる位置が物体中心からずれている
   ```

---

### Task 2-4：ロボットの身体制約の整理

**ゴール:** ロボットの「体のルール」を明文化し、後のデジタルツイン設計に活かす。

1. Isaac Sim の UI から該当ロボット（例: Franka）の Joint パラメータを確認：

   - 角度制限（Joint limits）
   - 速度・トルク制限
   - 衝突形状（Collision Shapes）

2. `notes/week2_embodiment.md` に構造化して記載：

   ```markdown
   ## ロボット身体制約（Franka Emika 例）

   ### ジョイントリミット（角度）
   - Joint1: [-2.9, 2.9] rad
   - Joint2: [-1.76, 1.76] rad
   - Joint3: [-2.9, 2.9] rad
   - Joint4: [-3.07, -0.07] rad
   - Joint5: [-2.9, 2.9] rad
   - Joint6: [-0.01, 3.75] rad
   - Joint7: [-2.9, 2.9] rad

   ### 典型的な干渉・制約
   - 自己干渉:
     - 肩〜肘まわりで特定の角度を超えると Link 間干渉が発生
   - 環境との干渉:
     - 机角に対してエンドエフェクタが近づきすぎると衝突
   ```

---

## Week 2 のふりかえりテンプレ

```markdown
### Week 2 ふりかえり

- Manipulation / Pick & Place を触ってみて分かったこと:
- 条件変更で顕在化したロボットの制約・弱点:
- 「身体性（Embodiment）」の観点で新しく理解したこと:
- Week 3 の Digital Twin で試したいアイデア:
```
