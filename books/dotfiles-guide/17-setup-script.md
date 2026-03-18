---
title: "install.sh によるワンコマンドセットアップ"
---

# install.sh によるワンコマンドセットアップ

chezmoi には**リポジトリルートに `install.sh` があれば自動実行する**という仕組みがあります[^1]。

```bash
# install.sh なら chezmoi が自動検出・実行する
chezmoi init Zeni-Y
```

そのため、単にchezmoi initやapplyではカバーできない処理を挟みたい場合には、install.shに処理を記載することで通常通りワンライナーでセットアップが行えます。

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply Zeni-Y
```

chezmoi がバイナリをダウンロードし、リポジトリを clone し、`install.sh` を見つけて自動実行してくれます。

## 他のリポジトリではどう使われているか

install.sh（や setup.sh）が必要になる理由はリポジトリによって異なります。まずは shunk031/dotfiles[^3] と twpayne/dotfiles[^2] でどう使われているかを見てみます。

### shunk031 の setup.sh — private dotfiles の管理

shunk031 の setup.sh で最も重要な役割は、**private dotfiles リポジトリの取得と適用**です[^5]。

```bash
# shunk031/dotfiles の setup.sh から抜粋
PRIVATE_DOTFILES_REPO_URL="https://github.com/shunk031/dotfiles-private"
PRIVATE_DOTFILES_PATH="${HOME}/.local/share/chezmoi-private"
PRIVATE_DOTFILES_CONFIG_PATH="${HOME}/.config/chezmoi-private/chezmoi.yaml"

# public dotfiles の init & apply（通常の chezmoi init --apply に相当）
"${chezmoi_cmd}" init "${DOTFILES_REPO_URL}" --force ...
"${chezmoi_cmd}" apply

# ここが setup.sh の核心 — private dotfiles を別ソースとして init & apply
"${chezmoi_cmd}" init --apply --ssh \
    --source "${PRIVATE_DOTFILES_PATH}" \
    --config "${PRIVATE_DOTFILES_CONFIG_PATH}" \
    "${PRIVATE_DOTFILES_REPO_URL}"
```

chezmoi は `--source` と `--config` を指定することで**複数のソースディレクトリを管理**できます。shunk031 はこの仕組みを使い、public リポジトリと private リポジトリを分離しています。

この「2つのリポジトリを順に init → apply する」というフローは `chezmoi init --apply <user>` のワンライナーではできません。**setup.sh が存在する最大の理由**がここにあります。

それ以外にも、CI/非TTY 環境への対応、macOS/Linux 両対応の sudo keepalive、ブートストラップ用バイナリの後始末なども setup.sh が担当しています。

### twpayne の install.sh — 最小のブートストラップ

一方、chezmoi 作者 twpayne の install.sh はわずか 23 行です。

```bash
#!/bin/sh
set -e

if [ ! "$(command -v chezmoi)" ]; then
  bin_dir="$HOME/.local/bin"
  chezmoi="$bin_dir/chezmoi"
  if [ "$(command -v curl)" ]; then
    sh -c "$(curl -fsSL https://git.io/chezmoi)" -- -b "$bin_dir"
  elif [ "$(command -v wget)" ]; then
    sh -c "$(wget -qO- https://git.io/chezmoi)" -- -b "$bin_dir"
  else
    echo "To install chezmoi, you must have curl or wget installed." >&2
    exit 1
  fi
else
  chezmoi=chezmoi
fi

