---
title: "fish と fisher プラグイン管理"
---

# fish と fisher プラグイン管理

## この章で扱うこと

fish shell は**シンタックスハイライト・オートサジェスチョン・Tab 補完**を標準搭載しています。zsh では大量のプラグインで実現していた機能の大半が、fish では組み込みで動作します。

この章では、fish の組み込み機能と最小限のプラグインを組み合わせて、**高速かつメンテナンスコストの低いシェル環境**を構築する方法を解説します。

| 課題                               | 解決策                             | アプローチ                                      |
| ---------------------------------- | ---------------------------------- | ----------------------------------------------- |
| プラグインを増やすと起動が遅くなる | **fish の組み込み機能を活用**      | ハイライト・補完・サジェスチョンが標準搭載      |
| プラグイン管理が煩雑               | **fisher + fish_plugins ファイル** | テキストファイル 1 枚で宣言的に管理             |
| 起動のたびに外部コマンドが走る     | **バージョンキャッシュ戦略**       | starship/fzf の init 結果をキャッシュして再利用 |

## fish shell とは

[fish (Friendly Interactive SHell)](https://fishshell.com/) は、ユーザーフレンドリーさを設計の中心に置いたシェルです。

### 主な組み込み機能

| 機能                   | bash/zsh              | fish                               |
| ---------------------- | --------------------- | ---------------------------------- |
| シンタックスハイライト | プラグインが必要      | 標準搭載                           |
| オートサジェスチョン   | プラグインが必要      | 標準搭載                           |
| Tab 補完               | compinit の設定が必要 | 標準搭載（man ページから自動生成） |
| Web ベースの設定 UI    | なし                  | `fish_config` コマンドで起動       |
| エラーメッセージ       | 簡素                  | 詳細で分かりやすい                 |
| abbreviation           | プラグインが必要      | 標準搭載（`abbr` コマンド）        |

### POSIX 非互換のトレードオフ

fish は POSIX 非互換です。`#!/usr/bin/env fish` で書いたスクリプトは他のシェルでは動きません。また、bash スクリプトをそのまま `source` することもできません。

このリポジトリでは、インストールスクリプトは `bash` で書き（`#!/usr/bin/env bash`）、対話的な設定だけ fish で管理するという役割分担で対処しています。

## fisher とは

[fisher](https://github.com/jorgebucaran/fisher) は fish のプラグインマネージャです。

### プラグインマネージャの比較

| ツール                                               | 対象シェル | 設定形式                        | 特徴                                              |
| ---------------------------------------------------- | ---------- | ------------------------------- | ------------------------------------------------- |
| [oh-my-zsh](https://ohmyz.sh/)                       | zsh        | `.zshrc` に直接記述             | 機能豊富だが重い                                  |
| [sheldon](https://sheldon.cli.rs/)                   | zsh        | TOML ファイル                   | Rust 製で高速。設定と実行を分離                   |
| **[fisher](https://github.com/jorgebucaran/fisher)** | fish       | `fish_plugins` テキストファイル | シンプル。fish 組み込み機能で代替できる機能が多い |

fisher を選ぶ理由:

- **シンプル**: プラグインリストは `fish_plugins` の 1 ファイルで管理
- **fish と統合**: fish の関数・補完・conf.d メカニズムをそのまま利用
- **必要なプラグインが少ない**: fish の組み込み機能で大半をカバーできるため、プラグイン数を最小に保てる

## fish_plugins ファイル

fisher が管理するプラグインは `~/.config/fish/fish_plugins` に宣言します。

```
jorgebucaran/fisher
jorgebucaran/autopair.fish
meaningful-ooo/sponge
PatrickF1/fzf.fish
```

| プラグイン                   | 役割                                                                |
| ---------------------------- | ------------------------------------------------------------------- |
| `jorgebucaran/fisher`        | fisher 自体を fish_plugins で管理（自己管理）                       |
| `jorgebucaran/autopair.fish` | `(` を入力すると `)` を自動挿入。括弧・クォートの対応を補完         |
| `meaningful-ooo/sponge`      | 終了コードが 0 以外のコマンドを履歴に記録しない                     |
| `PatrickF1/fzf.fish`         | fzf を fish に統合。`Ctrl+R`（履歴）や `Ctrl+F`（ファイル）が使える |

## zsh プラグイン → fish の対応表

zsh で必要だったプラグインの多くは、fish では不要になります。

| zsh でのプラグイン             | fish での対応                      |
| ------------------------------ | ---------------------------------- |
| `zsh-syntax-highlighting`      | 組み込み（追加設定不要）           |
| `zsh-autosuggestions`          | 組み込み（追加設定不要）           |
| `compinit` / `zsh-completions` | 組み込み（man ページから自動生成） |
| `zsh-abbr`                     | 組み込み `abbr` コマンド           |
| `zsh-autopair`                 | `jorgebucaran/autopair.fish`       |
| `zsh-history-on-success`       | `meaningful-ooo/sponge`            |
| oh-my-zsh の fzf プラグイン    | `PatrickF1/fzf.fish`               |
| `zsh-defer`（遅延読み込み）    | 不要（fish の起動が元々速い）      |

fish はプラグイン 4 つで環境が整います。zsh の構成に比べて大幅に管理するものが減ります。

## config.fish.tmpl の構成

メイン設定ファイル `~/.config/fish/config.fish`（chezmoi では `config.fish.tmpl`）は、以下の順序で処理されます。

```
fish 起動
  │
  ├─ 1. PATH の設定（fish_add_path）
  │       /usr/local/bin, ~/.local/bin, system 別パス
  │
  ├─ 2. 環境変数（set -gx）
  │       LANG, GPG_TTY, CLAUDE_CONFIG_DIR 等
  │       server の場合: CUDA_HOME, HF_HOME 等
  │
  ├─ 3. starship プロンプト初期化（キャッシュ経由）
  │
  ├─ 4. mise shims の PATH 追加（activate の代わり）
  │
  ├─ 5. fzf 初期化（キャッシュ経由）
  │
  ├─ 6. 言語環境（Go / Rust / Bun の PATH と環境変数）
  │
  ├─ 7. エイリアス定義（abbr / alias）
  │
  ├─ 8. SSH keychain（server のみ）
  │
  └─ 9. プライベート設定（~/.workrc.fish）
```

## パフォーマンスキャッシュ戦略

`starship init fish` や `fzf --fish` は毎回実行すると数十ミリ秒かかります。`config.fish.tmpl` では、**バージョン番号をキャッシュキーとして結果をファイルに保存**し、バージョンが変わった時だけ再生成するパターンを採用しています。

### starship のキャッシュ

```fish
#
# starship プロンプト（キャッシュ）
#
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

`starship --version` の出力からバージョン文字列を取り出し、`~/.cache/fish/starship_init_<version>.fish` にキャッシュします。ファイルが存在すれば `starship init fish` を実行せず、キャッシュを直接 `source` します。starship をアップデートするとバージョンが変わり、自動的に再生成されます。

### fzf のキャッシュ

```fish
#
# fzf（キャッシュ）
#
if type -q fzf
    set -l _ver (fzf --version 2>/dev/null | string split ' ')[1]
    set -l _cache $_cache_dir/fzf_init_$_ver.fish
    if not test -f $_cache
        mkdir -p $_cache_dir
        fzf --fish >$_cache
    end
    source $_cache
    set -gx FZF_DEFAULT_OPTS "--reverse"
end
```

### GOROOT のキャッシュ

`go env GOROOT` はサブプロセスを呼ぶため毎回実行するとコストがかかります。結果をテキストファイルに保存し、次回以降は `cat` で読み込みます。

```fish
# Go（GOROOT をキャッシュ。Go バージョン変更時は ~/.cache/fish/goroot を削除）
if type -q go
    set -gx GOPATH "$HOME/ghq"
    set -l _cache $_cache_dir/goroot
    if not test -f $_cache
        mkdir -p $_cache_dir
        go env GOROOT >$_cache
    end
    set -gx GOROOT (cat $_cache)
    fish_add_path $GOPATH/bin
    fish_add_path $HOME/.go/bin
end
```

Go のバージョンを mise で切り替えた後は `rm ~/.cache/fish/goroot` で手動削除するか、`fish -c 'rm -f ~/.cache/fish/goroot'` を実行すれば次回起動時に再生成されます。

### mise の shims モード

mise は `mise activate fish` で有効化すると `cd` のたびにバージョンを切り替えるフックが走りますが、起動コストがかかります。このリポジトリでは代わりに **shims モード**（shims ディレクトリを PATH に追加するだけ）を採用しています。

```fish
#
# mise ランタイムバージョン管理（shims モード）
# activate 方式の代わりに shims PATH を追加することで起動を高速化
# トレードオフ: cd 時の自動バージョン切替なし（mise reshim が必要）
#
if test -x $HOME/.local/bin/mise
    fish_add_path $HOME/.local/share/mise/shims
end
```

トレードオフとして、ディレクトリ移動時の自動バージョン切り替えが動作しません。バージョンを追加した後は `mise reshim` の実行が必要です。

## abbr と alias の使い分け

fish には `abbr`（abbreviation）と `alias` の 2 種類のコマンド短縮機能があります。

### abbr — 展開表示される短縮形

`abbr` はスペースを押した瞬間にフルコマンドへ展開されます。コマンドラインに展開後のテキストが表示されるため、何が実行されるかが一目で分かります。履歴にもフルコマンドが残ります。

```fish
abbr -a cz chezmoi
abbr -a gm 'git checkout (git symbolic-ref refs/remotes/origin/HEAD | sed "s@^refs/remotes/origin/@@")'
```

- `cz` と入力してスペースを押すと → `chezmoi` に展開される
- `gm` と入力してスペースを押すと → `git checkout (git symbolic-ref ...)` に展開される

:::message
`gm` は `git symbolic-ref` でリモートのデフォルトブランチ（main や master）を自動判定してチェックアウトします。リポジトリごとにデフォルトブランチが異なる場合でも対応できます。
:::

### alias — 展開しない長いオプション列

`alias` は展開せずにそのまま実行します。展開後のコマンドが長くなる場合（`eza` のオプション列など）に向いています。

```fish
alias ls "eza --long --group --header --binary --time-style=long-iso --icons"
alias ll "eza -la --long --group --header --binary --time-style=long-iso --icons"
```

`ls` を入力してもコマンドラインには `ls` のまま表示されます。展開後が長いため、画面上に展開されると読みにくくなるケースで使用します。

### 使い分けの基準

| 状況                             | 使うべきもの              |
| -------------------------------- | ------------------------- |
| 展開後が短く、内容を確認したい   | `abbr`                    |
| 展開後が長く、画面が見づらくなる | `alias`                   |
| 引数を加工・転送したい           | `alias` または `function` |

## conf.d/ 自動読み込み

fish は `~/.config/fish/conf.d/` に置いた `.fish` ファイルを起動時に自動読み込みします。`config.fish` に書かなくても、ファイルをディレクトリに置くだけで有効になります。

このリポジトリでは `conf.d/` に `chezmoi-notify.fish` を配置しています。`chezmoi apply` 時に chezmoi がファイルを `~/.config/fish/conf.d/` に配置するため、手動での設定は不要です。

## functions/ ディレクトリ

fish は `~/.config/fish/functions/` に置いた `.fish` ファイルを**オートロード**します。関数名と同名のファイルを置くだけで、呼び出された時に自動で読み込まれます。

このリポジトリでは **1 関数 1 ファイル**の規約で管理しています。

| ファイル                          | 機能                                                        |
| --------------------------------- | ----------------------------------------------------------- |
| `dev.fish`                        | ghq + fzf でリポジトリに移動し、tmux セッション名をリネーム |
| `cdgwq.fish`                      | gwq worktree を fzf で選択して移動                          |
| `cdw.fish`                        | 最新の gwq worktree に移動                                  |
| `chezmoi-cd.fish`                 | chezmoi ソースディレクトリに移動                            |
| `fgc.fish`                        | fzf で git ブランチをインタラクティブにチェックアウト       |
| `git-delete-merged-branches.fish` | squash-merge 済みブランチを検出・削除                       |
| `uv-format.fish`                  | ruff でフォーマット + リントを実行                          |

### dev.fish の例

`dev` 関数は ghq で管理しているリポジトリを fzf でインタラクティブに選択し、移動します。tmux セッション内では、移動先のリポジトリ名にセッション名をリネームします。日常的なリポジトリ間の移動を効率化するために最もよく使うカスタム関数です。

## chezmoi-notify — dotfiles 更新通知

### 概要

`chezmoi-notify.fish` は、dotfiles リポジトリのリモートに未適用の更新がないかをバックグラウンドで定期チェックし、starship プロンプトに通知を表示するカスタム関数です。

### 仕組み

```
[fish_prompt イベント] → 1時間経過? → [バックグラウンドで git fetch（disown）]
                                       → 差分あり → キャッシュファイルに件数を書き込み
                                       → 差分なし → キャッシュファイルを削除

[starship] → キャッシュファイルを読み取り → プロンプト右側に表示
```

### コード

```fish
function _check_chezmoi_update --on-event fish_prompt
    set -l check_interval 3600
    set -l cache_dir (set -q XDG_CACHE_HOME; and echo $XDG_CACHE_HOME; or echo $HOME/.cache)/starship-chezmoi
    set -l status_file $cache_dir/count
    set -l last_check_file $cache_dir/last_check

    test -d $cache_dir; or mkdir -p $cache_dir

    set -l current_time (date +%s)
    set -l last_check 0
    if test -f $last_check_file
        set last_check (cat $last_check_file)
    end

    if test (math "$current_time - $last_check") -gt $check_interval
        echo $current_time >$last_check_file

        # バックグラウンドで実行
        fish -c "
            if type -q chezmoi
                chezmoi git -- fetch -q
                set -l count (chezmoi git -- rev-list --count HEAD..origin/main 2>/dev/null)
                if test \"\$count\" -gt 0
                    echo \$count > $status_file
                else
                    rm -f $status_file
                end
            end
        " &
        disown
    end
end
```

### fish での実装ポイント

**`--on-event fish_prompt`**: fish のイベントシステムを使い、プロンプトが表示されるたびに関数を呼び出します。zsh での `add-zsh-hook precmd` に相当します。

**`disown`**: バックグラウンドジョブを fish のジョブ管理から切り離します。fish セッションを終了してもバックグラウンドプロセスが継続し、終了時にジョブ完了の通知が出なくなります。

`&|` ではなく `& disown` を使っているのは、`fish -c "..."` を一つのジョブとして起動した後で切り離すためです。直接 `& disown` を書くことでフォークボムのリスクも回避しています。

### starship との連携

未適用の更新がある場合、starship のカスタムコマンドモジュールがキャッシュファイルを読み取り、プロンプトに `dotfiles ⇣3` のように表示します。starship の設定詳細については [starship — クロスシェル対応のモダンプロンプト](10-starship) を参照してください。

## fish -c フォークボムに注意

fish の設定ファイル（`config.fish`, `conf.d/`, `functions/`）やインストールスクリプトから **`fish -c "..."`** でサブシェルを起動してはいけません。`fish -c` は通常の fish 起動と同様に `config.fish` を読み込むため、config.fish の中から `fish -c` を呼ぶとプロセスが無限増殖する**フォークボム**を引き起こします。

### 再帰のメカニズム

```
fish 起動
  → config.fish を読み込む
    → fish -c "fisher update" を実行
      → 新しい fish プロセスが起動
        → config.fish を読み込む
          → fish -c "fisher update" を実行
            → ... (無限ループ)
```

`starship init fish` や `fzf --fish` などの**外部コマンド呼び出しは安全**です。これらは fish のサブシェルではなく独立したバイナリの実行なので、config.fish の再読み込みは発生しません。危険なのは `fish -c` で**新しい fish シェルを起動する**パターンだけです。

### 安全な代替手段

| やりたいこと          | NG                             | OK                                         |
| --------------------- | ------------------------------ | ------------------------------------------ |
| 外部コマンド実行      | `fish -c "command ..."`        | `command <cmd>`                            |
| バックグラウンド処理  | `fish -c "..." &`              | `command sh -c '...' &`                    |
| fisher セットアップ等 | `fish -c 'curl ... \| source'` | `fish --no-config -c 'source fisher.fish'` |

`fish --no-config` は config.fish を一切読み込まずに fish を起動するオプションです。config.fish を経由しないため再帰が発生せず、安全に fish のビルトイン機能（`source` 等）を使えます。ただし PATH 等の環境変数も設定されないため、必要なコマンドにはフルパスを使うか、事前に PATH を通しておく必要があります。

:::message alert
**このリポジトリの実例**

当初、`install/common/fish.sh` で `fish -c 'curl ... | source; fisher update'` としていたところフォークボムが発生しました。fisher.fish を curl でファイルとして先にダウンロードし、`fish --no-config -c 'source fisher.fish; fisher update'` とすることで解決しています。

同様に、`config.fish` 内の keychain 呼び出しでも `fish -c "keychain ..."` としていた箇所を `command keychain ... &` に修正しています。
:::

## SSH keychain（サーバー）

サーバー環境では SSH agent の管理に [keychain](https://github.com/funtoo/keychain) を使います。keychain は起動済みの SSH agent を検出して再利用するため、tmux の pane を開くたびにパスフレーズを求められる問題を回避できます。

```fish
{{ if eq .system "server" -}}
#
# SSH Agent (サーバー)
#
set -l _keychain_env "$HOME/.keychain/$hostname-fish"
if test -f $_keychain_env
    source $_keychain_env
end
# バックグラウンドで agent の生存確認と必要なら再起動
command keychain --quiet --nolock --quick --agents ssh ~/.ssh/id_ed25519 &>/dev/null &
disown
{{ end -}}
```

`command keychain ...` のあとに `& disown` を付けることで、keychain の起動チェックをバックグラウンドに切り出しています。これにより fish セッションの起動をブロックしません。

`command` プレフィックスを付けているのは、同名の fish 関数や abbr があった場合にバイパスして、必ず外部コマンドの `keychain` を呼ぶためです。

:::message
`disown` なしで `fish -c "keychain ..."` のように呼ぶと、fish がサブシェルを spawn し、そのサブシェルがさらに fish を起動するフォークボムになる危険があります。シェルスクリプト内から fish を呼ぶ場合は注意が必要です。
:::

## プライベート設定

Git 管理外の個人設定は `~/.workrc.fish` に記述します。

```fish
#
# プライベート設定
#
if test -f $HOME/.workrc.fish
    source $HOME/.workrc.fish
end
```

`~/.workrc.fish` は `.chezmoiignore` に記載されており、リポジトリには含まれません。会社固有のプロキシ設定や個人トークンなど、公開したくない設定をここに書きます。詳しくはセキュリティと暗号化のチャプターで解説します。

## ライフサイクル

### 初期セットアップ

`chezmoi apply` を実行すると、`install/common/fish.sh` が fisher のセットアップを行います。処理は 2 段階に分かれています。

```bash
function install_fisher() {
    mkdir -p "${FUNCTIONS_DIR}"
    curl -sL "${FISHER_URL}" -o "${FUNCTIONS_DIR}/fisher.fish"
}

function setup_plugins() {
    if [ -f "${HOME}/.config/fish/fish_plugins" ]; then
        fish --no-config -c '
            source ~/.config/fish/functions/fisher.fish
            fisher update
        '
    fi
}
```

1. **bash で fisher.fish をダウンロード** — curl でファイルとして保存するだけなので fish は不要
2. **`fish --no-config` でプラグインを復元** — ダウンロード済みの fisher.fish を `source` してから `fisher update`

`--no-config` を使うのは、config.fish を読み込まないことでフォークボムを防ぐためです（詳しくは前述の「fish -c フォークボムに注意」を参照）。

### 日常の操作

| やりたいこと                            | コマンド                                                       |
| --------------------------------------- | -------------------------------------------------------------- |
| プラグインを追加する                    | `fish_plugins` に追記して `fisher update`                      |
| プラグインをすべて更新する              | `fisher update`                                                |
| fish の起動時間を確認する               | `fish-time`（このリポジトリのカスタムコマンド）                |
| starship キャッシュを再生成する         | `rm ~/.cache/fish/starship_init_*.fish` して新しいシェルを開く |
| Go バージョン切り替え後に GOROOT を更新 | `rm ~/.cache/fish/goroot` して新しいシェルを開く               |
| abbr を追加する                         | `config.fish.tmpl` に追記して `chezmoi apply`                  |
| fish function を追加する                | `functions/` に `<関数名>.fish` を作成して `chezmoi add`       |
