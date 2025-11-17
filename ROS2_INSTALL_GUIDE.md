# ROS2 Humble インストールガイド（Ubuntu 22.04 Raspberry Pi用）

## ROS2とは？
ROS2（Robot Operating System 2）はロボット開発のためのフレームワークです。
複数のプログラム（ノード）が互いにデータをやり取りしながら協調動作できます。

## なぜROS2を使うのか？
- **モジュール化**: センサ、推論、モータ制御を独立したプログラムとして開発できる
- **再利用性**: 一度書いたノードを他のロボットでも使える
- **デバッグ**: データを記録・再生できる（ROS bag）
- **可視化**: rviz2で状態をリアルタイム表示できる

---

## インストール手順

### 1. ロケール設定（文字コード設定）
```bash
# UTF-8が使えるか確認
locale

# UTF-8を有効化
sudo apt update && sudo apt install locales
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8
```

### 2. ROS2のリポジトリを追加
```bash
# Ubuntuのパッケージリストが最新か確認
sudo apt install software-properties-common
sudo add-apt-repository universe

# ROS2の公式リポジトリを追加
sudo apt update && sudo apt install curl -y
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg

# リポジトリをソースリストに追加
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
```

### 3. ROS2 Humbleをインストール
```bash
# パッケージリストを更新
sudo apt update
sudo apt upgrade

# ROS2 Humble（デスクトップ版：推奨）
# デスクトップ版にはrviz2などの可視化ツールが含まれます
sudo apt install ros-humble-desktop -y

# もし容量が厳しい場合は基本版（rviz2なし）
# sudo apt install ros-humble-ros-base -y
```

### 4. 開発ツールのインストール
```bash
# colcon: ROS2のビルドツール
# rosdep: 依存関係を自動インストールするツール
sudo apt install python3-colcon-common-extensions python3-rosdep -y

# rosdepの初期化
sudo rosdep init
rosdep update
```

### 5. 環境設定を自動化
```bash
# ROS2を使うには毎回「source」する必要がある
# これを自動化するために.bashrcに追記

echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
source ~/.bashrc
```

---

## インストール確認

### テスト1: ROS2が動くか確認
```bash
# ターミナル1
ros2 run demo_nodes_cpp talker

# 新しいターミナル2を開いて
ros2 run demo_nodes_py listener
```
→ talkerが"Hello World"を送り、listenerが受信すればOK！

### テスト2: インストールされたパッケージ確認
```bash
ros2 pkg list
```
→ たくさんのパッケージ名が表示されればOK

---

## よく使うROS2コマンド

```bash
# ノード（プログラム）の一覧を表示
ros2 node list

# トピック（データの通り道）の一覧を表示
ros2 topic list

# トピックの中身を表示
ros2 topic echo /topic_name

# ノードの情報を表示
ros2 node info /node_name

# パッケージを作成
ros2 pkg create --build-type ament_python my_package
```

---

## 次のステップ
ROS2がインストールできたら、OpenDuckのワークスペースを作成します！
