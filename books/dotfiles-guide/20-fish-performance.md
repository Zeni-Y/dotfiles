---
title: "fish 起動パフォーマンスの計測と改善"
---

# fish 起動パフォーマンスの計測と改善

## この章で扱うこと

シェルの起動速度はターミナル作業の快適さに直結します。新しいタブを開くたび、tmux の pane を分割するたびに待たされるのはストレスです。

この章では、fish の起動パフォーマンスを**定量的に計測**し、ボトルネックを特定して改善する方法を解説します。具体的には、`config.fish` で使っているキャッシュパターンの仕組みと、CI で自動計測する仕組みを紹介します。

## 起動時間の目標

このリポジトリでは、CI の閾値に合わせて以下を目標にしています。

| 指標         | 目標    | 説明                                         |
| ------------ | ------- | -------------------------------------------- |
| 平均起動時間 | < 300ms | `--profile-startup` による 10 回計測の平均値 |

300ms という数値は、新しいターミナルタブを開いたときに「一瞬待つ」と感じない目安です。500ms を超えると体感できる遅さになります。

## 計測ツール

### fish 組み込みの `--profile-startup`

fish には起動プロファイリング機能が組み込まれています。外部ツールは不要です。

```fish
# プロファイル結果を /tmp/fish-profile.txt に出力して起動
fish --profile-startup /tmp/fish-profile.txt -c exit
```

出力はタブ区切りの以下のフォーマットになります:

```
Time    Sum     Command
45      45      source /home/user/.config/fish/config.fish
12      57      starship init fish
...
```

| カラム    | 意味                                             |
| --------- | ------------------------------------------------ |
| `Time`    | そのコマンド単体の実行時間（マイクロ秒）         |
| `Sum`     | 起動開始からの累積時間（マイクロ秒）             |
| `Command` | 実行されたコマンドまたは `source` されたファイル |

`Sum` カラムの最大値が起動完了までのトータル時間です。CI ではこの値を使ってベンチマークを行います。

### ボトルネックの特定

プロファイル結果から遅い箇所を見つけるには、`Time` カラムの降順でソートするのが効率的です。

```fish
# 上位 20 件を遅い順に表示
fish --profile-startup /tmp/fish-profile.txt -c exit
tail -n +2 /tmp/fish-profile.txt | sort -t'\t' -k1 -rn | head -20
```

`Time` が大きい行が単体で重い処理です。一方、`Sum` が急増している行の直前の処理がボトルネックです。

### このリポジトリの `fish-time` コマンド

本リポジトリには起動時間を手軽に確認する `fish-time` コマンドが付属しています。実体は `config.fish` に定義された abbr で、プロファイルを取得して合計時間をミリ秒で表示します。

```fish
fish-time
# => Startup time: 142ms
```

## キャッシュによる起動高速化

fish 起動の最適化において核心となる戦略が**コマンド出力のキャッシュ**です。`config.fish` 内で `starship init fish` や `fzf --fish` のような「初期化スクリプトを生成するコマンド」を毎回実行すると、それぞれ数十〜百数十 ms のコストがかかります。

このリポジトリでは、これらの出力を `~/.cache/fish/` にキャッシュし、**2 回目以降の起動では `source` するだけ**にしています。

### キャッシュディレクトリの設定

`config.fish` の冒頭でキャッシュディレクトリを変数に入れておきます:

```fish
# コマンド出力キャッシュ用ディレクトリ
set -l _cache_dir ~/.cache/fish
```

以降の各コンポーネントがこの変数を参照します。

### starship init のキャッシュ

`starship init fish` は starship がフック関数をシェルに登録するためのスクリプトを出力します。このスクリプトはバージョンが変わらない限り同じ内容です。バージョン番号をキャッシュファイル名に含めることで、**バージョンアップ時だけ自動再生成**される仕組みにしています。

```fish
# starship プロンプト（キャッシュ）
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

キャッシュファイルのパスは `~/.cache/fish/starship_init_1.22.1.fish` のような形になります。starship をアップグレードすると `_ver` が変わるため、古いキャッシュは自動的に使われなくなり、新しいキャッシュが生成されます。

### fzf init のキャッシュ

`fzf --fish` は fzf のキーバインドや補完を fish 向けに設定するスクリプトを出力します。starship と同じパターンでキャッシュします。

```fish
# fzf（キャッシュ）
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

