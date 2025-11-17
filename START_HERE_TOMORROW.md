# 🌅 明日の作業再開ガイド

おはようございます！昨日の続きから始めましょう。

---

## 📋 クイックスタート（3ステップ）

### 1. ターミナルを開く

### 2. ワークスペースに移動
```bash
cd ~/openduck_ws
```

### 3. ROS2環境をロード
```bash
source install/setup.bash
```

**確認コマンド:**
```bash
# カスタムメッセージが使えるか確認
ros2 interface list | grep openduck
```

5つのメッセージが表示されればOK！

---

## 📚 昨日の成果を確認

### 作成したドキュメント
```bash
cd ~/OpenDuck
ls *.md
```

以下が表示されます：
- `DESIGN_DOCUMENT.md` - プロジェクト設計
- `WORKSPACE_DESIGN.md` - ROS2構造設計
- `ROS2_BASICS.md` - ROS2学習ガイド
- `PROGRESS.md` - 進捗状況（最重要！）
- `README.md` - プロジェクト概要

**まず読むべき:** `PROGRESS.md`

### 作成したROS2メッセージ
```bash
cd ~/openduck_ws/src/openduck_msgs/msg
ls
```

以下が表示されます：
- `Observation.msg` (39次元観測ベクトル)
- `Action.msg` (14次元アクション)
- `MotorState.msg`
- `MotorCommand.msg`
- `SafetyStatus.msg`

---

## 🎯 今日やること（Phase 1: IMUノード作成）

### タスク1: センサパッケージ作成
```bash
cd ~/openduck_ws/src
source /opt/ros/humble/setup.bash

ros2 pkg create --build-type ament_python openduck_sensors \
  --dependencies rclpy std_msgs sensor_msgs geometry_msgs openduck_msgs
```

### タスク2: IMUノードの実装
- 既存のBNO055テストコード (`~/OpenDuck/duck/test_bno055.py`) を参考に
- ROS2ノードとして実装
- `/imu/data` トピックに配信

### タスク3: テスト
```bash
# ノードを実行
ros2 run openduck_sensors imu_node

# 別のターミナルでデータを確認
ros2 topic echo /imu/data
```

---

## 💡 よく使うコマンド

### ROS2環境のロード
```bash
source /opt/ros/humble/setup.bash
source ~/openduck_ws/install/setup.bash
```

### ビルド
```bash
cd ~/openduck_ws
colcon build
source install/setup.bash
```

### 特定のパッケージだけビルド
```bash
colcon build --packages-select openduck_sensors
```

### トピックの確認
```bash
# トピック一覧
ros2 topic list

# トピックの中身を見る
ros2 topic echo /topic_name

# トピックの頻度を測定
ros2 topic hz /topic_name
```

### ノードの確認
```bash
# 実行中のノード一覧
ros2 node list

# ノードの詳細情報
ros2 node info /node_name
```

---

## 🔧 トラブルシューティング

### ROS2コマンドが見つからない
```bash
source /opt/ros/humble/setup.bash
```

### カスタムメッセージが見つからない
```bash
cd ~/openduck_ws
source install/setup.bash
```

### ビルドエラー
```bash
cd ~/openduck_ws
rm -rf build install log
colcon build
```

---

## 📁 重要なディレクトリ

```
~/OpenDuck/              # ドキュメント・設計資料
  ├── PROGRESS.md        # 進捗状況（最重要）
  ├── README.md          # プロジェクト概要
  └── duck/              # BNO055テストコード

~/openduck_ws/           # ROS2ワークスペース
  ├── src/               # ソースコード
  │   └── openduck_msgs/ # カスタムメッセージ（完成済み）
  ├── build/             # ビルド作業用
  ├── install/           # インストール先
  └── log/               # ログ
```

---

## 🎓 困ったときに読むドキュメント

1. **ROS2の基本がわからない** → `ROS2_BASICS.md`
2. **全体の設計を確認したい** → `DESIGN_DOCUMENT.md`
3. **ワークスペース構造がわからない** → `WORKSPACE_DESIGN.md`
4. **進捗状況を確認したい** → `PROGRESS.md`

---

## ✅ 作業開始前チェックリスト

- [ ] ターミナルを開いた
- [ ] `cd ~/openduck_ws`
- [ ] `source install/setup.bash`
- [ ] `ros2 interface list | grep openduck` で確認
- [ ] `PROGRESS.md` を読んだ

準備OK！今日も頑張りましょう 🦆

---

**Claude Codeを再起動する場合:**
このドキュメントを開いて、「明日の続きからお願いします」と伝えれば、
私がこのドキュメントを読んで、続きから開始できます！
