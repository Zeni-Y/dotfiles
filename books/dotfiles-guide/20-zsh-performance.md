---
title: "zsh 起動パフォーマンスの計測と改善"
---

# zsh 起動パフォーマンスの計測と改善

## この章で扱うこと

シェルの起動速度はターミナル作業の快適さに直結します。新しいタブを開くたび、tmux の pane を分割するたびに待たされるのはストレスです。

この章では、zsh の起動パフォーマンスを**定量的に計測**し、ボトルネックを特定して改善する方法を解説します。

## 起動時間の目標

| 指標                | 目標    | 説明                                           |
| ------------------- | ------- | ---------------------------------------------- |
| `first_prompt_lag`  | < 500ms | シェル起動からプロンプト表示まで               |
| `first_command_lag` | < 500ms | 起動から最初のコマンドが実行可能になるまで     |
| `command_lag`       | < 200ms | コマンド実行後、次のプロンプトが表示されるまで |
| `input_lag`         | < 50ms  | キー入力から画面反映まで                       |

## 計測ツール

### zsh-bench

[romkatv/zsh-bench](https://github.com/romkatv/zsh-bench) は、zsh の起動パフォーマンスを包括的に計測するベンチマークツールです。

```bash
# インストールと実行
git clone --depth=1 https://github.com/romkatv/zsh-bench /tmp/zsh-bench
/tmp/zsh-bench/zsh-bench
```

出力例:

```
creates_tty=0
has_compsys=1
has_syntax_highlighting=0
has_autosuggestions=0
has_git_prompt=1
first_prompt_lag_ms=174.000
first_command_lag_ms=190.000
command_lag_ms=45.000
input_lag_ms=10.000
exit_time_ms=150.000
```

#### 各指標の意味

- **`first_prompt_lag_ms`**: zsh が起動してからプロンプトが表示されるまでの時間。`.zshrc` の同期処理がここに影響する
- **`first_command_lag_ms`**: プロンプト表示後、`zsh-defer` 等で遅延実行されるタスクが完了するまでの時間。この間はキー入力が表示されない場合がある
- **`command_lag_ms`**: コマンド実行後に次のプロンプトが表示されるまでの時間。`precmd` フックや starship の描画時間が影響する
- **`input_lag_ms`**: キーを押してから画面に文字が表示されるまでの時間
- **`has_syntax_highlighting=0`** / **`has_autosuggestions=0`**: `zsh-defer` で遅延読み込みしている場合は `0` になる（正常）

### このリポジトリのベンチマークコマンド

本リポジトリには `zsh-startup-bench` コマンドが付属しています:

```bash
zsh-startup-bench
```

閾値を超えた場合は `FAIL` と表示され、終了コードが `1` になります。閾値は環境変数でカスタマイズ可能です:

```bash
ZSH_BENCH_THRESHOLD_FIRST_PROMPT=300 zsh-startup-bench
```

## ボトルネックの特定方法

### 1. zprof によるプロファイリング

zsh 組み込みのプロファイラで関数ごとの実行時間を計測します。

```bash
# .zshrc の先頭に以下を一時的に追加:
# zmodload zsh/zprof

# .zshrc の末尾に以下を追加:
# zprof

# 実行
zsh -i -c exit
```

### 2. xtrace でタイムスタンプ付きトレース

各行の実行時間をログに記録し、大きな時間差を見つけます。

```bash
zsh -c '
zmodload zsh/datetime
PS4="+$EPOCHREALTIME %N:%i> "
set -x
source ~/.zshrc
' 2>/tmp/zsh-trace.log

# 遅い箇所を抽出（Python）
python3 -c "
import re
lines = open('/tmp/zsh-trace.log').readlines()
prev_ts = None
for i, line in enumerate(lines):
    m = re.match(r'\+(\d+\.\d+)', line)
    if m:
        ts = float(m.group(1))
        if prev_ts and (ts - prev_ts) > 0.01:
            print(f'{(ts-prev_ts)*1000:8.1f}ms  L{i+1}  {line.rstrip()[:100]}')
        prev_ts = ts
"
```

### 3. 各コンポーネントの個別計測

```bash
# sheldon source（生成のみ、eval なし）
time sheldon source > /dev/null

# mise activate
time eval "$(mise activate zsh)"

# starship init
time eval "$(starship init zsh)"
```

### 4. 段階的な無効化

```bash
# 全設定なしで起動（ベースライン）
zsh -f -c exit

# sheldon なしで起動
ZDOTDIR=/tmp zsh -i -c exit
```

## よくあるボトルネックと対策

### sheldon source の eval が遅い

`sheldon source` コマンド自体は高速（~10ms）ですが、生成されたスクリプトの eval に含まれる処理がボトルネックになります。

**対策**: 重い初期化処理を `zsh-defer` で遅延実行に移行する。

### mise activate が遅い

`mise activate zsh` は多数のツールの PATH 設定と hook 関数の登録を行うため、100ms 以上かかることがあります。

**対策**: `zsh-defer` で遅延実行する。起動直後の数十 ms は mise 管理のコマンドが使えなくなるが、実用上は問題ない。

```toml
[plugins.mise]
inline = '''
function _mise() {
    eval "$(~/.local/bin/mise activate zsh)"
}
zsh-defer _mise
'''
```

### compinit が遅い

補完システムの初期化 (`compinit`) は 40-50ms かかります。`.zcompdump` のキャッシュを活用することで 10ms 程度に短縮できます。

```toml
[plugins.compinit]
inline = '''
function _compinit() {
    autoload -Uz compinit
    local zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"
    if [[ -f "$zcompdump" && $(date +'%j') == $(date -r "$zcompdump" +'%j' 2>/dev/null) ]]; then
        compinit -C
    else
        compinit
    fi
}
zsh-defer _compinit
'''
```

### fzf install --bin が毎回走る

sheldon の `fzf-install` テンプレートで毎回 `install --bin` を実行していると ~30ms かかります。fzf のバイナリは chezmoi のインストールスクリプトで管理し、sheldon では PATH 追加のみにします。

### zsh-defer の注意点

`zsh-defer` は ZLE のアイドル時に遅延タスクを実行します。キー入力があればタスク間で中断されますが、**1 つのタスク実行中はブロック**されます。

```
プロンプト表示 → [task1: 10ms] → キーチェック → [task2: 150ms] → キーチェック → ...
                                                  ^^^^^^^^^^^^^^^^
                                                  この間は入力が表示されない
```

そのため、`zsh-defer` に渡す個々のタスクは軽量であることが重要です。重いタスク（100ms 以上）がある場合は `first_command_lag` に影響します。

## CI による自動計測

### GitHub Actions

本リポジトリでは `.github/workflows/zsh-bench.yml` で以下のタイミングでベンチマークを実行します:

- zsh 関連ファイルの push / PR 時
- 毎週月曜日（定期実行）
- 手動実行（workflow_dispatch）

閾値を超えた場合は CI が失敗し、Job Summary にベンチマーク結果のテーブルが表示されます。

### ローカルでの実行

```bash
# ベンチマークコマンドを実行
zsh-startup-bench

# 閾値をカスタマイズ
ZSH_BENCH_THRESHOLD_FIRST_PROMPT=300 zsh-startup-bench
```

## パフォーマンスバジェット

本リポジトリで使用しているプラグインの実測値（参考）:

| 処理                    | 同期/defer | 時間   |
| ----------------------- | ---------- | ------ |
| sheldon source（生成）  | 同期       | ~10ms  |
| starship init           | 同期       | ~17ms  |
| fzf PATH 追加           | 同期       | ~1ms   |
| oh-my-zsh (部分)        | 同期       | ~15ms  |
| compinit -C             | defer      | ~11ms  |
| mise activate           | defer      | ~140ms |
| zsh-syntax-highlighting | defer      | ~30ms  |
| zsh-autosuggestions     | defer      | ~7ms   |

同期処理の合計: ~50ms（目標: 200ms 以内）
defer 処理の最大単一タスク: ~140ms（mise）