script_dir="$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P)"
exec "$chezmoi" init --apply "--source=$script_dir"
```

やっていることは3つだけです。

1. **chezmoi が未インストールなら curl/wget でダウンロード**
2. **スクリプト自身のディレクトリを取得**
3. **`exec chezmoi init --apply --source=<dir>` を実行**

`exec` で現在のプロセスを chezmoi に置き換えるので、この install.sh は chezmoi の起動ランチャーに徹しています。

CI 対応も sudo keepalive も暗号化ファイルの除外もありません。これは twpayne が**秘密管理に 1Password CLI を使っている**ため、age のようなパスフレーズ入力の問題がそもそも発生しないからです。それ以外の環境固有の処理はすべて `.chezmoiscripts/` に委ねています。

注目すべきは `--source=$script_dir` です。これにより2つの経路をサポートしています。

| 経路 | 動作 |
|------|------|
| `chezmoi init twpayne` | chezmoi がリポジトリを clone → `install.sh` を自動検出・実行 → `--source` で clone 先を指定 |
| `git clone` → `./install.sh` | 手動で clone したディレクトリをそのまま `--source` に指定 |

どちらの経路でも同じ install.sh で動作するシンプルな設計です。

## 当リポジトリの install.sh

当リポジトリでは shunk031 のアプローチをベースに、Ubuntu 単一環境向けにシンプル化しています。

### chezmoi init --apply だけではカバーできないこと

当リポジトリの場合、install.sh が必要な理由は以下の3つです。

**1. CI/非TTY 環境への対応**

age 暗号化を使っている場合、パスフレーズの入力に **TTY** が必要です。

:::message
**TTY（TeleTYpewriter）とは？**
ユーザーがキーボードから入力し画面に出力する、対話的な端末インターフェースのことです。ターミナルを開いてコマンドを直接実行する場合は TTY があります。一方、CI 環境（GitHub Actions 等）では人間がキーボードの前にいないため TTY がありません。また `curl ... | bash` のようなパイプ経由の実行でも、標準入力がパイプに繋がるため TTY がない状態になります。
:::

CI 環境やパイプ経由の実行では TTY が利用できないため、暗号化ファイルの復号でパスフレーズを聞かれた時点で止まってしまいます。

ワンライナーでも `--no-tty` を渡すことはできますが、暗号化ファイルの除外までは `chezmoi init --apply` のオプションだけでは対処しきれません。shunk031/dotfiles[^3] では `encrypted_*` ファイルを事前に削除するアプローチを取っています。

**2. sudo セッションのタイムアウト**

`chezmoi apply` 中に `.chezmoiscripts` が `apt-get` 等の sudo を使うコマンドを実行します。インストールが長時間になると sudo のセッションがタイムアウトして、途中で再度パスワードを求められることがあります。

install.sh なら、バックグラウンドで sudo のタイムスタンプを更新し続ける処理（sudo keepalive）を入れられます。

**3. ブートストラップ用バイナリの後始末**

ワンライナーは chezmoi バイナリを `~/.local/bin/chezmoi` にダウンロードして実行します。一方、`chezmoi apply` の中で mise がインストールされ、mise 経由でも chezmoi がインストールされます。結果として**同じツールが2箇所に存在する**状態になります。

```
~/.local/bin/chezmoi              ← ワンライナーでダウンロードしたもの
~/.local/share/mise/.../chezmoi   ← mise が管理するもの
```

install.sh なら、apply 完了後にブートストラップ用バイナリを削除するステップを入れられます。

### 設計思想

install.sh が担う役割は「`chezmoi init --apply` の前後を補完すること」です。

- **前処理**: CI/TTY 判定、sudo keepalive の起動
- **本処理**: `chezmoi init` → 暗号化ファイルの除外 → `chezmoi apply`
- **後処理**: ブートストラップ用 chezmoi バイナリの削除

chezmoi 自体はあくまでブートストラップ専用としてダウンロードし、永続的な管理は mise に任せるという方式です。

:::message
**shunk031/dotfiles との差分**
shunk031 の setup.sh をベースにしていますが、以下の機能は当リポジトリでは不要なため省いています。
- private dotfiles の管理（別リポジトリからの init）— 当リポジトリでは age encryption で単一リポジトリに統合
- macOS 対応（Homebrew 初期化、macOS 向け sudo keepalive）
- シェルの再起動（shunk031 でも無効化されている）
:::

## install/ スクリプトと mise の使い分け

ツールのインストールには「`install/` にシェルスクリプトを書く」方法と「mise の `config.toml` に追加する」方法があります。どちらを使うかの判断基準を整理しておきます。

### mise で管理するもの

以下に当てはまるツールは mise に任せます。

- **mise がバックエンドとして対応している**（`mise registry` で確認できる）
- **バージョンの切り替え・アップデートを一元管理したい**
- **OS 固有のインストール手順が不要**（バイナリを取得するだけで動く）

例: go, node, rust, python, eza, jq, starship, shfmt, gh, claude-code など

### install/ スクリプトで管理するもの

以下のいずれかに当てはまるツールは `install/` にスクリプトを書きます。

- **mise 自体のインストール**（mise より先に存在する必要がある）
- **mise が対応していない**（sheldon など）
- **OS 固有のインストール手順がある**（apt-get, brew, systemd 設定などが必要）
- **テスト（bats）で install/uninstall のサイクルを検証したい**[^5]

例: mise 本体, sheldon, apt/brew パッケージ, Docker, SSH サーバー設定など

### 判断フローチャート

```
そのツールは mise が対応している？
  ├─ No → install/ スクリプト
  └─ Yes
       OS 固有の手順が必要？
         ├─ Yes → install/ スクリプト
         └─ No → mise で管理
