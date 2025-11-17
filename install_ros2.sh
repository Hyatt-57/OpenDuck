#!/bin/bash
# OpenDuck用 ROS2 Humble インストールスクリプト
# Ubuntu 22.04 (aarch64) Raspberry Pi用

set -e  # エラーが発生したら即座に停止

echo "=========================================="
echo "ROS2 Humble インストール開始"
echo "=========================================="

# 色付き出力用
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ステップ1: 必要なパッケージをインストール
echo -e "\n${BLUE}[1/6] 必要なパッケージをインストール中...${NC}"
sudo apt update
sudo apt install software-properties-common curl -y
sudo add-apt-repository universe -y

# ステップ2: ROS2の公式リポジトリを追加
echo -e "\n${BLUE}[2/6] ROS2リポジトリを追加中...${NC}"
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

# ステップ3: パッケージリストを更新
echo -e "\n${BLUE}[3/6] パッケージリストを更新中...${NC}"
sudo apt update
sudo apt upgrade -y

# ステップ4: ROS2 Humbleをインストール（デスクトップ版）
echo -e "\n${BLUE}[4/6] ROS2 Humble（デスクトップ版）をインストール中...${NC}"
echo "※これには10-20分程度かかります。気長にお待ちください..."
sudo apt install ros-humble-desktop -y

# ステップ5: 開発ツールをインストール
echo -e "\n${BLUE}[5/6] 開発ツール（colcon, rosdep）をインストール中...${NC}"
sudo apt install python3-colcon-common-extensions python3-rosdep -y

# rosdepの初期化（既に初期化済みの場合はエラーを無視）
echo -e "\n${BLUE}[6/6] rosdepを初期化中...${NC}"
if [ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]; then
    sudo rosdep init
fi
rosdep update

# bashrcに自動sourceを追加（重複チェック）
echo -e "\n${BLUE}bashrcにROS2設定を追加中...${NC}"
if ! grep -q "source /opt/ros/humble/setup.bash" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# ROS2 Humble setup" >> ~/.bashrc
    echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
    echo -e "${GREEN}✓ bashrcにROS2設定を追加しました${NC}"
else
    echo -e "${GREEN}✓ bashrcには既にROS2設定があります${NC}"
fi

echo -e "\n=========================================="
echo -e "${GREEN}ROS2 Humbleのインストールが完了しました！${NC}"
echo "=========================================="
echo ""
echo "次のコマンドを実行してROS2を有効化してください："
echo "  source ~/.bashrc"
echo ""
echo "または、新しいターミナルを開いてください。"
echo ""
echo "インストール確認："
echo "  ros2 --version"
echo ""