`go env GOROOT` は Go のインストールディレクトリを返すコマンドです。毎回実行すると Go のランタイムが起動するため無視できないコストがかかります。こちらはバージョンに関係なく単純なテキストファイルとしてキャッシュします。

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

Go をバージョンアップしたときは `GOROOT` が変わる場合があるため、`~/.cache/fish/goroot` を手動で削除すれば次回起動時に再生成されます。

:::message
`go env GOROOT` の結果は mise shims モードを使っている場合、shim 経由での実行になります。shim のオーバーヘッドがあるためキャッシュの効果が特に大きくなります。
:::

### mise shims モード: activate vs shims の選択

mise には 2 つの統合方式があり、起動時間への影響が大きく異なります。

```fish
# activate 方式（起動時に ~135ms のオーバーヘッド）
$HOME/.local/bin/mise activate fish | source

# shims モード（起動時に ~1ms）
fish_add_path $HOME/.local/share/mise/shims
```

このリポジトリでは **shims モードを採用**しています。`activate` 方式は `chpwd` フック（ディレクトリ移動時に呼ばれる関数）の登録と PATH の動的解決を起動時に行うため、~135ms のコストがかかります。shims モードでは `~/.local/share/mise/shims/` への PATH 追加だけなので、このコストがほぼゼロになります。

```fish
# mise ランタイムバージョン管理（shims モード）
# activate 方式の代わりに shims PATH を追加することで起動を高速化
# トレードオフ: cd 時の自動バージョン切替なし（mise reshim が必要）
if test -x $HOME/.local/bin/mise
    fish_add_path $HOME/.local/share/mise/shims
end
```

:::message alert
**shims モードのトレードオフ**

shims モードでは `cd` 時にバージョンが自動で切り替わりません。プロジェクトごとに異なるバージョンを使い分けている場合は、以下の点に注意してください。

- **新しいツールをインストールした後**: `mise reshim` を実行して shim を再生成する必要があります
- **`GOROOT` 等の環境変数**: `mise hook-env` が走らないため、手動でキャッシュする必要があります（上述の GOROOT キャッシュはこの対応です）

筆者の環境では、複数バージョンを頻繁に切り替えるケースが少ないため shims モードを採用しています。プロジェクトごとにバージョンを厳密に管理したい場合は activate 方式の方が安全です。
:::

## 落とし穴: mise が fish 自体を管理する場合

mise は非常に便利なツールですが、**fish 自体を mise で管理する**と、shims モードを使っていても起動が大幅に遅くなる落とし穴があります。

### 何が起きるか

mise の shim バイナリは、管理対象のツール（ここでは fish）を起動するとき、`-C`（`--init-command`）フラグを使って mise 環境をシェルに注入します。

```
# shim が実際に実行するコマンド（概略）
fish -C "set -gx GOROOT ...
fish_add_path -gm ~/.local/share/mise/installs/go/1.26.0/bin
fish_add_path -gm ~/.local/share/mise/installs/node/24.14.0/bin
fish_add_path -gm ~/.local/share/mise/installs/starship/1.24.2
...（管理ツール数 × 1 行）"
```

mise が管理するツールの数だけ `fish_add_path` が呼ばれます。`fish_add_path` は内部で `__fish_reconstruct_path` を呼び出し PATH 変数を再構築するため、呼び出しのたびにコストがかかります。ツールが 29 個なら **O(n²) の PATH 操作が 29 回**発生します。

```
# 計測結果（ツール 29 個の場合）
mise shim 経由の fish 起動: ~500ms
直接バイナリの fish 起動:   ~50ms
差分: ~450ms
```

### 計測の落とし穴

この問題は「fish の中から `time fish -c exit` で計測する」と顕在化しますが、見落としやすい罠があります。

```fish
# fish シェル内で実行すると「fish」は shim に解決される
time fish -c exit  # → ~500ms（shim 経由）

# bash から直接バイナリを指定すると本来の速度
bash -c 'time /usr/bin/fish -c exit'  # → ~50ms
```