```

:::message
shunk031/dotfiles[^3] では starship を `install/ubuntu/server/` で管理していますが、mise が starship に対応している現在は mise 管理の方がシンプルです。当リポジトリでは `config.toml` に `starship = "latest"` を追加する方式を採用しています。
:::

## セットアップのフロー

```
Step 1: sudo keepalive を起動（TTY がある場合のみ）
         ↓ sudo のタイムアウトを防止
Step 2: chezmoi バイナリをダウンロード
         ↓ ~/.local/bin/chezmoi が得られる
Step 3: chezmoi init（リポジトリを clone）
         ↓ ~/.local/share/chezmoi にソースが展開される
         ↓ CI/非TTY なら encrypted_* を除外
Step 4: chezmoi apply（dotfiles を適用）
         ↓ mise, sheldon, starship 等がインストールされる
         ↓ mise 経由で chezmoi もインストールされる
Step 5: ブートストラップ用 chezmoi を削除
         ↓ 以降は mise 管理の chezmoi を使用
```

## install.sh の中身

### シェルオプション

```bash
set -Eeuo pipefail
```

| オプション | 効果 |
|-----------|------|
| `-E` | `ERR` トラップをサブシェルや関数にも伝播させる |
| `-e` | コマンドが失敗したら即座にスクリプトを終了する |
| `-u` | 未定義の変数を参照したらエラーにする |
| `-o pipefail` | パイプラインの途中のコマンドが失敗しても検知する |

### ユーティリティ関数

```bash
function is_ci() {
    [ "${CI:-}" = "true" ]
}

function is_tty() {
    [ -t 0 ]
}

function is_ci_or_not_tty() {
    is_ci || ! is_tty
}
```

`is_ci` は GitHub Actions 等が自動で設定する `CI=true` を検出します。`is_tty` は `[ -t 0 ]` で標準入力（ファイルディスクリプタ 0）が端末に繋がっているかを判定します。

`is_ci_or_not_tty` はこの2つをまとめて「対話入力ができない環境」を検出するための関数です。この判定は install.sh 内の複数箇所で使われます。

### keepalive_sudo — sudo セッションの維持

```bash
function keepalive_sudo() {
    echo "Checking for \`sudo\` access which may request your password."
    sudo -v

    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" || exit
    done 2>/dev/null &
}
```

`chezmoi apply` 中に `.chezmoiscripts` が `apt-get` 等を実行するため、sudo セッションが必要です。

最初に `sudo -v` でパスワードを入力させ、その後バックグラウンドで 60 秒ごとに `sudo -n true` を実行して sudo のタイムスタンプを更新し続けます。`kill -0 "$$"` で親プロセス（install.sh 自体）が生きているか確認し、終了していたらバックグラウンドプロセスも終了します。

CI 環境ではパスワードなし sudo が使えるため、`initialize_dotfiles` 関数内で `is_ci_or_not_tty` が true の場合はスキップされます。

### run_chezmoi — メインのセットアップ処理

```bash
function run_chezmoi() {
    local bin_dir="${HOME}/.local/bin"

    # chezmoi バイナリをダウンロード
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "${bin_dir}"
    local chezmoi_cmd="${bin_dir}/chezmoi"

    # CI/非TTY 環境では --no-tty を付与
    local no_tty_option=""
    if is_ci_or_not_tty; then
        no_tty_option="--no-tty"
    fi

    # chezmoi init
    "${chezmoi_cmd}" init "${DOTFILES_REPO_URL}" \
        --force \
        --branch "${BRANCH_NAME}" \
        --use-builtin-git true \
        ${no_tty_option}

    # CI/非TTY 環境では暗号化ファイルを除外
    if is_ci_or_not_tty; then
        find "$("${chezmoi_cmd}" source-path)" \
            -type f -name "encrypted_*" -exec rm -fv {} +
    fi

    # chezmoi apply
    "${chezmoi_cmd}" apply ${no_tty_option}

    # ブートストラップ用 chezmoi を削除
    rm -fv "${chezmoi_cmd}"
}
```

処理の各ステップを順に見ていきます。

**1. chezmoi のダウンロード**

chezmoi 公式のインストーラスクリプト[^4]で `~/.local/bin` にバイナリをダウンロードします。以降はフルパス（`${chezmoi_cmd}`）で直接呼び出すため、PATH に追加する必要はありません。

**2. chezmoi init**

dotfiles リポジトリを clone し、設定ファイル（`.chezmoi.yaml`）を生成します。

| オプション | 効果 |
|-----------|------|
| `--force` | 既存の設定があっても上書きする |
| `--branch` | clone するブランチを指定 |
| `--use-builtin-git true` | システムに git がなくても chezmoi 内蔵の git で clone できる |
| `--no-tty` | 対話プロンプトを抑制する（CI/非TTY 時のみ） |

**3. 暗号化ファイルの除外**

CI/非TTY 環境では `find` で `encrypted_*` prefix のファイルをソースディレクトリから削除します。これにより、`chezmoi apply` 時に age による復号が走らなくなります。

**4. chezmoi apply**

ソースディレクトリの内容をホームディレクトリに適用します。この中で `.chezmoiscripts` が実行され、mise, sheldon, starship 等がインストールされます。

**5. ブートストラップ用 chezmoi の削除**

`chezmoi apply` が完了すると mise 経由で chezmoi もインストールされているため、ダウンロードしたバイナリは不要になります。`rm -fv` で削除して二重管理を防ぎます。

### initialize_dotfiles — オーケストレーション

```bash
function initialize_dotfiles() {
    if ! is_ci_or_not_tty; then
        keepalive_sudo
    fi
    run_chezmoi
}
```

sudo keepalive と `run_chezmoi` をまとめて実行する関数です。TTY がある場合（対話的な端末で実行している場合）のみ `keepalive_sudo` を起動します。CI 環境ではパスワードなし sudo が使えるため不要です。

### デバッグモード

```bash
if [ "${DOTFILES_DEBUG:-}" ]; then
    set -x
