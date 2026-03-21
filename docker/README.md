# Docker 開発環境

chezmoi と連携し、コンテナ内でもホストと同じ開発環境を自動構築する Docker 構成。

## 設計方針

- **ベースイメージ**: `ubuntu:24.04`（CUDA イメージ不要。PyTorch は pip 同梱の CUDA ランタイムを使用）
- **dotfiles 展開**: `entrypoint.sh` で `chezmoi init --apply` を実行し、fish / fisher / mise / starship 等をすべて自動セットアップ
- **SSH 鍵管理**: SSH agent forwarding を利用。秘密鍵・公開鍵はコンテナに配置しない
- **chezmoi 管理外**: `docker/` ディレクトリ自体は chezmoi の管理対象外

## ファイル構成

| ファイル           | 役割                                                          |
| ------------------ | ------------------------------------------------------------- |
| `Dockerfile`       | ubuntu ベースイメージ + 最小パッケージ + chezmoi インストール |
| `entrypoint.sh`    | コンテナ起動時に `chezmoi init --apply` を実行                |
| `build_image.sh`   | イメージビルドスクリプト（UID/GID をホストに合わせる）        |
| `run_container.sh` | コンテナ起動スクリプト（GPU / 共有メモリ設定込み）            |
| `run_simple.sh`    | GPU 動作確認用（`nvidia-smi` を実行するだけ）                 |

## セットアップ手順

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
2. chezmoi が dotfiles をすべて展開
3. mise / fish 等のインストールスクリプトが実行される
4. bash シェルが起動

2 回目以降は `chezmoi apply` のみ実行される。

### GPU 動作確認

```bash
./run_simple.sh
```

## 主な変更点（旧構成からの移行）

| 項目            | 旧                                     | 新                                    |
| --------------- | -------------------------------------- | ------------------------------------- |
| ベースイメージ  | `nvidia/cuda:12.2.0-devel-ubuntu22.04` | `ubuntu:22.04`                        |
| SSH             | openssh-server + ポートフォワード      | SSH agent forwarding                  |
| dotfiles        | なし（手動設定）                       | `chezmoi init --apply` で自動展開     |
| ユーザー認証    | パスワード (`chpasswd`)                | sudo NOPASSWD（パスワードなし）       |
| Python          | `python3-pip`                          | uv（chezmoi/mise 経由でインストール） |
| gosu            | 使用                                   | 削除（sudo で十分）                   |
| 起動モード      | `-itd` (デタッチ) + SSH 接続           | `-it` (対話モード)                    |
| `.ssh` マウント | ホストからマウント                     | 不要（SSH agent forwarding）          |
| ホームマウント  | `$HOME` 全体                           | `$HOME` → `/home/$USER/host`          |