**ターミナルの実際の起動は直接バイナリ経由のため速い**のですが、ツールやスクリプトが `fish -c` を呼ぶたびに 500ms のオーバーヘッドが発生し続けます。

また、プロセスリストを見ると shim が何をしているかが一目瞭然です。

```bash
ps aux | grep fish
# → fish -C "set -gx CARGO_HOME ... fish_add_path -gm .../go/bin
#           fish_add_path -gm .../node/bin fish_add_path -gm ... (×29)"
```

### 解決策: fish はシステムパッケージで管理する

mise の強みは「複数バージョンの切り替え」にありますが、fish はシェル自体なので複数バージョンを使い分けることはほぼありません。システムパッケージで管理するのが適切です。

```bash
# Ubuntu: PPA から最新版をインストール
sudo apt-add-repository -y ppa:fish-shell/release-4
sudo apt-get update && sudo apt-get install -y fish

# mise の管理対象から外す（mise/config.toml）
# "github:fish-shell/fish-shell" = "latest"  ← この行を削除
```

```fish
# ログインシェルを /usr/bin/fish に変更
sudo chsh -s /usr/bin/fish $USER
```

これにより、fish 起動時に shim の `-C` 注入が一切なくなります。

### 影響を受けるケース

| 状況                                      | shim 経由か            | 影響                        |
| ----------------------------------------- | ---------------------- | --------------------------- |
| ターミナルを開く（fish がログインシェル） | 直接バイナリ           | なし                        |
| fish 内で `fish -c` を呼ぶ                | shim 経由              | **~450ms のオーバーヘッド** |
| bash スクリプトから `fish -c` を呼ぶ      | shim 経由（PATH 次第） | **~450ms のオーバーヘッド** |
| `chezmoi apply` 内での fisher 実行        | shim 経由              | **~450ms のオーバーヘッド** |

`fish -c` を呼ぶ頻度が低ければ実害は少ないですが、fish をシステムパッケージで管理する方がシンプルで根本的な解決策です。

## ボトルネックの特定方法

### profile-startup の出力をソートして分析

実際のプロファイリングの手順です:

```fish
# 1. プロファイルを取得
fish --profile-startup /tmp/fish-profile.txt -c exit

# 2. ヘッダーを除いて Time 降順でソート（上位 15 件）
tail -n +2 /tmp/fish-profile.txt | sort -t'\t' -k1 -rn | head -15

# 3. 起動完了までのトータル時間を確認（Sum の最大値）
tail -n +2 /tmp/fish-profile.txt | awk -F'\t' 'BEGIN{max=0} {if($2+0>max) max=$2+0} END{print max/1000 "ms"}'
```

### キャッシュの有無を確認する

キャッシュが効いているかを確認するには、キャッシュを一度削除してから計測します:

```fish
# キャッシュを全削除して起動時間を計測（キャッシュなし）
rm -rf ~/.cache/fish
fish --profile-startup /tmp/fish-profile-cold.txt -c exit
tail -n +2 /tmp/fish-profile-cold.txt | awk -F'\t' 'BEGIN{max=0} {if($2+0>max) max=$2+0} END{print "cold: " max/1000 "ms"}'

# キャッシュあり（2回目以降）
fish --profile-startup /tmp/fish-profile-warm.txt -c exit
tail -n +2 /tmp/fish-profile-warm.txt | awk -F'\t' 'BEGIN{max=0} {if($2+0>max) max=$2+0} END{print "warm: " max/1000 "ms"}'
```

### 段階的な無効化

特定のコンポーネントが原因かを調べるには、一時的に無効化して比較します:

```fish
# config.fish を読み込まずに起動（最小ベースライン）
fish --no-config -c exit

# 特定の行をコメントアウトして計測
# config.fish の該当箇所を一時的にコメントアウト → fish --profile-startup で差分を確認
```

## CI による自動計測

### GitHub Actions の設定

本リポジトリでは `.github/workflows/fish-bench.yml` で以下のタイミングでベンチマークを実行します:

- `home/dot_config/fish/**` または `home/dot_config/starship.toml` への push / PR 時
- 毎週月曜 9:00 JST（定期実行）
- 手動実行（workflow_dispatch）

