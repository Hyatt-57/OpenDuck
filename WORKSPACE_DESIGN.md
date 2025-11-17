# OpenDuck ワークスペース設計図

このドキュメントでは、OpenDuckプロジェクトのROS2ワークスペース全体の構造を詳しく説明します。

---

## ワークスペース全体構造

```
openduck_ws/                      # ワークスペースのルート
│
├── src/                          # ソースコード置き場
│   ├── openduck_msgs/            # カスタムメッセージ定義
│   ├── openduck_bringup/         # 起動設定・launchファイル
│   ├── openduck_sensors/         # センサノード群
│   ├── openduck_control/         # 制御系ノード群
│   └── openduck_description/     # ロボットモデル（URDF等）※将来的に
│
├── build/                        # ビルド作業用（自動生成、gitignore）
├── install/                      # インストール先（自動生成、gitignore）
├── log/                          # ログファイル（自動生成、gitignore）
│
└── models/                       # 学習済みモデル置き場（ワークスペース外）
    └── policy.onnx               # GenesisからエクスポートしたONNXモデル
```

---

## パッケージ詳細

### 1. openduck_msgs（メッセージ定義パッケージ）

**目的**: OpenDuck専用のカスタムメッセージ型を定義

```
openduck_msgs/
├── CMakeLists.txt                # ビルド設定（メッセージ用）
├── package.xml                   # パッケージ情報
└── msg/                          # メッセージ定義フォルダ
    ├── Observation.msg           # 観測ベクトル（39次元）
    ├── Action.msg                # アクション（14次元）
    ├── MotorState.msg            # 単一モータの状態
    ├── MotorCommand.msg          # 単一モータへの指令
    └── SafetyStatus.msg          # 安全監視の状態
```

#### Observation.msg（観測ベクトル）
```
# OpenDuck観測ベクトル（39次元）
std_msgs/Header header

# ベース角速度（IMUから）
float64[3] angular_velocity       # [rad/s] (x, y, z)

# 重力ベクトル投射（IMUから）
float64[3] gravity_projection     # 正規化済み (x, y, z)

# コマンド速度（ゲームパッドから）
float64[3] command_velocity       # (vx, vy, omega_z)

# 関節位置（モータから）
float64[14] joint_positions       # [rad] 各関節の現在位置

# 前回のアクション（Aggregatorが保持）
float64[14] previous_action       # 前の制御周期のアクション

# 足裏接地判定
bool[2] foot_contact              # [右足, 左足]
```

#### Action.msg（アクション）
```
# OpenDuckアクション（14次元）
std_msgs/Header header

# モータ目標値
float64[14] target_positions      # [rad] 各関節の目標位置
```

#### MotorState.msg
```
# 単一モータの状態
uint8 motor_id                    # モータID（0-13）
float64 position                  # 現在位置 [rad]
float64 velocity                  # 現在速度 [rad/s]
float64 current                   # 電流 [A]
float64 temperature               # 温度 [℃]
bool error                        # エラーフラグ
```

#### MotorCommand.msg
```
# 単一モータへの指令
uint8 motor_id                    # モータID（0-13）
float64 target_position           # 目標位置 [rad]
float64 max_speed                 # 最大速度 [rad/s]（オプション）
```

#### SafetyStatus.msg
```
# 安全監視の状態
std_msgs/Header header

bool is_safe                      # 全体の安全状態
float64 imu_roll                  # ロール角 [rad]
float64 imu_pitch                 # ピッチ角 [rad]
float64 battery_voltage           # バッテリー電圧 [V]
bool emergency_stop               # 緊急停止フラグ
string[] error_messages           # エラーメッセージリスト
```

---

### 2. openduck_sensors（センサノード群）

**目的**: 各種センサからデータを取得してROS2トピックに配信

```
openduck_sensors/
├── package.xml
├── setup.py
├── setup.cfg
├── resource/
│   └── openduck_sensors
└── openduck_sensors/
    ├── __init__.py
    ├── imu_node.py               # BNO055 IMUノード
    ├── foot_contact_node.py      # 足裏スイッチノード
    ├── motor_state_node.py       # モータ状態取得ノード
    ├── gamepad_node.py           # Xboxコントローラノード
    └── drivers/                  # ハードウェアドライバ
        ├── __init__.py
        ├── bno055_driver.py      # BNO055通信クラス
        ├── sts3215_driver.py     # Feetech STS3215ドライバ
        └── lx16a_driver.py       # Hiwonder LX16Aドライバ
```

#### 各ノードの役割

| ノード名 | 配信トピック | 周期 | 役割 |
|---------|-------------|------|------|
| `imu_node` | `/imu/data` | 100Hz | 角速度、重力方向を配信 |
| `foot_contact_node` | `/foot_contact` | 200Hz | 左右足の接地状態を配信 |
| `motor_state_node` | `/motor_states` | 50Hz | 14モータの状態を配信 |
| `gamepad_node` | `/cmd_vel` | 30Hz | ゲームパッドからの速度コマンドを配信 |

---

### 3. openduck_control（制御系ノード群）

**目的**: センサデータを処理し、推論を実行し、モータを制御

