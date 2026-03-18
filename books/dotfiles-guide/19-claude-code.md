---
title: "Claude Code の設定管理"
---

# Claude Code の設定管理

[Claude Code](https://docs.anthropic.com/en/docs/claude-code) は Anthropic が提供する CLI ベースの AI コーディングアシスタントです。ターミナル上で対話しながら、ファイルの読み書き・コマンド実行・Git 操作など幅広いタスクをこなしてくれます。

Claude Code の設定は `~/.claude/` ディレクトリに保存されます。dotfiles と同じように chezmoi で管理すれば、新しいマシンでも一瞬で自分好みの Claude Code 環境を再現できます。

## 設定ディレクトリの構成

Claude Code の設定は以下の構造です。

```
~/.claude/
├── settings.json          # メイン設定（権限、フック、プラグイン）
├── hooks/                 # ツール実行前後に走るスクリプト
│   └── enforce-uv.sh
├── commands/              # カスタムコマンド（/commit 等）
│   └── commit.md
├── rules/                 # ファイルパターン別のルール
│   ├── python.md
│   ├── gpu.md
│   ├── latex.md
│   └── ask-user-question.md
└── skills/                # 専門的なワークフロー定義
    ├── convert-to-transformers/
    └── high-impact-journal-publishing/
```

chezmoi では `home/dot_claude/` に配置することで `~/.claude/` に展開されます。

:::message
`~/.claude/` をシンボリックリンクにして別の場所（例: `~/.config/claude/`）を参照するパターンもありますが、Claude Code にシンボリックリンク関連のバグが複数報告されており[^1][^2]、直接配置が安全です。
:::

## settings.json — メイン設定

`settings.json` は Claude Code の振る舞い全体を制御する設定ファイルです。

### 権限設定（permissions）

```json
{
  "permissions": {
    "deny": [
      "Bash(sudo:*)",
      "Bash(rm -rf:*)",
      "Read(.env.*)",
      "Read(id_rsa*)",
      "Read(id_ed25519*)",
      "Write(.env*)"
    ],
    "defaultMode": "plan"
  }
}
```

`deny` リストで危険な操作を明示的にブロックします。

| ルール | 説明 |
|--------|------|
| `Bash(sudo:*)` | sudo コマンドの実行を禁止 |
| `Bash(rm -rf:*)` | 再帰的な強制削除を禁止 |
| `Read(.env.*)` / `Write(.env*)` | 環境変数ファイルの読み書きを禁止 |
| `Read(id_rsa*)` / `Read(id_ed25519*)` | 秘密鍵の読み取りを禁止 |

`defaultMode: "plan"` にすると、Claude Code は実行前に計画を提示してくれます。いきなりファイルを編集されたくない場合に便利です。

### 環境変数（env）

```json
{
  "env": {
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
    "DISABLE_PROMPT_CACHING": "1",
    "DISABLE_INSTALLATION_CHECKS": "1"
  }
}
```

| 変数 | 説明 |
|------|------|
| `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` | テレメトリ等の非必須通信を無効化 |
| `DISABLE_PROMPT_CACHING` | プロンプトキャッシュを無効化 |
| `DISABLE_INSTALLATION_CHECKS` | 起動時のアップデートチェックをスキップ |

### プラグイン（enabledPlugins）

```json
{
  "enabledPlugins": {
    "pyright-lsp@claude-plugins-official": true,
    "claude-mem@thedotmack": true
  }
}
```

- **pyright-lsp**: Python の静的型チェック。Claude Code がコードを書くときに型エラーを検出できる
- **claude-mem**: 会話中の観察を自動で記録・要約するメモリプラグイン（後述）

### その他の設定

```json
{
  "alwaysThinkingEnabled": true,
  "plansDirectory": "./plans",
  "statusLine": {
    "type": "command",
    "command": "npx ccstatusline@latest"
  }
}
```

- `alwaysThinkingEnabled`: 常に思考プロセスを表示する（回答の根拠が見えて安心）
- `plansDirectory`: 計画ファイルの保存先
- `statusLine`: ステータスバーのカスタマイズ

## Hooks — ツール実行の自動化

Hooks は Claude Code がツールを使う前後に自動実行されるスクリプトです。コード品質の自動管理にめちゃめちゃ便利です。

### PreToolUse — ツール実行前

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/enforce-uv.sh"
          }
        ]
      }
    ]
  }
}
```

`enforce-uv.sh` は Bash コマンドの実行前に走り、`pip` コマンドを検出してブロックします。代わりに `uv` の対応コマンドを提案してくれます。

```
# Claude Code が pip install numpy を実行しようとすると...
📦 パッケージをインストール:

uv add numpy

💾 'uv add' はpyproject.tomlに依存関係を保存します
🔒 uv.lockで再現可能な環境を保証
```

Claude Code は CLAUDE.md に「uv を使え」と書いても、たまに `pip` を使おうとすることがあります。Hooks で強制すれば確実です。

### PostToolUse — ツール実行後

```json
{
  "PostToolUse": [
    {
      "matcher": "Write|Edit|MultiEdit",
      "hooks": [
        {
          "type": "command",
          "command": "jq -r '.tool_input.file_path | select(endswith(\".py\"))' | xargs -r uvx ruff format"
        },
        {
          "type": "command",
          "command": "jq -r '.tool_input.file_path | select(endswith(\".py\"))' | xargs -r uvx ruff check --fix"
        },
        {
          "type": "command",
          "command": "jq -r '.tool_input.file_path | select(endswith(\".py\"))' | xargs -r uvx mypy"
        },
        {
          "type": "command",
          "command": "jq -r '.tool_input.file_path | select(endswith(\".md\"))' | xargs -r npx prettier@2 --write"
        }
      ]
    }
  ]
}
```

ファイルの書き込み・編集後に自動で実行されます。

| 対象 | 実行されるツール |
|------|----------------|
| `.py` ファイル | `ruff format` → `ruff check --fix` → `mypy` |
| `.md` ファイル | `prettier` でフォーマット |

Claude Code がコードを書くたびに自動でフォーマット・リント・型チェックが走るので、品質を常に保てます。

## Rules — ファイルパターン別ルール

Rules はファイルのパターンに応じて Claude Code の振る舞いを変えるルールです。`~/.claude/rules/` に Markdown ファイルとして配置します。

### python.md — Python ルール

```markdown
---
paths: **/*.py
---

## `uv` の使用
- Python プロジェクトの場合は常に `uv` を使う
- コードを書いたときは常にテストを記述する
- `uv run <script>` でスクリプトを実行

## `pyright-lsp` の使用
- pyright-lsp がインストールされていれば静的解析に使用

## 探索的なデバッグ
- `uv run --with <library> python -c "..."` で一時的にライブラリを試す
```

`paths: **/*.py` を指定すると、Python ファイルを扱うときだけこのルールが適用されます。

### gpu.md — GPU ルール

```markdown
---
paths: **/*.py
---

`torch` を使ったスクリプトを実行する場合は `CUDA_VISIBLE_DEVICES` を指定して実行。
```

GPU を使うスクリプトで、Claude Code がうっかり全 GPU を掴んでしまうのを防ぎます。`nvidia-smi` で空いている GPU を確認してから実行するよう指示しています。

### その他のルール

| ルール | 対象 | 内容 |
|--------|------|------|
| `latex.md` | `**/*.tex` | LaTeX 論文執筆のサポート |
| `ask-user-question.md` | 全般 | Plan モードで仕様不明確時に質問させる |

## Skills — 専門ワークフロー

Skills は特定のタスクに対する詳細なワークフロー定義です。Rules よりも大きな粒度で、手順書のような役割を果たします。

### convert-to-transformers

カスタム PyTorch モデルを Hugging Face Transformers 形式に変換するためのスキルです。

```
skills/convert-to-transformers/
├── SKILL.md                          # メインのワークフロー定義
└── references/
    ├── common-pitfalls.md            # よくあるハマりポイントと解決策
    └── learnings.md                  # 過去のプロジェクトから得た教訓
