---
title: "chezmoi 入門"
---

# chezmoi 入門

## chezmoi とは

[chezmoi](https://www.chezmoi.io/) は Go 製の dotfiles マネージャーです。まずは chezmoi がどういう設計思想で dotfiles を管理しているのか、全体像を掴んでおきましょう。

### 設計思想: ソースとターゲットの分離

dotfiles 管理ツールにはいくつかのアプローチがあります。代表的なのが [GNU Stow](https://www.gnu.org/software/stow/) に代表される **symlink（シンボリックリンク）ベース** のアプローチです。

**symlink ベース** とは、dotfiles リポジトリ内のファイルへのシンボリックリンク（ショートカットのようなもの）をホームディレクトリに作成する方式です。`~/.zshrc` がリポジトリ内のファイルを直接指すので、ファイルを編集すると即座に反映されます。シンプルですが、環境ごとに異なる設定を出し分けたり、秘密情報を暗号化したりするのが難しいという課題があります。

chezmoi はこれとは異なり、**コピーベース** のアプローチを取っています。

```
# Stow (symlink ベース): リポジトリのファイルを直接参照
~/.zshrc -> ~/dotfiles/zsh/.zshrc  (同一ファイル)

# chezmoi (コピーベース): ソースから生成してコピー
~/dotfiles/home/dot_zshrc  →(apply)→  ~/.zshrc  (別々のファイル)
```

chezmoi では、リポジトリ内のファイル（**ソース**）と、実際に `~/` 以下に配置されるファイル（**ターゲット**）が完全に独立しています。ソースを編集しても `chezmoi apply` するまで実際の設定は変わりません。この分離があるおかげで:

- **安全に編集・テストができる** — 「設定ファイルをいじったらシェルが壊れた」みたいな事故を防げる
- **テンプレートで環境ごとに出し分けられる** — 同じソースから macOS / Linux で異なる設定を生成できる
- **暗号化が自然に組み込める** — ソースは暗号化されたまま、apply 時に復号してターゲットに配置

### chezmoi が管理するもの

chezmoi は以下のデータを使って dotfiles を管理しています。

| 概念 | 場所 | 説明 |
|------|------|------|
| **ソースディレクトリ** | `~/.local/share/chezmoi` | dotfiles のソースファイル（Git リポジトリ） |
| **ターゲットディレクトリ** | `~/`（ホーム） | 実際に配置される設定ファイル群 |
| **設定ファイル** | `~/.config/chezmoi/chezmoi.yaml` | chezmoi 自体の設定 |
| **テンプレートデータ** | `.chezmoi.yaml.tmpl` から生成 | テンプレート展開に使うカスタム変数（email, system 等） |

`chezmoi apply` を実行すると、ソースディレクトリの内容を読み取り、テンプレートを展開し、ターゲットディレクトリにコピーします。この **「ソース → 変換 → ターゲット」** という一方向のフローが chezmoi の基本です。

### ざっくりライフサイクル

chezmoi の日常的な使い方を先に示しておきます（詳細は後述します）。

```
【初回セットアップ】
chezmoi init --apply <リポジトリURL>
  → clone → 対話プロンプト → ファイル展開 → スクリプト実行

【日常の変更サイクル】
1. edit  — ソースファイルを編集
2. diff  — 変更内容を確認
3. apply — ターゲットに反映
4. git commit & push — リポジトリに保存

【別のマシンで同期】
chezmoi update  → リモートの最新を取得して apply
```

この全体像を頭に入れた上で、以下の具体的なコマンドを見ていきましょう。

## インストール

```bash
# curl でインストール（公式推奨）
sh -c "$(curl -fsLS get.chezmoi.io)"

# mise でインストール（この dotfiles の方式）
mise install chezmoi

# Homebrew
brew install chezmoi
```

:::message
この dotfiles リポジトリでは、chezmoi 以外のツール（mise, sheldon, starship 等）は **`chezmoi apply` 時に自動インストールされる**ように設定しています。個別のインストール手順は各チャプターで紹介していますが、実際には `chezmoi init --apply` を実行するだけで一通り揃います。自動インストールの仕組みについては「chezmoi テンプレートと応用」チャプターの `run_once` スクリプトの節を参照してください。
:::

## 基本コマンド

### init — 初期化

```bash
# GitHub リポジトリから dotfiles を取得して初期化
chezmoi init https://github.com/username/dotfiles.git

# ローカルリポジトリで初期化
chezmoi init

# 既存の設定データを無視して再度プロンプトを表示
chezmoi init --data=false
```

`init` を実行すると、`~/.local/share/chezmoi` にソースディレクトリが作成されます。

`--data=false` を指定すると、既存の設定データ（`chezmoi.yaml` に保存済みの値）を無視して、`.chezmoi.yaml.tmpl` 内の `promptString` 等による対話プロンプトが再度表示されます。メールアドレスやシステム種別などの設定値を変更したい場合に便利です。

### add — ファイルを管理対象に追加

```bash
# ~/.zshrc を管理対象に追加
chezmoi add ~/.zshrc
# → ~/.local/share/chezmoi/dot_zshrc が作成される

# テンプレートとして追加
chezmoi add --template ~/.zshrc
```

### edit — ソースファイルを編集

```bash
# エディタでソースファイルを開く
chezmoi edit ~/.zshrc
```

### diff — 差分を確認

```bash
# ソースと実際のファイルの差分を表示
chezmoi diff
```

`apply` する前に必ず `diff` で変更内容を確認する習慣をつけましょう。テンプレートの展開結果が意図しないものになっていることもあるので、この一手間が大事です。

### apply — 変更を適用

```bash
# ソースの内容を実際のファイルに反映
chezmoi apply

# dry-run（実際には適用しない）
chezmoi apply --dry-run
```

### cd — ソースディレクトリに移動

```bash
# ソースディレクトリに移動
chezmoi cd
# → ~/.local/share/chezmoi に移動
```

### re-add — ターゲット側の変更を取り込む

```bash
# ~/.zshrc を直接編集した後、変更を source に反映
chezmoi re-add ~/.zshrc
```

既に管理対象のファイルについて、ターゲット側（`~/` 以下の実ファイル）の変更を chezmoi の source に書き戻します。暗号化対象のファイルなら自動で再暗号化されます。

通常のワークフローでは source 側を編集して `apply` しますが、「先にターゲット側を変更してしまった」ときに `re-add` で source に反映できます。

### data — テンプレートデータの確認

chezmoi のテンプレートは、展開時に**テンプレートデータ**と呼ばれる変数群を参照します。テンプレートデータには2種類あります:

- **ビルトイン変数** — chezmoi が自動的に提供する変数（OS 名、ホスト名、ユーザー名など）。`.chezmoi.os` のように `.chezmoi.` で始まる
- **カスタムデータ** — ユーザーが `.chezmoi.yaml.tmpl` で定義する変数（メールアドレス、環境の種別など）。`.email`, `.system` のように参照する

```bash
# 利用可能なテンプレート変数を表示
chezmoi data
```

テンプレートが思ったように展開されないときに、まずこのコマンドで変数の値を確認するのがおすすめです。

## ディレクトリ構造

chezmoi のソースディレクトリは通常 `~/.local/share/chezmoi` です。

### .chezmoiroot

このリポジトリでは `.chezmoiroot` ファイルで**ソースルートを `home/` に設定**しています。

```
# .chezmoiroot の内容
home
```

これにより、リポジトリ直下に `install/` や `books/` などのディレクトリを置いても chezmoi に認識されません。chezmoi が管理するファイルは `home/` 以下のみです。

```
dotfiles/               # リポジトリルート
├── .chezmoiroot         # ソースルートを home/ に設定
├── CLAUDE.md            # プロジェクトドキュメント
├── README.md
├── install/             # インストールスクリプト（chezmoi 管理外）
│   ├── common/
│   └── ubuntu/
└── home/                # ← chezmoi のソースルート
    ├── .chezmoi.yaml.tmpl
    ├── .chezmoiscripts/
    ├── dot_zshrc
    ├── dot_gitconfig
    └── dot_config/
```

リポジトリ直下と chezmoi の管理領域をきれいに分離できるので、この構成はなかなか便利です。

## Naming Convention

chezmoi はファイル名の**プレフィックス**と**サフィックス**で管理方法を制御します。最初は「なんだこの名前...」と戸惑いますが、慣れるとファイル名を見ただけで動作が分かるようになります。

### プレフィックス

| プレフィックス | 意味 | 例 |
|--------------|------|-----|
| `dot_` | `.` に変換 | `dot_zshrc` → `~/.zshrc` |
| `private_` | パーミッション制限（ディレクトリ: `0700`、ファイル: `0600`） | `private_dot_ssh/` → `~/.ssh/` |
| `executable_` | 実行権限付き | `executable_script.sh` → `script.sh` (chmod +x) |
| `symlink_` | シンボリックリンク | `symlink_link` → シンボリックリンクとして配置 |
| `empty_` | 空ファイルを作成 | `empty_dot_file` → 空の `.file` |

プレフィックスは**組み合わせ可能**です:

```
private_dot_ssh/             → ~/.ssh/ (パーミッション制限付き)
private_executable_dot_script → ~/.script (private + executable)
```

### サフィックス

| サフィックス | 意味 |
|------------|------|
| `.tmpl` | Go template として処理される |

```
dot_zshrc.tmpl → テンプレート処理後に ~/.zshrc として配置
```

### 実際のファイル対応表

このリポジトリの実際の対応を見てみましょう。

| ソースファイル | 配置先 |
|--------------|--------|
| `home/dot_zshrc` | `~/.zshrc` |
| `home/dot_gitconfig` | `~/.gitconfig` |
| `home/dot_config/sheldon/plugins.toml` | `~/.config/sheldon/plugins.toml` |
| `home/dot_config/mise/config.toml` | `~/.config/mise/config.toml` |
| `home/dot_config/zsh-abbr/user-abbreviations` | `~/.config/zsh-abbr/user-abbreviations` |
| `home/.chezmoi.yaml.tmpl` | `~/.config/chezmoi/chezmoi.yaml` |

:::message
`dot_config/` はディレクトリにも `dot_` プレフィックスが適用されます。`dot_config/sheldon/` は `~/.config/sheldon/` になります。
:::

## 基本的なワークフロー

dotfiles の変更は `edit → diff → apply → commit` のサイクルで行います。

```
1. edit  — ソースファイルを編集
      ↓ ソースが変更された状態
2. diff  — 変更内容を確認（テンプレート展開後の結果を表示）
      ↓ 意図通りか確認できた
3. apply — 変更を実際のファイルに反映
      ↓ ~/.zshrc 等が更新された
4. commit — ソースディレクトリで git commit & push
```

### chezmoi edit を使う方法

```bash
# 1. ソースファイルを編集（エディタが開く）
chezmoi edit ~/.zshrc

# 2. テンプレート展開後の差分を確認
chezmoi diff

# 3. 問題なければ適用
chezmoi apply

# 4. ソースディレクトリに移動してコミット
chezmoi cd
git add -A
git commit -m "feat: update zshrc"
git push
```

### 直接ソースディレクトリで編集する方法

```bash
# 1. ソースディレクトリに移動して直接編集
chezmoi cd
vim dot_zshrc

# 2. 差分確認 → 適用
chezmoi diff
chezmoi apply

# 3. そのままコミット（既にソースディレクトリにいる）
git add -A
git commit -m "feat: update zshrc"
git push
```

筆者は後者のスタイルで、ソースディレクトリで直接編集してから `chezmoi apply` するパターンが多いです。

## ライフサイクル

### 初期セットアップ（初回のみ）

```bash
# GitHub リポジトリから dotfiles を取得して初期化・適用
chezmoi init --apply https://github.com/username/dotfiles.git
```

このコマンド1つで、リポジトリの clone → 対話プロンプト（メール・system 等） → ファイル展開 → スクリプト実行まで全自動で行われます。

### 日常の操作

| やりたいこと | コマンド |
|------------|---------|
| 設定ファイルを編集する | `chezmoi edit ~/.zshrc` または `chezmoi cd` して直接編集 |
| 変更内容を確認する | `chezmoi diff` |
| 変更を適用する | `chezmoi apply` |
| テンプレート変数を確認する | `chezmoi data` |
| リモートの最新を取得・適用する | `chezmoi update` |

### 新しいファイルを管理対象に追加したいとき

```bash
# 通常のファイル
chezmoi add ~/.config/starship.toml

# テンプレートとして追加（OS 分岐等が必要な場合）
chezmoi add --template ~/.config/sheldon/plugins.toml

# 暗号化して追加（秘密鍵等）
chezmoi add --encrypt ~/.ssh/id_ed25519
```

追加後は `chezmoi cd` でソースディレクトリに移動し、`git add` → `git commit` → `git push` でリポジトリに反映します。