```
openduck_control/
├── package.xml
├── setup.py
├── setup.cfg
├── resource/
│   └── openduck_control
├── config/                       # 設定ファイル
│   ├── motor_config.yaml         # モータID、可動範囲など
│   ├── safety_limits.yaml        # 安全限界値
│   └── inference_config.yaml     # 推論設定（モデルパスなど）
└── openduck_control/
    ├── __init__.py
    ├── observation_aggregator_node.py  # 観測ベクトル集約
    ├── inference_node.py               # ONNX推論実行
    ├── motor_control_node.py           # モータ制御
    ├── safety_monitor_node.py          # 安全監視
    └── utils/
        ├── __init__.py
        ├── onnx_runner.py              # ONNXランタイムラッパー
        ├── action_filter.py            # アクションのフィルタリング
        └── time_synchronizer.py        # 時刻同期ユーティリティ
```

#### 各ノードの詳細

##### observation_aggregator_node.py
```
購読トピック:
  - /imu/data (sensor_msgs/Imu)
  - /foot_contact (std_msgs/Bool[2])
  - /motor_states (openduck_msgs/MotorState[])
  - /cmd_vel (geometry_msgs/Twist)

配信トピック:
  - /observation (openduck_msgs/Observation) @ 50Hz

役割:
  1. 各センサデータを購読
  2. tf2で時刻同期（最新のデータセットを作成）
  3. 39次元の観測ベクトルに整形
  4. 前回のアクションを記憶・追加
```

##### inference_node.py
```
購読トピック:
  - /observation (openduck_msgs/Observation)

配信トピック:
  - /action (openduck_msgs/Action) @ 50Hz

役割:
  1. 観測ベクトルを受信
  2. ONNXランタイムで推論実行
  3. アクションをクリッピング（-1 ~ 1など）
  4. スケーリング（ラジアンに変換）
  5. ローパスフィルタ適用（急激な変化を抑制）
  6. 推論時間を計測・記録
```

##### motor_control_node.py
```
購読トピック:
  - /action (openduck_msgs/Action)
  - /safety_status (openduck_msgs/SafetyStatus)

配信トピック:
  - なし（モータへ直接指令）

役割:
  1. アクションを受信
  2. 安全状態を確認
  3. STS3215グループ（10モータ）に指令送信
  4. LX16Aグループ（4モータ）に指令送信
  5. エラーハンドリング
```

##### safety_monitor_node.py
```
購読トピック:
  - /imu/data (姿勢監視)
  - /motor_states (電流・温度監視)
  - /battery_voltage (電圧監視) ※将来的に

配信トピック:
  - /safety_status (openduck_msgs/SafetyStatus) @ 100Hz
  - /emergency_stop (std_msgs/Bool)

役割:
  1. IMUで転倒検知（ロール/ピッチが閾値超過）
  2. モータ電流監視（過負荷検知）
  3. モータ温度監視（過熱検知）
  4. バッテリー電圧監視（低電圧検知）
  5. 異常時に緊急停止信号を配信
```

---

### 4. openduck_bringup（起動設定）

**目的**: すべてのノードを一括起動するためのlaunchファイル

```
openduck_bringup/
├── package.xml
├── setup.py
├── setup.cfg
├── resource/
│   └── openduck_bringup
├── config/                       # パラメータファイル
│   └── openduck.yaml
└── launch/                       # Launchファイル
    ├── openduck_full.launch.py   # 全ノード起動
    ├── sensors_only.launch.py    # センサのみ
    ├── control_only.launch.py    # 制御のみ（開発用）
    └── test_imu.launch.py        # IMUテスト用
```

#### openduck_full.launch.py（全体起動）
```python
from launch import LaunchDescription
from launch_ros.actions import Node

def generate_launch_description():
    return LaunchDescription([
        # センサノード群
        Node(
            package='openduck_sensors',
            executable='imu_node',
            name='imu_node',
            output='screen'
        ),
        Node(
            package='openduck_sensors',
            executable='foot_contact_node',
            name='foot_contact_node'
        ),
        Node(
            package='openduck_sensors',
            executable='motor_state_node',
            name='motor_state_node'
        ),
        Node(
            package='openduck_sensors',
            executable='gamepad_node',
            name='gamepad_node'
        ),

        # 制御ノード群
        Node(
            package='openduck_control',
            executable='observation_aggregator_node',
            name='observation_aggregator'
        ),
        Node(
            package='openduck_control',
            executable='inference_node',
            name='inference_node',
            parameters=[{
                'model_path': '/home/hayato/OpenDuck/models/policy.onnx'
            }]
        ),
        Node(
            package='openduck_control',
            executable='motor_control_node',
            name='motor_control_node'
        ),

        # 安全監視ノード
        Node(
            package='openduck_control',
            executable='safety_monitor_node',
            name='safety_monitor'
        ),
    ])
```

---

## トピック構成図

