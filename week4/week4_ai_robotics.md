# Week 4：AI Robotics ─ 学習するロボットと自律行動

## 目的

- 学習用タスク（Pick & Place など）の学習プロセスを一通り実行する
- 少量の模倣データ（5〜20軌跡）でのポリシー学習を体験する
- 画像 → 簡易AI → ロボット制御の「見て動く」ミニループを作る
- Sim2Real を意識したドメインランダム化の効果を観察する

---

## タスク一覧

### Task 4-1：学習用タスク（例: Isaac Orbit）の起動

**ゴール:** 学習前後でポリシーの挙動が変化するタスクを実際に動かす。

1. 学習フレームワークのリポジトリをクローン（例）：

   ```bash
   cd ~/work
   git clone <orbit_repo_url> isaac-orbit
   cd isaac-orbit
   ```

2. 必要な依存関係をインストール（リポジトリの README に従う）

3. 学習スクリプトを実行（例）：

   ```bash
   python train_pick_and_place.py      --num-envs 64      --max-steps 100000
   ```

4. 学習前後の評価スクリプトを実行し、成功率などを `logs/week4_tasks.md` に記録：

   ```markdown
   ## Task 4-1: 学習タスク実行ログ

   - タスク: Pick & Place
   - 学習ステップ: 100k
   - 学習前成功率: 5/100
   - 学習後成功率: 78/100
   - 観察メモ:
     - 学習後は把持位置のばらつきが減少
     - 特定の初期位置ではまだ失敗しやすい
   ```

---

### Task 4-2：模倣データ少量での学習

**ゴール:** 少量デモでの模倣学習フローを一周してみる。

1. Isaac Sim 上でデモデータ収集：

   - 手動操作 or スクリプトで、箱を掴んで所定位置に置く動作を 5〜20回実行
   - それぞれの軌跡（Joint角度 / End-effector Pose / Gripper状態）を記録

2. `data/imitation/week4_demo_01/` に保存：

   ```bash
   mkdir -p data/imitation/week4_demo_01
   # 軌跡ファイル（例: .json / .npz）をこの中に配置
   ```

3. 模倣学習スクリプトの実行例：

   ```bash
   python train_imitation.py      --demo-dir data/imitation/week4_demo_01      --output-dir runs/imitation_week4_01
   ```

4. 学習済みポリシーをテストし、成功率・失敗パターンを `logs/week4_tasks.md` に記録。

---

### Task 4-3：カメラ画像 → 簡易AI → ロボット制御のミニループ構築

**ゴール:** 単純でいいので「見て→判定して→動く」ループを実現する。

1. カメラ画像を取得するスクリプトを作成（例: `scripts/capture_camera_frame.py`）：

   ```python
   # 疑似コード例
   # - Isaac Sim からカメラのRGBA画像を取得
   # - /tmp/frames/frame_0001.png のように保存
   ```

2. 簡易「AI」ロジック（実際はルールベースでもOK）を作成（例: `scripts/simple_policy.py`）：

   - 画像の特定領域の明るさ or 色を見て
     - 明るければ「箱は右」→ 右のターゲット位置へ移動
     - 暗ければ「箱は左」→ 左のターゲット位置へ移動

3. ロボットの目標ポーズを切り替えるコードを用意：

   ```python
   # simple_policy.py の中で:
   # - 判定結果に応じてターゲットポーズを設定
   # - Isaac Sim / Orbit のAPI経由でコマンド送信
   ```

4. 1サイクルの「見て→判定→動く」動作を確認し、フローをこのファイルに記録：

   ```markdown
   ## 見て動くミニループ概要

   1. カメラ画像キャプチャ（/tmp/frames/frame_xxxx.png）
   2. 画像の右半分の平均輝度を計算
   3. 閾値 T を超えたら「右に箱あり」と判定
   4. ロボットのターゲットポーズを右 or 左に切り替え
   5. MoveIt/軌跡生成 → 実行
   ```

---

### Task 4-4：Sim2Real を意識したランダム化実験

**ゴール:** ドメインランダム化がポリシーの頑健性に与える影響を観察する。

1. 学習環境側で以下のパラメータをランダム化：

   - Box の初期位置（±数cm）
   - Box の質量・摩擦係数
   - 照明の明るさ・方向

2. ランダム化あり / なし で同じポリシーを 100エピソードずつ評価する擬似コード：

   ```python
   def eval_policy(randomize: bool, episodes: int = 100):
       successes = 0
       for i in range(episodes):
           if randomize:
               randomize_env()
           reset_env()
           if run_policy_episode():
               successes += 1
       return successes / episodes
   ```

3. 結果を `logs/week4_tasks.md` に記録し、Sim2Real 観点で考察をまとめる：

   ```markdown
   ## ドメインランダム化実験結果

   - ランダム化なし成功率: 92%
   - ランダム化あり成功率: 81%
   - 観察:
     - ランダム化ありの方が平均成功率はやや下がるが、
       特定の条件（重い箱・暗い照明）でも破綻しにくくなった。
   ```

---

## Week 4 のふりかえりテンプレ

```markdown
### Week 4 ふりかえり

- 学習タスク（RL / 模倣）を通じて分かった「AIが物理世界から学ぶ」仕組み:
- 少量デモ学習（模倣）で見えた限界・可能性:
- Sim2Real ギャップをどう埋めるべきかのアイデア:
- 今後 深堀りしたい Physical AI のテーマ（例: Diffusion Policy / VLM連携 など）:
```
