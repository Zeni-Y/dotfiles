---
title: "セキュリティと暗号化"
---

# セキュリティと暗号化

## なぜ暗号化が必要か

dotfiles を Git で管理する場合、以下のような秘密情報をそのままコミットすることはできません:

- SSH 秘密鍵
- API キー・トークン
- パスワード
- 個人情報を含む設定

chezmoi は暗号化機能を内蔵しており、これらの秘密情報を安全に Git で管理できます。

## age とは

[age](https://github.com/FiloSottile/age) は、シンプルで安全なファイル暗号化ツールです。

### GPG との比較

| 特徴 | GPG | age |
|------|-----|-----|
| 設定の複雑さ | 高い | 低い |
| 鍵の管理 | 複雑（鍵サーバー等） | シンプル（ファイル1つ） |
| 鍵の形式 | 複数形式 | 1形式のみ |
| 暗号化方式 | 多数 | X25519 + ChaCha20-Poly1305 |
| 用途 | 汎用 | ファイル暗号化に特化 |

age は「やることが少ない代わりに、それを安全にやる」という設計思想です。GPG の複雑さに悩まされることなく、ファイル暗号化だけに集中できます。

### 鍵の生成

```bash
# 鍵を生成
age-keygen -o ~/.config/age/key.txt

# 出力例
# created: 2024-01-01T00:00:00+09:00
# public key: age1vhjw9eclwdtcsc47wspfkgakyvqehlgkuqd8m338ql7nnp9y0s0qwnw9sx
AGE-SECRET-KEY-1XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

- **公開鍵** (`age1...`): 暗号化に使用。`.chezmoi.yaml.tmpl` に記載して OK
- **秘密鍵** (`AGE-SECRET-KEY-...`): 復号に使用。**絶対にコミットしない**

## chezmoi + age の設定

### .chezmoi.yaml.tmpl

```yaml
{{ if ne (env "CI") "true" -}}
encryption: "age"
age:
    identity: "~/.config/age/key.txt"
    recipient: "age1vhjw9eclwdtcsc47wspfkgakyvqehlgkuqd8m338ql7nnp9y0s0qwnw9sx"
{{- end }}
```

- `encryption: "age"` — 暗号化方式に age を指定
- `identity` — 秘密鍵のパス
- `recipient` — 公開鍵（暗号化時に使用）

### 暗号化ファイルの追加

```bash
# --encrypt フラグで暗号化して管理
chezmoi add --encrypt ~/.ssh/id_ed25519

# ソースディレクトリに暗号化されたファイルが作成される
# → home/private_dot_ssh/encrypted_private_id_ed25519.age
```

`chezmoi apply` 時に自動的に復号されて配置されます。

## private_ プレフィックス

`private_` プレフィックスを付けたファイルは、パーミッションが `0600`（所有者のみ読み書き可能）で配置されます。

```
private_dot_ssh/              → ~/.ssh/ (パーミッション制限)
private_dot_ssh/config        → ~/.ssh/config (0600)
```

暗号化とは別に、ファイルのパーミッションを適切に設定する機能です。SSH 関連のファイルは必ず `private_` を付けましょう。

## CI 環境での暗号化無効化

```yaml
{{ if ne (env "CI") "true" -}}
encryption: "age"
...
{{- end }}
```

`CI=true` 環境変数が設定されている場合、暗号化設定を無効にします。CI 環境では秘密鍵が存在しないため、暗号化ファイルの復号をスキップする必要があります。

## GPG_TTY の設定

Git のコミット署名や GPG 操作に必要な `GPG_TTY` 環境変数を sheldon で設定しています。

```toml
# plugins.toml
[plugins.gpg]
inline = 'export GPG_TTY=$(tty)'
apply = ["defer"]
```

`GPG_TTY` が設定されていないと、GPG がパスフレーズの入力を求める端末を特定できず、署名に失敗します。

## .workrc による非追跡設定の分離

仕事用の設定や個人的なトークンなど、**Git で管理したくない設定**は `~/.workrc` に記述します。

```toml
# plugins.toml
[plugins.private-dotfiles]
inline = '[[ -f ~/.workrc ]] && source ~/.workrc'
apply = ["defer"]
```

- `~/.workrc` が存在すれば自動的に読み込まれる
- 存在しなくてもエラーにならない
- Git 管理外なので、マシンごとに異なる内容を設定できる

使い方の例:

```bash
# ~/.workrc（Git 管理外）
export COMPANY_API_KEY="xxxxx"
export SLACK_TOKEN="xxxxx"
alias vpn="sudo openconnect vpn.company.com"
```

## .gitignore のセキュリティ設計

```gitignore
# age key（秘密鍵は絶対にコミットしない）
key.txt
```

age の秘密鍵ファイル `key.txt` を `.gitignore` で明示的に除外しています。うっかりコミットしてしまうリスクを排除しています。

## セキュリティのベストプラクティス

### やるべきこと

1. **秘密鍵は age で暗号化して管理**する
2. **`private_` プレフィックス**で適切なパーミッションを設定する
3. **`.gitignore`** で秘密鍵ファイルを除外する
4. **`.workrc`** でマシン固有の秘密設定を分離する
5. **公開鍵のみ** `.chezmoi.yaml.tmpl` に記載する

### やってはいけないこと

1. **秘密鍵を平文でコミット**する
2. **API キーやパスワードを `.zshrc` に直接記述**する
3. **age の秘密鍵を紛失**する（復号不可能になる）
4. **信頼できないマシンに秘密鍵をコピー**する

:::message alert
age の秘密鍵を紛失すると、暗号化されたファイルを復号できなくなります。秘密鍵は安全な場所にバックアップしてください。
:::
