# Docker 開発環境

chezmoi と連携し、コンテナ内でもホストと同じ開発環境を自動構築する Docker 構成。

## 設計方針

- **ベースイメージ**: `ubuntu:24.04`（CUDA イメージ不要。PyTorch は pip 同梱の CUDA ランタイムを使用）
- **dotfiles 展開**: `entrypoint.sh` で `chezmoi init --apply` を実行し、zsh / sheldon / mise / starship 等をすべて自動セットアップ
- **SSH 鍵管理**: age 暗号化された SSH 秘密鍵を chezmoi が復号・展開するため、ホストからの `.ssh` マウント不要
- **age 暗号化**: パスフレーズで保護した age 秘密鍵 (`.key.txt.age`) をリポジトリに含め、初回起動時にパスフレーズ入力で復号
- **chezmoi 管理外**: `docker/` ディレクトリ自体は chezmoi の管理対象外

## ファイル構成

| ファイル | 役割 |
|---------|------|
| `Dockerfile` | ubuntu ベースイメージ + 最小パッケージ + chezmoi インストール |
| `entrypoint.sh` | コンテナ起動時に `chezmoi init --apply` を実行 |
| `build_image.sh` | イメージビルドスクリプト（UID/GID をホストに合わせる） |
| `run_container.sh` | コンテナ起動スクリプト（GPU / 共有メモリ設定込み） |
| `run_simple.sh` | GPU 動作確認用（`nvidia-smi` を実行するだけ） |

## セットアップ手順

### 前提: age 暗号化基盤の準備（初回のみ）

#### 1. age 秘密鍵をパスフレーズで暗号化

```bash
age -p -o ~/dotfiles/home/.key.txt.age ~/.config/age/key.txt
```

パスフレーズを設定すると `.key.txt.age` が生成される。これをリポジトリにコミットする。

#### 2. SSH 鍵を chezmoi に暗号化追加

```bash
chezmoi add --encrypt ~/.ssh/id_ed25519      # 暗号化して追加
chezmoi add ~/.ssh/id_ed25519.pub             # 公開鍵はそのまま
chezmoi add ~/.ssh/config                     # config もそのまま
```

### イメージビルド

```bash
cd docker/
./build_image.sh
```

`$USER_image` という名前のイメージが作成される。`--build-arg` でホストの UID/GID を引き継ぐため、マウントしたファイルの権限問題が起きない。

### コンテナ起動

```bash
./run_container.sh
```

初回起動時の流れ:

1. `entrypoint.sh` が `chezmoi init --apply Zeni-Y` を実行
2. chezmoi が `.key.txt.age` を検出し、age パスフレーズの入力を求める
3. age 秘密鍵が復号され `~/.config/age/key.txt` に配置される
4. chezmoi が暗号化された SSH 鍵やその他 dotfiles をすべて展開
5. mise / sheldon 等のインストールスクリプトが実行される
6. bash シェルが起動

2回目以降は `chezmoi apply` のみ実行され、パスフレーズ入力は不要。

### GPU 動作確認

```bash
./run_simple.sh
```

## 主な変更点（旧構成からの移行）

| 項目 | 旧 | 新 |
|------|-----|-----|
| ベースイメージ | `nvidia/cuda:12.2.0-devel-ubuntu22.04` | `ubuntu:22.04` |
| SSH | openssh-server + ポートフォワード | chezmoi が age 暗号化された鍵を展開 |
| dotfiles | なし（手動設定） | `chezmoi init --apply` で自動展開 |
| ユーザー認証 | パスワード (`chpasswd`) | sudo NOPASSWD（パスワードなし） |
| Python | `python3-pip` | uv（chezmoi/mise 経由でインストール） |
| gosu | 使用 | 削除（sudo で十分） |
| 起動モード | `-itd` (デタッチ) + SSH 接続 | `-it` (対話モード) |
| `.ssh` マウント | ホストからマウント | 不要（chezmoi が展開） |
| ホームマウント | `$HOME` 全体 | `$HOME` → `/home/$USER/host` |
