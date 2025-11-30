# Physical AI 学習ロードマップ  
Isaac Sim × Digital Twin × Robotics

## 概要

このリポジトリは、Physical AI（AI × ロボティクス × シミュレーション）の基礎を  
**1ヶ月（4週間）で体系的に学ぶためのロードマップ**です。

### 学習の主なゴール

- **世界モデル（World Model）**：AIから見た「物理世界」の理解
- **身体性（Embodiment）**：ロボットの身体と制約を踏まえた行動生成
- **Digital Twin**：工場・ライン・作業環境のデジタル再現
- **AI Robotics**：自己学習 / 模倣学習によるロボット動作の獲得

これらを通じて、製造業DX・ロボティクス案件で活きる  
**Physical AI 的な視点と実装感覚** を獲得することを目的とする。

---

## リポジトリ構成（推奨）

```bash
physical-ai-roadmap/
├── README.md                         # このファイル（全体ロードマップ）
├── notes/
│   ├── week1_world_model.md          # Week1: 世界モデル・シミュレーション
│   ├── week2_embodiment.md           # Week2: 身体性 & マニピュレーション
│   ├── week3_digital_twin.md         # Week3: デジタルツイン
│   └── week4_ai_robotics.md          # Week4: AIロボティクス & 学習
├── logs/
│   ├── week1_env_checklist.md
│   ├── week2_tasks.md
│   ├── week3_tasks.md
│   └── week4_tasks.md
├── configs/
│   ├── aws_instance_config.json      # EC2 起動用の設定例
│   └── isaac_sim_settings.json       # Isaac Sim 起動設定メモ
└── screenshots/
    ├── week1/
    ├── week2/
    ├── week3/
    └── week4/
```

---

## 4週間ロードマップの概要

### Week 1：World Model ─ シミュレーションとしての「世界」を理解する

- Isaac Sim をクラウド（例: AWS g4dn.xlarge）で起動
- Ground / Box / Robot / Camera からなる「ミニ世界」を構築
- 物理シミュレーション（重力 / 衝突）を体感
- 結果や気づきを `notes/week1_world_model.md` に記録

👉 詳細タスク: `notes/week1_world_model.md`

---

### Week 2：Embodiment & Manipulation ─ ロボットの身体性と行動

- Pick & Place Example を Isaac Sim 上で実行
- タスク条件（位置 / 個数 / 制約）を変更し、挙動の違いを観察
- ロボットの関節制約や衝突条件を整理
- 結果や制約メモを `notes/week2_embodiment.md` に記録

👉 詳細タスク: `notes/week2_embodiment.md`

---

### Week 3：Digital Twin ─ 物理プロセスのデジタル再現

- ミニ工場レイアウト（机 or コンベア + 部品 + ロボット + カメラ）を構築
- 1サイクルの作業フロー（供給→ピック→配置）をシミュレーション
- カメラ視点・死角・動線などを評価し、改善案を2パターン作成
- 内容を `notes/week3_digital_twin.md` にまとめる

👉 詳細タスク: `notes/week3_digital_twin.md`

---

### Week 4：AI Robotics ─ 学習するロボットと自律行動

- 学習用タスク（例: Isaac Orbit の Pick & Place）を実行
- 少量の模倣データでポリシーを学習させる流れを体験
- 画像 → 簡易AI → ロボット制御の「見て動く」ミニループを構築
- Sim2Real を意識したランダム化で、頑健性を観察
- 結果を `notes/week4_ai_robotics.md` に整理

👉 詳細タスク: `notes/week4_ai_robotics.md`

---

## 前提・環境

- AWS アカウント & AWS CLI 設定済み
- Isaac Sim が動作する GPU インスタンス（例: g4dn.xlarge）
- （任意）ローカルに ROS2 + Gazebo 環境を構築し、将来の実機連携に備える

---

## ログとナレッジの蓄積方法

- 実行したタスク・コマンド・エラーなど → `logs/weekX_*.md`
- 気づき・設計メモ・Physical AI 観点での学び → `notes/weekX_*.md`
- スクリーンショット → `screenshots/weekX/`

このリポジトリ全体を、自分 or AIエージェントの  
**「Physical AI ラボ & ランブック」** として育てていくことを想定している。
