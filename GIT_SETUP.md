# Git セットアップ手順

今日の作業を保存するために、Gitの設定とコミットを行います。

## ステップ1: Gitユーザー情報を設定

```bash
# あなたの名前とメールアドレスを設定
git config --global user.name "あなたの名前"
git config --global user.email "your.email@example.com"

# 例：
# git config --global user.name "Hayato"
# git config --global user.email "hayato@example.com"
```

## ステップ2: duckディレクトリの処理

duckディレクトリが別のgitリポジトリになっているので、修正が必要です。

### オプションA: duckを通常のディレクトリとして扱う（推奨）
```bash
cd ~/OpenDuck
rm -rf duck/.git
git add .
```

### オプションB: duckをサブモジュールとして扱う
```bash
cd ~/OpenDuck
git rm --cached duck
# 後でサブモジュールとして追加する場合に使用
```

## ステップ3: 今日の作業をコミット

```bash
cd ~/OpenDuck
git add .
git commit -m "Initial OpenDuck setup and ROS2 message definitions

- Added project design documents
- Created ROS2 workspace structure
- Defined custom messages (Observation, Action, MotorState, etc.)
- Built openduck_msgs package successfully
- Added BNO055 sensor test code
"
```

## ステップ4: 確認

```bash
# コミット履歴を確認
git log

# 現在の状態を確認
git status
```

---

## 簡易版（すぐにコミットしたい場合）

```bash
cd ~/OpenDuck

# ユーザー情報設定
git config --global user.name "Hayato"
git config --global user.email "hayato@example.com"

# duckの.gitを削除
rm -rf duck/.git

# すべて追加してコミット
git add .
git commit -m "Day 1: ROS2 setup and message definitions"
```

---

これで今日の作業が保存されます！