```

7 ステップの変換ワークフロー（モデル解析 → Config 作成 → Model 作成 → Processor 作成 → テスト → MODEL_CARD → Hub プッシュ）が定義されており、チェックリスト付きです。

`references/` に過去の経験から得た教訓を蓄積していくのが特徴的です。同じミスを繰り返さないように、プロジェクトごとの学びをスキルの中に記録していきます。

### high-impact-journal-publishing

高インパクトジャーナルへの論文出版をサポートするスキルです。El-Omar (2014) の論文[^3]をベースに、研究質問の明確化からピアレビュー対応まで体系化しています。

## Commands — カスタムコマンド

Commands は Claude Code の会話内で `/commit` のように呼び出せるカスタムコマンドです。`~/.claude/commands/` に Markdown で定義します。

### commit.md

Conventional Commits 形式でコミットメッセージを自動生成するワークフローです。

1. 未コミットの変更をレビュー
2. セキュリティ上の懸念ファイルを検出・警告
3. 全変更をステージング
4. Conventional Commits 形式のメッセージを生成
5. ユーザーに承認を求める（Approve / Regenerate / 手動入力）
6. コミット実行

## claude-mem — メモリプラグイン

[claude-mem](https://github.com/thedotmack/claude-mem) は Claude Code の会話を自動的に観察・要約してメモリとして蓄積するサードパーティプラグインです。設定は `~/.claude-mem/settings.json` に保存します。

```json
{
  "CLAUDE_MEM_MODEL": "claude-sonnet-4-5",
  "CLAUDE_MEM_CONTEXT_OBSERVATIONS": "50",
  "CLAUDE_MEM_WORKER_PORT": "37777",
  "CLAUDE_MEM_PROVIDER": "claude"
}
```

| 設定 | 説明 |
|------|------|
| `CLAUDE_MEM_MODEL` | メモリ要約に使うモデル |
| `CLAUDE_MEM_CONTEXT_OBSERVATIONS` | 保持する観察記録の最大数 |
| `CLAUDE_MEM_WORKER_PORT` | ワーカーサーバーのポート |

観察タイプとして `bugfix`, `feature`, `refactor`, `discovery`, `decision`, `change` を自動分類し、コンセプト（`how-it-works`, `problem-solution`, `gotcha` 等）でタグ付けしてくれます。

:::message
Claude Code 本体にも auto memory 機能（`~/.claude/projects/*/memory/`）があります。claude-mem はより細かい粒度で自動追跡する補完的な位置づけです。追加の API コストが発生する点には注意してください。
:::

## chezmoi での管理

chezmoi では以下の構造で配置します。

```
home/
├── dot_claude/                                # → ~/.claude/
│   ├── settings.json
│   ├── hooks/
│   │   └── executable_enforce-uv.sh           # executable_ で実行権限付与
│   ├── commands/
│   │   └── commit.md
│   ├── rules/
│   │   ├── python.md
│   │   ├── gpu.md
│   │   ├── latex.md
│   │   └── ask-user-question.md
│   └── skills/
│       ├── convert-to-transformers/
│       │   ├── SKILL.md
│       │   └── references/
│       └── high-impact-journal-publishing/
│           ├── SKILL.md
│           └── references/
└── dot_claude-mem/                            # → ~/.claude-mem/
    └── settings.json
```

ポイント:

- `dot_claude/` → `~/.claude/` に展開される（chezmoi の `dot_` prefix ルール）
- `executable_enforce-uv.sh` → `enforce-uv.sh` として実行権限付きで配置される
- シンボリックリンクは使わず直接配置。シンプルで確実

`chezmoi apply` するだけで Claude Code の全設定が配置されます。

## ライフサイクル

### 初期セットアップ（初回のみ）

`chezmoi apply` で自動配置されます。プラグインを使う場合は Claude Code 内で有効化してください。

### 日常の操作

| やりたいこと | 方法 |
|------------|------|
| ルールを追加する | `home/dot_claude/rules/` に Markdown を追加 |
| スキルを追加する | `home/dot_claude/skills/<name>/SKILL.md` を作成 |
| Hooks を変更する | `settings.json` の `hooks` セクションを編集 |
| 権限を変更する | `settings.json` の `permissions.deny` を編集 |
| 設定を反映する | `chezmoi apply` |

### カスタマイズのヒント

- **Rules**: 自分がよく使う言語やフレームワークに合わせてルールを追加すると効果的
- **Skills**: 繰り返し行うタスク（デプロイ手順、コードレビューのチェックリスト等）をスキル化すると便利
- **Hooks**: プロジェクト固有のリンターやフォーマッターがあれば PostToolUse に追加

## 参考文献

[^1]: [Claude Code Issue #764 — Symlink Resolution Failure](https://github.com/anthropics/claude-code/issues/764)
[^2]: [Claude Code Issue #3575 — Symlinked settings.json causes permission failures](https://github.com/anthropics/claude-code/issues/3575)
[^3]: El-Omar EM (2014) [How to publish a scientific manuscript in a high-impact journal](https://www.sciencedirect.com/science/article/pii/S2351979714000838). Advances in Digestive Medicine, 1(4), 105-109.