```
                    ┌──────────────┐
                    │  imu_node    │
                    └──────┬───────┘
                           │ /imu/data (100Hz)
                           │
    ┌──────────────┐       │       ┌──────────────────┐
    │foot_contact  │───────┼───────│                  │
    │    _node     │       │       │  observation_    │
    └──────────────┘       │       │  aggregator_node │
         │ /foot_contact   │       │                  │
         │ (200Hz)         ↓       │  ・時刻同期      │
         │          ┌─────────┐    │  ・39次元作成    │
         └─────────→│         │───→│  ・前回Action記憶│
                    │         │    └──────────────────┘
    ┌──────────────┐│         │             │
    │motor_state   ││  Sync   │             │ /observation
    │    _node     ││  Buffer │             │ (50Hz)
    └──────┬───────┘│         │             ↓
           │        │         │    ┌──────────────────┐
           │ /motor_states    │    │  inference_node  │
           │ (50Hz)  │        │    │                  │
           └────────→│        │    │  ・ONNX推論      │
                     │        │    │  ・フィルタリング│
    ┌──────────────┐ │        │    │  ・スケーリング  │
    │ gamepad_node │ │        │    └──────────────────┘
    └──────┬───────┘ └────────┘             │
           │                                │ /action
           │ /cmd_vel (30Hz)                │ (50Hz)
           └────────────────────────────────┤
                                            ↓
                                   ┌──────────────────┐
                                   │ motor_control_   │
                                   │      node        │
                          ┌────────│                  │
                          │        │  ・STS3215制御   │
                          │        │  ・LX16A制御     │
                          │        └──────────────────┘
                          │
                          │ /safety_status (100Hz)
                          │
                   ┌──────┴───────────┐
                   │ safety_monitor_  │
                   │      node        │
                   │                  │
                   │  ・転倒検知      │
                   │  ・過負荷検知    │
                   │  ・緊急停止      │
                   └──────────────────┘
```

---

## 設定ファイルの例

### config/motor_config.yaml
```yaml
# モータ設定
motors:
  # STS3215グループ（右脚）
  - id: 0
    name: "right_hip_roll"
    type: "sts3215"
    serial_port: "/dev/ttyUSB0"
    min_position: -0.785  # -45度
    max_position: 0.785   # +45度

  - id: 1
    name: "right_hip_pitch"
    type: "sts3215"
    serial_port: "/dev/ttyUSB0"
    min_position: -1.57
    max_position: 1.57

  # ... (他のモータも同様に定義)

  # LX16Aグループ
  - id: 10
    name: "head_pan"
    type: "lx16a"
    serial_port: "/dev/ttyUSB1"
    min_position: -1.57
    max_position: 1.57
```

### config/safety_limits.yaml
```yaml
# 安全限界値
safety:
  max_roll: 0.52          # 最大ロール角 [rad] (30度)
  max_pitch: 0.52         # 最大ピッチ角 [rad] (30度)
  max_motor_current: 2.0  # 最大モータ電流 [A]
  max_motor_temp: 70.0    # 最大モータ温度 [℃]
  min_battery_voltage: 11.0  # 最低バッテリー電圧 [V]
```

---

## ビルド・実行手順

### 1. ワークスペース作成
```bash
cd ~
mkdir -p openduck_ws/src
cd openduck_ws
```

### 2. パッケージ作成（後ほど実施）
```bash
cd ~/openduck_ws/src

# メッセージパッケージ
ros2 pkg create --build-type ament_cmake openduck_msgs

# センサパッケージ
ros2 pkg create --build-type ament_python openduck_sensors \
  --dependencies rclpy std_msgs sensor_msgs geometry_msgs

# 制御パッケージ
ros2 pkg create --build-type ament_python openduck_control \
  --dependencies rclpy std_msgs openduck_msgs

# 起動設定パッケージ
ros2 pkg create --build-type ament_python openduck_bringup
```

### 3. ビルド
```bash
cd ~/openduck_ws
colcon build --symlink-install
source install/setup.bash
```

### 4. 実行
```bash
# 全ノード起動
ros2 launch openduck_bringup openduck_full.launch.py

# センサのみテスト
ros2 launch openduck_bringup sensors_only.launch.py

# 個別ノード起動
ros2 run openduck_sensors imu_node
```

---

## 開発フェーズ

### Phase 1: メッセージ定義（最初にやる）
- [ ] openduck_msgsパッケージ作成
- [ ] Observation.msg定義
- [ ] Action.msg定義
- [ ] その他メッセージ定義
- [ ] ビルド確認

### Phase 2: センサノード（個別にテスト）
- [ ] imu_node実装
- [ ] foot_contact_node実装
- [ ] motor_state_node実装
- [ ] gamepad_node実装

### Phase 3: 制御ノード
- [ ] observation_aggregator_node実装
- [ ] inference_node実装（ダミーモデルでテスト）
- [ ] motor_control_node実装

### Phase 4: 安全・統合
- [ ] safety_monitor_node実装
- [ ] launchファイル作成
- [ ] 全体統合テスト

---

## 次のステップ

ROS2のインストールが完了したら：

1. **ワークスペースを作成** (`mkdir -p ~/openduck_ws/src`)
2. **メッセージパッケージから作成** （他のパッケージが依存するため）
3. **センサノードを1つずつテスト** （IMUノードから始める）
4. **全体を統合**

準備はバッチリです！