fi
```

shunk031/dotfiles と同様に、`DOTFILES_DEBUG=1 bash install.sh` で全コマンドのトレースが出力されます。`set -x` は bash の組み込みで、実行される各コマンドを実行前に表示します。セットアップがうまくいかないときの原因調査に便利です。

## 使い方

### 新しいマシンでのセットアップ

```bash
bash -c "$(curl -fsLS https://raw.githubusercontent.com/Zeni-Y/dotfiles/main/install.sh)"
```

実行後、新しいシェルを起動すれば設定が反映されます。

### CI 環境でのセットアップ

GitHub Actions では `CI=true` がデフォルトで設定されているので、暗号化ファイルの除外と sudo keepalive のスキップが自動的に行われます。

```yaml
- name: Setup dotfiles
  run: bash install.sh
```

### デバッグ

セットアップが失敗する場合は、デバッグモードで実行して原因を調査できます。

```bash
DOTFILES_DEBUG=1 bash install.sh
```

## ライフサイクル

### 初期セットアップ（初回のみ）

| やること | コマンド |
|---------|---------|
| dotfiles を展開 | `bash -c "$(curl -fsLS https://raw.githubusercontent.com/Zeni-Y/dotfiles/main/install.sh)"` |
| age 秘密鍵の復号 | セットアップ中に自動でプロンプトが表示される |

### 日常の操作

初期セットアップ後は `install.sh` を使う必要はありません。mise 管理の chezmoi を直接使います。

| やりたいこと | コマンド |
|------------|---------|
| dotfiles の変更を適用 | `chezmoi apply` |
| 差分を確認 | `chezmoi diff` |
| ファイルを管理対象に追加 | `chezmoi add <file>` |

### 再セットアップ

マシンを初期化した場合は、再度 `install.sh` を実行するだけです。

## 参考文献

[^1]: [chezmoi ドキュメント — Use a custom install script](https://www.chezmoi.io/user-guide/machines/general/)
[^2]: [twpayne/dotfiles — install.sh](https://github.com/twpayne/dotfiles/blob/master/install.sh)
[^3]: [shunk031/dotfiles — setup.sh](https://github.com/shunk031/dotfiles/blob/master/setup.sh)
[^4]: [chezmoi — Install: one-line binary install](https://www.chezmoi.io/install/)
[^5]: [テスト可能な dotfiles 管理：chezmoi による開発環境構築 — shunk031](https://zenn.dev/shunk031/articles/testable-dotfiles-management-with-chezmoi)
