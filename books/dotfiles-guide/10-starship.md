---
title: "starship — クロスシェル対応のモダンプロンプト"
---

# starship — クロスシェル対応のモダンプロンプト

## この章で扱うこと

シェルのプロンプトは、ターミナルで最も目にする UI です。Git ブランチ、言語バージョン、実行時間など、開発に必要な情報をプロンプトに表示できると作業効率が上がります。

この章では、プロンプトツールの選定理由と設定方法を解説します。

| 課題                                     | 解決するツール | アプローチ                                                     |
| ---------------------------------------- | -------------- | -------------------------------------------------------------- |
| プロンプトに開発情報を表示したい         | **starship**   | TOML で宣言的に設定。80 以上のモジュールが文脈に応じて自動表示 |
| シェルを変えても同じプロンプトを使いたい | **starship**   | Bash, Zsh, Fish, PowerShell, Nushell 等 10 種のシェルに対応    |

## starship とは

[starship](https://starship.rs/) は **Rust 製のクロスシェル対応プロンプト**です。Git の状態、プログラミング言語のバージョン、クラウド環境の情報などを、必要なときだけプロンプトに表示してくれます。

### starship の特徴

| 特徴               | 説明                                                                          |
| ------------------ | ----------------------------------------------------------------------------- |
| **クロスシェル**   | Bash, Fish, Zsh, PowerShell, Nushell 等 10 種のシェルで同じ設定が使える       |
| **高速**           | Rust 製バイナリで、プロンプト表示のオーバーヘッドが小さい                     |
| **文脈対応**       | カレントディレクトリの内容に応じてモジュールが自動で表示/非表示になる         |
| **TOML 設定**      | `~/.config/starship.toml` 1 ファイルで宣言的に設定。dotfiles 管理と相性が良い |
| **80+ モジュール** | Git, Python, Node.js, Rust, Go, Docker, AWS, Kubernetes 等を標準サポート      |

## powerlevel10k との比較

zsh のプロンプトといえば [powerlevel10k](https://github.com/romkatv/powerlevel10k)（以下 p10k）も有名です。筆者も以前は p10k を使っていましたが、現在は starship に移行しています。

### なぜ starship を選んだか

最大の理由は **p10k のメンテナンス状況**です。p10k の README には以下の記載があります[^1]:

> THE PROJECT HAS VERY LIMITED SUPPORT. NO NEW FEATURES ARE IN THE WORKS. MOST BUGS WILL GO UNFIXED. HELP REQUESTS WILL BE IGNORED.

開発が事実上停止しており、新機能の追加もバグ修正もほぼ行われない状態です。プロンプトはシェルの起動時に毎回実行される重要なコンポーネントなので、メンテナンスが継続しているツールを選びたいところです。

一方、starship は 2025 年現在も活発に開発が続いており、GitHub スター数は 50,000 以上です[^2]。

### 機能比較

| 比較項目         | starship                                | powerlevel10k                                  |
| ---------------- | --------------------------------------- | ---------------------------------------------- |
| 開発状況         | 活発に開発中                            | メンテナンス限定（事実上停止）                 |
| 対応シェル       | 10 種（Bash, Fish, Zsh, PowerShell 等） | **Zsh のみ**                                   |
| 実装言語         | Rust                                    | Zsh スクリプト                                 |
| 設定方式         | TOML ファイルを直接編集                 | ウィザード（`p10k configure`）で生成           |
| 設定ファイル     | `starship.toml`（数十行〜）             | `~/.p10k.zsh`（1,000 行超の生成ファイル）      |
| Instant Prompt   | なし（Rust バイナリで十分速い）         | あり（プラグイン読み込み前にプロンプトを表示） |
| Transient Prompt | なし                                    | あり（過去のプロンプトを折りたたむ）           |

### dotfiles 管理の観点から

dotfiles をバージョン管理する上で、starship の TOML 設定は大きなメリットです。

- **差分が読みやすい**: TOML なので `git diff` で何が変わったか一目瞭然
- **設定が短い**: 必要なモジュールだけ記述すれば良い（デフォルト設定が優秀）
- **chezmoi との相性**: テンプレート（`.tmpl`）にする必要がなく、そのまま管理できる

p10k の設定ファイルはウィザードが生成する 1,000 行超のファイルです。動作はしますが、何がどこに設定されているか把握するのは大変ですし、差分レビューもしにくいです。

## このリポジトリでの starship 設定

### config.fish.tmpl での初期化

starship の初期化は `config.fish.tmpl` で行っています。バージョンごとにキャッシュを生成することで、シェル起動のたびに初期化スクリプトを再生成するコストを省いています。

```fish
# config.fish.tmpl
if type -q starship
    set -l _ver (starship --version 2>/dev/null | string split ' ')[2]
    set -l _cache $_cache_dir/starship_init_$_ver.fish
    if not test -f $_cache
        mkdir -p $_cache_dir
        starship init fish >$_cache
    end
    source $_cache
end
```

:::message
starship の初期化スクリプトはバージョンが変わらない限り変化しないため、バージョン番号をキャッシュファイル名に含めて再利用しています。バージョンアップ時は新しいキャッシュが自動生成されます。
:::

### starship.toml の設定

設定ファイルは `~/.config/starship.toml` です。このリポジトリでは最小限のカスタマイズだけ行っています。

```toml
right_format = """
${custom.chezmoi}
"""

[python]
python_binary = 'python'

[git_branch]
only_attached = true
```

starship のデフォルト設定は十分に実用的なので、カスタマイズは少なくて済みます。ここでは以下の 3 点だけ変更しています:

| 設定                       | 内容                                          |
| -------------------------- | --------------------------------------------- |
| `right_format`             | 右プロンプトに chezmoi 更新通知を表示（後述） |
| `python_binary`            | Python バージョン検出に `python` を使用       |
| `git_branch.only_attached` | detached HEAD 状態では Git ブランチを非表示   |

### chezmoi 更新通知との連携

starship の [カスタムコマンドモジュール](https://starship.rs/config/#custom-commands) を使って、dotfiles リポジトリに未適用の更新がある場合にプロンプト右側に通知を表示しています。

```toml
[custom.chezmoi]
command = "cat ${XDG_CACHE_HOME:-$HOME/.cache}/starship-chezmoi/count"
when = "test -s ${XDG_CACHE_HOME:-$HOME/.cache}/starship-chezmoi/count"
symbol = " dotfiles  ⇣"
style = "bold red"
format = "[$symbol$output]($style) "
ignore_timeout = true
```

未適用の更新が 3 件ある場合、プロンプトの右側に `dotfiles ⇣3` のように表示されます。

**`ignore_timeout = true`**: starship のカスタムコマンドにはデフォルトで 500ms のタイムアウトがあります。bash など fish 以外のシェルではシェル起動オーバーヘッドにより `when` の判定がタイムアウトし、警告が表示されることがあります。`ignore_timeout = true` を設定すると、コマンドがタイムアウトしても警告を出さずプロンプトを即座に表示し、完了次第結果を反映します。

通知の仕組み自体（バックグラウンドでの `git fetch` とキャッシュ管理）は [fish と fisher プラグイン管理](09-fish-and-fisher) の chezmoi-notify セクションで解説しています。

## p10k から starship への移行

p10k から starship に移行する場合、手順は 3 ステップです[^3]。

### Step 1: starship のインストール

```bash
# macOS (Homebrew)
brew install starship

# Linux (curl)
curl -sS https://starship.rs/install.sh | sh

# mise でインストール（このリポジトリの方式）
mise use -g starship
```

### Step 2: シェル設定の変更

`config.fish.tmpl` から p10k 関連の設定を削除し、starship の初期化に置き換えます。

```fish
# 削除するもの
# source ~/powerlevel10k/powerlevel10k.zsh-theme

# 追加するもの（config.fish.tmpl）
if type -q starship
    set -l _ver (starship --version 2>/dev/null | string split ' ')[2]
    set -l _cache $_cache_dir/starship_init_$_ver.fish
    if not test -f $_cache
        mkdir -p $_cache_dir
        starship init fish >$_cache
    end
    source $_cache
end
```

### Step 3: starship.toml の作成

`~/.config/starship.toml` を作成して、好みに合わせてカスタマイズします。何も書かなくてもデフォルトで十分使えるので、まずは空ファイルから始めて、気になったモジュールだけ調整するのがおすすめです。

```bash
mkdir -p ~/.config && touch ~/.config/starship.toml
```

[プリセット](https://starship.rs/presets/) も用意されているので、見た目を手早く変えたい場合は試してみてください。

## 参考文献

[^1]: [romkatv/powerlevel10k — GitHub README](https://github.com/romkatv/powerlevel10k) — メンテナンス状況に関する記載
[^2]: [starship/starship — GitHub](https://github.com/starship/starship) — starship 公式リポジトリ
[^3]: [Powerlevel10k から Starship へ — scribble.washo3.com](https://scribble.washo3.com/powerlevel2starship/) — 移行手順の参考記事
