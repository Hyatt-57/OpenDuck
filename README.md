# OpenDuck - 二足歩行ロボットプロジェクト

OpenDuckは、強化学習（RL）と実機制御を組み合わせた二足歩行ロボットの開発プロジェクトです。

## プロジェクト概要

- **学習環境**: Genesis シミュレータ
- **推論環境**: Raspberry Pi + ONNX Runtime
- **制御フレームワーク**: ROS2 Humble
- **モータ**: Feetech STS3215 (×10), Hiwonder LX16A (×4)
- **IMU**: BNO055
- **コントローラ**: Xbox One (Bluetooth)

---

## ドキュメント

### 📚 設計ドキュメント
- **[DESIGN_DOCUMENT.md](./DESIGN_DOCUMENT.md)** - プロジェクト全体の設計方針と構成
- **[WORKSPACE_DESIGN.md](./WORKSPACE_DESIGN.md)** - ROS2ワークスペースの詳細設計図

### 🎓 学習ドキュメント
- **[ROS2_BASICS.md](./ROS2_BASICS.md)** - ROS2の基本概念（初心者向け）
- **[ROS2_INSTALL_GUIDE.md](./ROS2_INSTALL_GUIDE.md)** - ROS2 Humbleのインストール手順

### 🔧 センサ関連
- **[duck/README_BNO055.md](./duck/README_BNO055.md)** - BNO055 IMUセンサの情報

---

## クイックスタート

### 1. ROS2のインストール
```bash
# インストールスクリプトを実行
./install_ros2.sh

# インストール確認
source ~/.bashrc
ros2 --version
```

### 2. ワークスペースの作成
```bash
# ワークスペースを作成
mkdir -p ~/openduck_ws/src
cd ~/openduck_ws

# このリポジトリをワークスペースにリンク
ln -s ~/OpenDuck/src/* ~/openduck_ws/src/

# ビルド
colcon build --symlink-install
source install/setup.bash
```

### 3. センサテスト
```bash
# IMUのテスト
cd duck
python3 test_bno055.py
```

---

## システムアーキテクチャ

```
┌─────────────────┐
│  Genesisシミュ  │ → 学習 → policy.pt → ONNX変換 → policy.onnx
└─────────────────┘                                        ↓
                                                           ↓
┌────────────────────────────────────────────────────────────┐
│ Raspberry Pi (ROS2 Humble)                                 │
│                                                            │
│  センサノード → 観測集約 → 推論 → モータ制御               │
│  (IMU, 足裏,    (39次元)   (ONNX)  (14モータ)              │
│   モータ状態,                                              │
│   ゲームパッド)                                            │
│                                                            │
│  安全監視ノード (常時監視・緊急停止)                       │
└────────────────────────────────────────────────────────────┘
```

---

## ハードウェア構成

### モータ構成（14個）
- **右脚**: STS3215 ×5（股関節ロール、ピッチ、ヨー、膝、足首）
- **左脚**: STS3215 ×5（同上）
- **その他**: LX16A ×4（頭部、腕など）

### センサ
- **IMU**: BNO055（I2C接続）- 角速度・重力方向
- **足裏センサ**: リミットスイッチ ×2（GPIO接続）
- **モータエンコーダ**: 各モータ内蔵

### 制御入力
- **Xbox Oneコントローラ**（Bluetooth）- 速度コマンド

---

## 観測ベクトル（39次元）

| 項目 | 次元数 | 取得元 | 説明 |
|-----|-------|--------|------|
| ベース角速度 | 3 | BNO055 | ロボット本体の回転速度 |
| 重力投射 | 3 | BNO055 | 3軸方向の重力成分 |
| 目標速度コマンド | 3 | Xboxコントローラ | 前後・左右・回転速度 |
| 関節位置 | 14 | モータエンコーダ | 各関節の現在角度 |
| 前回アクション | 14 | 制御ループ | 1周期前のモータ指令 |
| 接地判定 | 2 | リミットスイッチ | 左右足の接地状態 |

---

## アクション（14次元）

各モータへの目標位置指令（ラジアン単位）

---

## 開発ロードマップ

### Phase 1: 環境構築 ✅
- [x] BNO055センサテスト
- [x] 設計ドキュメント作成
- [ ] ROS2インストール

### Phase 2: ROS2基盤構築
- [ ] ワークスペース作成
- [ ] カスタムメッセージ定義
- [ ] センサノード実装（IMU, 足裏, モータ状態, ゲームパッド）

### Phase 3: 制御ループ
- [ ] 観測ベクトル集約ノード
- [ ] ONNX推論ノード（ダミーモデルでテスト）
- [ ] モータ制御ノード

### Phase 4: 安全・統合
- [ ] 安全監視ノード
- [ ] Launchファイル作成
- [ ] 全体統合テスト

### Phase 5: 学習・Sim-to-Real
- [ ] Genesisでポリシー学習
- [ ] ONNX変換
- [ ] 実機テスト・微調整

---

## ディレクトリ構成

```
OpenDuck/
├── README.md                     # このファイル
├── DESIGN_DOCUMENT.md            # 設計ドキュメント
├── WORKSPACE_DESIGN.md           # ワークスペース設計図
├── ROS2_BASICS.md                # ROS2学習資料
├── ROS2_INSTALL_GUIDE.md         # インストールガイド
├── install_ros2.sh               # インストールスクリプト
├── duck/                         # センサテスト・開発用
│   ├── test_bno055.py
│   ├── main.py
│   └── ...
└── openduck_ws/                  # ROS2ワークスペース（作成予定）
    └── src/
        ├── openduck_msgs/
        ├── openduck_sensors/
        ├── openduck_control/
        └── openduck_bringup/
```

---

## 必要な依存パッケージ

### システム
- Ubuntu 22.04 (aarch64)
- ROS2 Humble
- Python 3.10+

### Pythonライブラリ
```bash
pip install onnxruntime  # または onnxruntime-gpu
pip install smbus2       # I2C通信（BNO055用）
pip install pyserial     # シリアル通信（モータ用）
pip install inputs       # ゲームパッド入力
```

---

## トラブルシューティング

### ROS2関連
```bash
# ROS2が見つからない
source /opt/ros/humble/setup.bash

# ビルドエラー
cd ~/openduck_ws
colcon build --symlink-install

# ノードが見つからない
source ~/openduck_ws/install/setup.bash
```

### センサ関連
```bash
# I2Cデバイスが見えない
sudo i2cdetect -y 1

# シリアルポートにアクセスできない
sudo usermod -a -G dialout $USER
# ログアウト・再ログインが必要
```

---

## 参考資料

- [ROS2公式ドキュメント](https://docs.ros.org/en/humble/)
- [ONNX Runtime](https://onnxruntime.ai/)
- [Genesis Simulator](https://genesis-world.readthedocs.io/)

---

## ライセンス

MIT License（予定）

---

## 貢献

バグ報告や機能提案は Issue でお願いします。

---

**作成日**: 2025-11-18
**最終更新**: 2025-11-18
