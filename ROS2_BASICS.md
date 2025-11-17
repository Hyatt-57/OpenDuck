# ROS2 基礎概念ガイド（OpenDuck向け）

このドキュメントでは、OpenDuck開発に必要なROS2の基本概念を、初心者向けにわかりやすく解説します。

---

## 目次
1. [ROS2とは何か？](#ros2とは何か)
2. [重要な用語](#重要な用語)
3. [ROS2の仕組み（データの流れ）](#ros2の仕組みデータの流れ)
4. [OpenDuckでの使い方](#openduckでの使い方)
5. [ワークスペースとパッケージ](#ワークスペースとパッケージ)
6. [実践：簡単なノードを作ってみよう](#実践簡単なノードを作ってみよう)

---

## ROS2とは何か？

### 一言で言うと
**「複数のプログラムが協力してロボットを動かすための仕組み」**

### 例えで理解する
工場をイメージしてください：

```
工場全体 = ロボットシステム
各部署   = ノード（プログラム）
ベルトコンベア = トピック（データの通り道）
荷物     = メッセージ（データ）
```

- **製造部署**（センサノード）が部品（センサデータ）を作る
- **検査部署**（処理ノード）がそれを検査・加工する
- **出荷部署**（アクチュエータノード）が最終製品を出荷（モータを動かす）

各部署は独立していて、ベルトコンベアで荷物をやり取りします。
これがROS2の基本的な考え方です！

---

## 重要な用語

### 1. ノード（Node）
**「独立したプログラム」**

例：
- `imu_node`: IMUセンサからデータを読むプログラム
- `motor_control_node`: モータを制御するプログラム
- `inference_node`: AI推論を実行するプログラム

**特徴：**
- 各ノードは独立して動作
- 1つのノードがクラッシュしても、他のノードは動き続ける
- ノードごとに別々の言語（Python/C++）で書ける

**Pythonでの例：**
```python
import rclpy
from rclpy.node import Node

class MyNode(Node):
    def __init__(self):
        super().__init__('my_node_name')  # ノード名を指定
        self.get_logger().info('ノードが起動しました！')

def main():
    rclpy.init()  # ROS2を初期化
    node = MyNode()
    rclpy.spin(node)  # ノードを実行し続ける
    node.destroy_node()
    rclpy.shutdown()
```

---

### 2. トピック（Topic）
**「データが流れる通り道（道路や川のようなもの）」**

例：
- `/imu/data`: IMUのデータが流れる道
- `/cmd_vel`: 速度コマンドが流れる道
- `/joint_states`: 関節の状態が流れる道

**特徴：**
- トピックには名前がある（スラッシュ/で始まる）
- 複数のノードが同じトピックから読める（1対多の通信）
- データは常に流れ続ける（パブリッシュ/サブスクライブ方式）

**イメージ図：**
```
[センサノード] ---(データを送信)--> [/sensor/data] ---(データを受信)--> [処理ノード]
                  Publisher                Topic              Subscriber
```

---

### 3. メッセージ（Message）
**「トピック上を流れるデータの型」**

例：
- `sensor_msgs/Imu`: IMUのデータ型
- `std_msgs/Float64MultiArray`: 浮動小数点数の配列
- 自作メッセージ：`openduck_msgs/Observation`（観測ベクトル用）

**メッセージの定義例：**
```
# Observation.msg（観測ベクトル）
float64[3] angular_velocity    # 角速度
float64[3] gravity_projection  # 重力投射
float64[3] command_velocity    # 目標速度
float64[14] joint_positions    # 関節位置
float64[14] previous_action    # 前回のアクション
bool[2] foot_contact           # 接地判定
```

---

### 4. パブリッシャー（Publisher）とサブスクライバー（Subscriber）

#### パブリッシャー（Publisher）
**「データを送信する側」**

```python
class SensorNode(Node):
    def __init__(self):
        super().__init__('sensor_node')
        # Publisherを作成：トピック名、メッセージ型、キューサイズ
        self.publisher = self.create_publisher(
            Float64MultiArray,
            '/sensor/data',
            10
        )

        # 10Hzでデータを送信
        self.timer = self.create_timer(0.1, self.publish_data)

    def publish_data(self):
        msg = Float64MultiArray()
        msg.data = [1.0, 2.0, 3.0]  # センサデータ
        self.publisher.publish(msg)  # データを送信！
        self.get_logger().info('データを送信しました')
```

#### サブスクライバー（Subscriber）
**「データを受信する側」**

```python
class ProcessorNode(Node):
    def __init__(self):
        super().__init__('processor_node')
        # Subscriberを作成：トピック名、メッセージ型、コールバック関数
        self.subscription = self.create_subscription(
            Float64MultiArray,
            '/sensor/data',
            self.data_callback,  # データが来たら呼ばれる関数
            10
        )

    def data_callback(self, msg):
        # データを受信したときに呼ばれる
        self.get_logger().info(f'受信: {msg.data}')
        # ここでデータを処理する
```

---

## ROS2の仕組み（データの流れ）

### OpenDuckでのデータフロー

```
┌─────────────┐
│  IMU Node   │ → /imu/data (100Hz)
└─────────────┘         ↓
                        ↓
┌─────────────┐         ↓
│ Motor State │ → /joint_states (50Hz)
│    Node     │         ↓
└─────────────┘         ↓
                        ↓         ┌──────────────────┐
┌─────────────┐         ↓         │  Observation     │
│ Foot Contact│ → /foot_contact   │  Aggregator Node │
│    Node     │         ↓         │                  │
└─────────────┘         ↓         │ ・各データを統合 │
                        ↓ ────────→│ ・時刻同期       │
┌─────────────┐         ↓         │ ・39次元作成     │
│ Gamepad     │ → /cmd_vel        └──────────────────┘
│    Node     │                            │
└─────────────┘                            │
                                          ↓
                                   /observation (50Hz)
                                          ↓
                                  ┌──────────────┐
                                  │ Inference    │
                                  │ Node         │
                                  │              │
                                  │ ・ONNX推論   │
                                  │ ・14次元出力 │
                                  └──────────────┘
                                          │
                                          ↓
                                    /action (50Hz)
                                          ↓
                                  ┌──────────────┐
                                  │ Motor Control│
                                  │ Node         │
                                  │              │
                                  │ ・モータ制御 │
                                  └──────────────┘
```

---

## OpenDuckでの使い方

### なぜノードを分けるのか？

#### メリット1：開発しやすい
```
❌ 1つの巨大なプログラム
   └─ 全部を一度に書かないといけない
   └─ バグが見つけにくい
   └─ 変更が大変

✅ 小さなノードに分割
   ├─ imu_node だけ先に開発できる
   ├─ motor_node が壊れても imu_node は動く
   └─ テストしやすい
```

#### メリット2：再利用できる
```
imu_node を一度作れば...
  ├─ 他のロボットでも使える
  ├─ 違うIMU（MPU6050など）に交換しやすい
  └─ シミュレータと実機で同じノードを使える
```

#### メリット3：並列実行できる
```
CPU Core 1: imu_node (100Hz)
CPU Core 2: inference_node (50Hz)
CPU Core 3: motor_control_node (50Hz)
CPU Core 4: safety_monitor_node (100Hz)

→ Raspberry Piの性能を最大限活用！
```

---

## ワークスペースとパッケージ

### ワークスペース（Workspace）
**「プロジェクト全体のフォルダ」**

```
openduck_ws/              ← ワークスペース（作業場所）
├── src/                  ← ソースコード置き場
│   ├── openduck_msgs/    ← メッセージ定義パッケージ
│   ├── openduck_sensors/ ← センサ関連パッケージ
│   ├── openduck_control/ ← 制御関連パッケージ
│   └── openduck_bringup/ ← 起動設定パッケージ
├── build/                ← ビルド作業用（自動生成）
├── install/              ← インストール先（自動生成）
└── log/                  ← ログファイル（自動生成）
```

### パッケージ（Package）
**「関連するノードをまとめたもの」**

```
openduck_sensors/         ← パッケージ名
├── package.xml           ← パッケージ情報（名前、依存関係など）
├── setup.py              ← Pythonパッケージ設定
├── setup.cfg             ← 追加設定
├── resource/             ← リソースファイル
└── openduck_sensors/     ← 実際のコード
    ├── __init__.py
    ├── imu_node.py       ← IMUノード
    ├── foot_contact_node.py
    └── motor_state_node.py
```

---

## 実践：簡単なノードを作ってみよう

### 例：Hello Worldを送るノード

**コード：**
```python
import rclpy
from rclpy.node import Node
from std_msgs.msg import String

class HelloPublisher(Node):
    def __init__(self):
        # ノード名を'hello_publisher'に設定
        super().__init__('hello_publisher')

        # Publisherを作成
        self.publisher = self.create_publisher(
            String,           # メッセージ型
            'hello_topic',    # トピック名
            10                # キューサイズ（バッファ）
        )

        # 1秒ごとにメッセージを送信
        self.timer = self.create_timer(1.0, self.timer_callback)
        self.count = 0

    def timer_callback(self):
        msg = String()
        msg.data = f'Hello World {self.count}'
        self.publisher.publish(msg)
        self.get_logger().info(f'送信: "{msg.data}"')
        self.count += 1

def main(args=None):
    rclpy.init(args=args)
    node = HelloPublisher()

    try:
        rclpy.spin(node)  # ノードを実行し続ける
    except KeyboardInterrupt:
        pass

    node.destroy_node()
    rclpy.shutdown()

if __name__ == '__main__':
    main()
```

**実行方法：**
```bash
# ターミナル1: Publisher実行
python3 hello_publisher.py

# ターミナル2: トピックの中身を確認
ros2 topic echo /hello_topic
```

---

## よく使うROS2コマンド一覧

### ノード関連
```bash
# 実行中のノード一覧を表示
ros2 node list

# ノードの詳細情報を表示
ros2 node info /node_name
```

### トピック関連
```bash
# トピック一覧を表示
ros2 topic list

# トピックの中身をリアルタイム表示
ros2 topic echo /topic_name

# トピックの情報を表示（型、Pub/Sub数）
ros2 topic info /topic_name

# トピックの送信頻度を測定
ros2 topic hz /topic_name

# トピックに手動でデータを送信
ros2 topic pub /topic_name std_msgs/msg/String "{data: 'test'}"
```

### パッケージ関連
```bash
# パッケージ一覧を表示
ros2 pkg list

# パッケージの場所を表示
ros2 pkg prefix package_name

# パッケージを作成
ros2 pkg create --build-type ament_python my_package
```

### ビルド関連
```bash
# ワークスペース全体をビルド
colcon build

# 特定のパッケージだけビルド
colcon build --packages-select my_package

# シンボリックリンクでビルド（開発時便利）
colcon build --symlink-install
```

---

## まとめ：OpenDuckで覚えるべきポイント

### 1. 基本構造
```
ノード（プログラム） → トピック（道） → ノード（プログラム）
     Publisher            /topic_name        Subscriber
```

### 2. OpenDuckでのノード設計
- **1ノード = 1つの役割** に専念させる
- センサ読み取り、データ処理、モータ制御を分離
- ノード間は**トピック**でデータをやり取り

### 3. 開発の流れ
```
1. ワークスペース作成
2. パッケージ作成
3. ノード実装（Pythonファイル）
4. ビルド（colcon build）
5. 実行・テスト
```

### 4. デバッグ方法
```bash
# どんなノードが動いてる？
ros2 node list

# どんなトピックがある？
ros2 topic list

# トピックの中身は？
ros2 topic echo /topic_name

# データは来てる？（頻度確認）
ros2 topic hz /topic_name
```

---

## 次のステップ

ROS2の基本概念を理解したら、次は：

1. **ワークスペースを作る** → 作業環境の準備
2. **カスタムメッセージを定義** → ObservationとAction
3. **センサノードを実装** → IMU、モータ状態など
4. **データフローを確認** → 全体が連携して動くか

頑張りましょう！