ベンチマークのコアとなる計測ロジックは以下の通りです:

```yaml
- name: Run fish startup benchmark (10 runs)
  run: |
    tmpfile=$(mktemp)
    total=0

    for i in $(seq 1 10); do
      # --profile-startup でプロファイル取得し、合計時間を算出
      fish --profile-startup "$tmpfile" -c exit
      # Sum 列の最大値 = 起動完了までの合計時間 (マイクロ秒)
      elapsed_us=$(tail -n +2 "$tmpfile" | awk -F'\t' 'BEGIN{max=0} {if($2+0>max) max=$2+0} END{print max}')
      elapsed_ms=$((elapsed_us / 1000))
      echo "Run $i: ${elapsed_ms}ms"
      total=$((total + elapsed_ms))
    done

    avg=$((total / 10))
    echo "Average startup time: ${avg}ms"
    echo "avg_ms=$avg" >> "$GITHUB_ENV"
```

10 回計測して平均を取ることで、CI 環境の一時的なノイズを平滑化しています。

### 閾値チェックと Job Summary

```yaml
- name: Check threshold
  run: |
    threshold=300
    echo "## Fish Startup Benchmark" >> "$GITHUB_STEP_SUMMARY"
    echo "| Metric | Value | Threshold |" >> "$GITHUB_STEP_SUMMARY"
    echo "|--------|-------|-----------|" >> "$GITHUB_STEP_SUMMARY"
    echo "| Average startup | ${avg_ms}ms | ${threshold}ms |" >> "$GITHUB_STEP_SUMMARY"

    if [ "$avg_ms" -gt "$threshold" ]; then
      echo "::warning::Average startup time ${avg_ms}ms exceeds threshold ${threshold}ms"
      exit 1
    fi
```

閾値（300ms）を超えた場合は CI が失敗し、Job Summary にベンチマーク結果のテーブルが表示されます。`config.fish` を変更したときに性能劣化を自動検知できます。

## パフォーマンスバジェット

各処理の実測値（参考）です。CI 環境（ubuntu-latest）と手元の環境では差がありますが、傾向は同じです。

| 処理                        | 方式               | キャッシュなし | キャッシュあり |
| --------------------------- | ------------------ | -------------- | -------------- |
| starship init fish          | 同期（キャッシュ） | ~120ms         | ~5ms           |
| fzf --fish                  | 同期（キャッシュ） | ~30ms          | ~2ms           |
| go env GOROOT               | 同期（キャッシュ） | ~80ms          | ~1ms           |
| mise activate fish          | 同期（activate）   | ~135ms         | —              |
| fish_add_path (mise shims)  | 同期（shims）      | ~1ms           | ~1ms           |
| fisher ブートストラップ確認 | 同期               | ~2ms           | ~2ms           |
| .workrc.fish の source      | 同期               | ファイルに依存 | ファイルに依存 |

**キャッシュ活用時の同期処理合計: ~15ms 程度**（目標 300ms に対して大幅に余裕あり）

:::message
CI 環境では mise のインストールに時間がかかるため、`mise install` は `|| true` で失敗を無視しています。CI の計測はキャッシュが温まった状態（2 回目以降）での値になります。
:::

## まとめ

fish の起動パフォーマンス改善のポイントをまとめます:

| 戦略                       | 効果           | 実装箇所                             |
| -------------------------- | -------------- | ------------------------------------ |
| starship init のキャッシュ | ~115ms 削減    | `config.fish` の starship セクション |
| fzf init のキャッシュ      | ~28ms 削減     | `config.fish` の fzf セクション      |
| GOROOT のキャッシュ        | ~79ms 削減     | `config.fish` の Go セクション       |
| mise shims モード          | ~134ms 削減    | `config.fish` の mise セクション     |
| CI での自動計測            | 性能劣化を検知 | `.github/workflows/fish-bench.yml`   |

fish は zsh と違い、遅延読み込み（`zsh-defer` 相当）の仕組みがありません。すべての初期化処理が同期的に実行されるため、**1 回あたりのコストを下げる**アプローチが基本戦略になります。キャッシュパターンはそのための有効な手段です。
