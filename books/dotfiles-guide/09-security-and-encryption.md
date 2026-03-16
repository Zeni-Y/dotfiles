---
title: "セキュリティと暗号化"
---

# セキュリティと暗号化

## なぜ暗号化が必要か

dotfiles を Git で管理していると、「これもリポジトリに入れたいけど、公開していいのか...？」と悩む場面が出てきます。たとえば:

- SSH 秘密鍵
- API キー・トークン
- パスワード
- 個人情報を含む設定

これらをそのままコミットしてしまうと、リポジトリを公開した瞬間にアウトですよね。かといって Git 管理外にすると、新しいマシンでのセットアップが面倒になります。

chezmoi は暗号化機能を内蔵しているので、**秘密情報を暗号化したまま Git で管理**できます。暗号化ツールとして [age](https://github.com/FiloSottile/age) と [GPG (GNU Privacy Guard)](https://gnupg.org/) の2つに対応していますが、この Book では age を使います。

## age とは

[age](https://github.com/FiloSottile/age) は、FiloSottile 氏が開発したシンプルで安全なファイル暗号化ツールです。「暗号化だけをやる。その代わり、それを安全にやる」という設計思想で作られています。

### GPG ではなく age を選ぶ理由

[GPG (GNU Privacy Guard)](https://gnupg.org/) は、メールの暗号化・電子署名・ファイル暗号化など幅広い用途に対応した暗号化ツールです。歴史が長く（1999年リリース）広く普及していますが、その汎用性ゆえに設定や鍵管理がかなり複雑です。鍵サーバーへの登録、信頼の網（Web of Trust）、サブキーの管理...正直、dotfiles のファイル暗号化だけが目的なのに GPG のフルセットアップをするのはめんどくさいですよね。

| 特徴 | [GPG](https://gnupg.org/) | [age](https://github.com/FiloSottile/age) |
|------|-----|-----|
| リリース年 | 1999年 | 2019年 |
| 設定の複雑さ | 高い（鍵サーバー、信頼モデル等） | 低い（鍵ファイル1つ） |
| 鍵の管理 | 複雑（主鍵・サブキー・失効証明書） | シンプル（ファイル1つ） |
| 暗号化方式 | 多数（RSA, DSA, ECDSA 等） | X25519 + ChaCha20-Poly1305[^1] |
| 用途 | 汎用（メール署名、ファイル暗号化等） | ファイル暗号化に特化 |

age は使わない機能を削ぎ落としている分、覚えることが少なくて済みます。dotfiles の秘密情報を暗号化する用途には age がぴったりです。

## chezmoi + age でファイルを暗号化管理するまでの全体像

ここから、age の鍵生成 → chezmoi の設定 → ファイルの暗号化追加 → 復号・適用 までを順番に進めていきます。全体の流れを先に示しておきます。

```
Step 1: age 鍵ペアを生成
         ↓ 公開鍵（age1...）と秘密鍵（AGE-SECRET-KEY-...）が得られる
Step 2: chezmoi に age を設定（.chezmoi.yaml.tmpl に公開鍵の中身と秘密鍵のパスを記載）
         ↓ chezmoi が暗号化・復号できる状態になる
Step 3: chezmoi add --encrypt で秘密ファイルを追加
         ↓ ソースディレクトリに .age ファイルが作成される
Step 4: chezmoi apply で復号・配置
         ↓ 暗号化ファイルが元のパスに復号されて配置される
```

### Step 1: age 鍵ペアの生成

まず age の鍵ペア（公開鍵と秘密鍵）を生成します。

```bash
mkdir -p ~/.config/age
age-keygen -o ~/.config/age/key.txt
```

実行すると、以下のような出力が表示されます。

```
Public key: age1vhjw9eclwdtcsc47wspfkgakyvqehlgkuqd8m338ql7nnp9y0s0qwnw9sx
```

この時点で2つのものが手に入ります。

- **公開鍵** (`age1...`): 画面に表示される文字列。暗号化に使う。次の Step 2 で `.chezmoi.yaml.tmpl` に記載する
- **秘密鍵** (`AGE-SECRET-KEY-...`): `~/.config/age/key.txt` に保存される。復号に使う。**絶対にコミットしない**

### Step 2: chezmoi に age を設定する

Step 1 で得た**公開鍵**と、秘密鍵の**ファイルパス**を `.chezmoi.yaml.tmpl` に記載します。

```yaml
{{ if ne (env "CI") "true" -}}
encryption: "age"
age:
    identity: "~/.config/age/key.txt"
    recipient: "age1vhjw9eclwdtcsc47wspfkgakyvqehlgkuqd8m338ql7nnp9y0s0qwnw9sx"
{{- end }}
```

- `encryption: "age"` — 暗号化方式に age を指定
- `identity` — Step 1 で生成した秘密鍵のパス（復号時に使用）
- `recipient` — Step 1 で表示された公開鍵（暗号化時に使用）。**ここを自分の公開鍵に書き換える**

この設定により、chezmoi が `--encrypt` フラグ付きで追加されたファイルを公開鍵で暗号化し、`chezmoi apply` 時に秘密鍵で復号できるようになります。

### Step 3: 暗号化ファイルの追加

Step 2 の設定が済んだら、秘密ファイルを暗号化して管理対象に追加します。

```bash
chezmoi add --encrypt ~/.ssh/id_ed25519
```

実行すると、chezmoi のソースディレクトリに暗号化されたファイルが作成されます。

```
home/private_dot_ssh/encrypted_private_id_ed25519.age
```

ファイル名の各パーツの意味はこうです。

| パーツ | 意味 |
|--------|------|
| `private_dot_ssh/` | `~/.ssh/`（`private_` でパーミッション制限、`dot_` で `.` に変換） |
| `encrypted_` | age で暗号化されていることを示す |
| `private_` | パーミッションを制限（ファイル: `0600`、ディレクトリ: `0700`） |
| `id_ed25519` | 元のファイル名 |
| `.age` | age 暗号化ファイルの拡張子 |

`.age` ファイルの中身はバイナリの暗号文なので、Git にコミットしても秘密情報が漏れることはありません。

:::message
**`private_` が付かない場合**: chezmoi は `chezmoi add` 時に**実際のファイル・ディレクトリのパーミッション**を見て `private_` を付けるか判断します。`~/.ssh/` のパーミッションが `700`（所有者のみ）なら `private_dot_ssh` に、`755` や `775` なら `dot_ssh`（`private_` なし）になります。Docker 環境などではディレクトリのパーミッションが緩くなっていることがあるので、`chezmoi add` の前に `chmod 700 ~/.ssh` でパーミッションを正しくしておきましょう。
:::

### Step 4: 復号と適用

別のマシンや、`chezmoi apply` を実行すると、Step 2 で設定した秘密鍵（`identity`）を使って `.age` ファイルが自動的に復号され、元のパスに配置されます。

```bash
chezmoi apply

# 結果: ~/.ssh/id_ed25519 が復号されて配置される（パーミッション 0600）
```

:::message alert
`chezmoi apply` 時に `age: error: no identity matched any of the recipients` というエラーが出る場合、`identity` に指定した秘密鍵が `recipient` の公開鍵と対応していません。`age-keygen -y ~/.config/age/key.txt` で秘密鍵から公開鍵を導出し、`.chezmoi.yaml.tmpl` の `recipient` と一致するか確認してください。
:::

## private_ プレフィックス

`private_` プレフィックスを付けると、パーミッションが所有者のみに制限されます。ディレクトリは `0700`（rwx）、ファイルは `0600`（rw）です。

```
private_dot_ssh/              → ~/.ssh/ (0700)
private_dot_ssh/config        → ~/.ssh/config (0600)
```

暗号化とは別の機能ですが、ファイルのパーミッションを適切に設定するために重要です。SSH 関連のファイルは必ず `private_` を付けましょう。SSH はパーミッションが甘いと接続を拒否するので、これを忘れるとハマります。

## CI 環境での暗号化無効化

```yaml
{{ if ne (env "CI") "true" -}}
encryption: "age"
...
{{- end }}
```

`CI=true` 環境変数が設定されている場合、暗号化設定を丸ごと無効にしています。CI 環境には秘密鍵が存在しないので、暗号化ファイルの復号をスキップする必要があるためです。

## GPG_TTY の設定

Git のコミット署名など GPG を使う操作には `GPG_TTY` 環境変数が必要です。sheldon の inline プラグインで設定しています。

```toml
# plugins.toml
[plugins.gpg]
inline = 'export GPG_TTY=$(tty)'
apply = ["defer"]
```

`GPG_TTY` が設定されていないと、GPG がパスフレーズの入力を求める端末を特定できず、署名に失敗します。

## .workrc による非追跡設定の分離

仕事用の設定や個人的なトークンなど、**Git で管理したくない設定**は `~/.workrc` に分離します。

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

age の秘密鍵ファイル `key.txt` を `.gitignore` で明示的に除外しています。うっかりコミットしてしまうリスクを排除するための安全策ですね。

## age 秘密鍵自体の管理

ここまでの説明で「暗号化ファイルは age で守る」ことはわかりました。でもここで1つ疑問が出てきますよね。**age の秘密鍵自体はどう管理するの？**という問題です。

### 鶏と卵の問題

```
encrypted_ ファイルを復号するには → age 秘密鍵が必要
age 秘密鍵も安全に管理したい   → でもどうやって？
```

これ、最初にぶつかるポイントだと思います。

### 解決策: パスフレーズ暗号化でリポジトリに含める

age にはパスフレーズでファイルを暗号化する機能があります。これを使って**秘密鍵自体をパスフレーズで暗号化し、リポジトリに含めてしまう**という方法があります。セットアップの流れを見ていきましょう。

#### 1. age 秘密鍵をパスフレーズで暗号化する

```bash
age --encrypt --passphrase --output .key.txt.age ~/.config/age/key.txt
```

実行するとパスフレーズの入力を求められます。ここで入力したパスフレーズが、新しいマシンでのセットアップ時に必要になるので、パスワードマネージャ等に保管しておきましょう。

これで以下の2つが揃います。

| ファイル | 内容 | Git 管理 |
|----------|------|----------|
| `.key.txt.age` | パスフレーズで暗号化された age 秘密鍵 | **する**（リポジトリに含める） |
| `~/.config/age/key.txt` | 平文の age 秘密鍵 | **しない**（`.gitignore` で除外） |

#### 2. 初回セットアップの自動化スクリプトを作る

新しいマシンで `chezmoi apply` したとき、暗号化ファイルを復号するには age 秘密鍵が必要です。でも秘密鍵自体がまだない——ということで、`run_once_before` スクリプトで**他のファイルより先に**秘密鍵を復号します。

```bash
#!/usr/bin/env bash
# .chezmoiscripts/common/run_once_before_01-decrypt-private-key.sh.tmpl

{{ if ne (env "CI") "true" -}}
age_dst_key="${HOME}/.config/age/key.txt"
age_src_key="{{ .chezmoi.sourceDir }}/.key.txt.age"

if [ ! -f "${age_dst_key}" ]; then
    mkdir -p "$(dirname "${age_dst_key}")"
    chezmoi age decrypt --output "${age_dst_key}" --passphrase "${age_src_key}"
    chmod 600 "${age_dst_key}"
fi
{{- end }}
```

ポイント:

- `run_once_before` なので、他のファイル展開（`encrypted_*` の復号含む）**より前に**実行される
- `if [ ! -f ... ]` で秘密鍵が既に存在する場合はスキップ（冪等性）
- `chmod 600` で秘密鍵のパーミッションを適切に設定

#### 3. 新しいマシンでの実行フロー

新しいマシンで `chezmoi apply` を叩くと、以下の順番で処理が進みます。

```
chezmoi apply
  │
  ├─ 1. run_once_before スクリプトが実行される
  │     → .key.txt.age をパスフレーズで復号
  │     → ~/.config/age/key.txt（平文の秘密鍵）が生成される
  │     ★ ここでパスフレーズの入力を求められる
  │
  ├─ 2. 通常のファイル展開
  │     → encrypted_*.age ファイルを秘密鍵で復号
  │     → ~/.ssh/id_ed25519 等が配置される
  │
  └─ 3. run_once_after スクリプトが実行される
        → sheldon, mise 等のインストール
```

つまり `chezmoi apply` を叩くだけでパスフレーズを聞かれて、あとは全部自動でやってくれます。めちゃめちゃ楽ですね。

### 信頼の連鎖

ここまでの仕組みを整理すると、セキュリティの信頼構造はこうなっています。

```
パスフレーズ（人間の記憶）
  └─→ .key.txt.age を復号
        └─→ ~/.config/age/key.txt（age 秘密鍵）
              └─→ encrypted_*.age を復号
                    └─→ ~/.ssh/id_ed25519 等（実際の秘密ファイル）
```

結局、セキュリティの信頼の根は**パスフレーズ1つ**に帰着します。覚えるものが1つで済むのはシンプルで良いですよね。

### パスフレーズの安全性

「パスフレーズだけで大丈夫なの？何度も試行されたら突破されるのでは？」という疑問は当然あると思います。

結論から言うと、**十分な長さのパスフレーズであれば現実的に突破は不可能**です。

age のパスフレーズ暗号化は内部で **scrypt** という鍵導出関数（KDF）を使っています[^1]。scrypt は意図的に CPU とメモリを大量に消費する設計になっていて、1回の試行にかなりのコストがかかります。デフォルトのパラメータは N=2^18（約256MiBのメモリを要求）、r=8、p=1 です[^2]。

| パスフレーズの強度 | 試行速度（scrypt） | 全探索にかかる時間 |
|---|---|---|
| 8文字ランダム英数字 | ~10回/秒 | ~約7000万年 |
| 20文字ランダム | ~10回/秒 | ~10^31 年（非現実的） |

GPU や ASIC を使った並列攻撃にも耐性があります。scrypt は**メモリハード**な設計なので、並列化しようとするとその分メモリも比例して必要になります[^3]。

:::message
パスフレーズはパスワードマネージャ（1Password、Bitwarden 等）で管理するのがおすすめです。覚えるのはマスターパスワード1つだけで済みます。
:::

### もう1つの選択肢: リポジトリに含めない

とはいえ「公開リポジトリに暗号化された鍵を置くこと自体が嫌だ」という方もいると思います。その場合は `.key.txt.age` をリポジトリに含めず、秘密鍵をパスワードマネージャ等で別管理する方法もあります。

| 方法 | メリット | デメリット |
|------|----------|------------|
| `.key.txt.age` をリポジトリに含める | セットアップが簡単（パスフレーズ入力だけ） | 公開リポジトリに暗号化鍵が存在する |
| パスワードマネージャで別管理 | 攻撃者にブルートフォースの機会を与えない | 新しいマシンで手動コピーが必要 |

どちらを選ぶかは「利便性」と「セキュリティの厳格さ」のトレードオフです。個人的には、十分に強いパスフレーズを設定していれば前者で問題ないと思っています。

## 多層的なセキュリティ設計

ここまで色々なセキュリティ手法を紹介してきましたが、実は秘密情報の**機密度に応じて管理方法を使い分ける**のが大事です。

### 3層モデル

```
┌─────────────────────────────────────────────────────┐
│  Layer 1: 公開リポジトリ + 暗号化なし                │
│  → zshrc, gitconfig 等の一般的な設定                 │
│  → 誰に見られても問題ないもの                        │
├─────────────────────────────────────────────────────┤
│  Layer 2: 公開リポジトリ + age 暗号化                │
│  → SSH 秘密鍵, GPG 鍵, VPN 認証情報                 │
│  → 「自分の」秘密だが、ファイルの存在は公開して良い  │
├─────────────────────────────────────────────────────┤
│  Layer 3: 非公開リポジトリ or .workrc                │
│  → 職場/組織固有の設定、社内サーバー名               │
│  → ファイルの存在自体を知られたくないもの            │
└─────────────────────────────────────────────────────┘
```

### Layer 2 と Layer 3 の使い分け

判断基準は **「暗号化すれば十分か、それとも存在自体を隠す必要があるか」** です。

| 判断軸 | Layer 2（公開+暗号化） | Layer 3（非公開 or .workrc） |
|--------|----------------------|---------------------------|
| 内容の所有者 | 個人 | 組織・職場 |
| メタデータの公開可否 | ファイル名が見えてもOK | ファイル名すら見せたくない |
| 例 | `encrypted_id_ed25519.age`（SSH鍵があること自体は問題ない） | 社内サーバーのホスト名・IP（ネットワーク構成が推測される） |

たとえば SSH 秘密鍵は、`encrypted_id_ed25519.age` というファイル名が見えても「SSH鍵を使っているんだな」くらいしかわからないので Layer 2 で十分です。一方、社内サーバーのホスト名や IP アドレスはファイル名やパスからネットワーク構成が推測されてしまうので、Layer 3 で管理した方がいいですね。

:::message
**実際のところ、個人の dotfiles では Layer 2（公開+暗号化）で十分なケースがほとんどだと思います。** ファイル名に機密情報が含まれるケースは稀ですし、`encrypted_id_ed25519.age` のようなファイル名から得られる情報は「SSH鍵を使っている」程度で、それは誰でも想像がつくことです。Layer 3 が本当に必要になるのは、ファイル名やディレクトリ構造からインフラ構成が推測されるような**組織固有の設定**を扱う場合に限られると思います。
:::

### Layer 3 の実現方法

#### 方法 A: `.workrc` による分離（シンプル）

本チャプターの前半で紹介した `.workrc` のパターンです。Git 管理外のファイルに職場固有の設定を記述します。セットアップの手間が少ない反面、バックアップは自己責任になります。

#### 方法 B: 非公開リポジトリの分離（堅牢）

chezmoi は `--source` と `--config` オプションで複数のインスタンスを使い分けられます。

```bash
# 非公開リポジトリ用のエイリアス
alias chezmoi-private="chezmoi \
  --source ~/.local/share/chezmoi-private \
  --config ~/.config/chezmoi-private/chezmoi.yaml"

# 初期化（SSH 経由で非公開リポジトリを clone）
chezmoi-private init --apply --ssh github-username/dotfiles-private
```

公開リポジトリ側に拡張ポイント（例: SSH config の `Include ~/.ssh/work.d/config`）を用意しておいて、非公開リポジトリからそこにファイルを配置する設計にすると、2つのリポジトリが**補完関係**で共存できます。

個人利用なら `.workrc` で十分だと思いますが、複数マシンで職場設定を同期したい場合は非公開リポジトリの方が便利です。

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

## ライフサイクル

### 初期セットアップ（初回のみ）

新しいマシンでは `chezmoi apply` を実行するだけです。`run_once_before` スクリプトがパスフレーズを聞いて age 秘密鍵を復号し、その後の `encrypted_*` ファイルの復号が自動で行われます。

### 日常の操作

暗号化関連で日常的に操作することはほとんどありません。`chezmoi apply` / `chezmoi update` で暗号化ファイルの復号は自動的に行われます。

### 暗号化ファイルを編集したいとき

暗号化済みのファイル（`encrypted_*.age`）を編集したい場合、2つの方法があります。

#### 方法 A: `chezmoi edit`（推奨）

```bash
chezmoi edit ~/.ssh/config
```

chezmoi が自動で復号 → エディタで編集 → 保存時に再暗号化までやってくれます。一番シンプルで安全な方法です。

#### 方法 B: ターゲット側を直接編集して `re-add`

`~/.ssh/config` を直接編集してから、変更を chezmoi の source に書き戻す方法です。

```bash
# 1. ターゲットファイルを直接編集
vim ~/.ssh/config

# 2. 差分を確認
chezmoi diff

# 3. 変更を source に反映（自動で再暗号化される）
chezmoi re-add ~/.ssh/config
```

`chezmoi re-add` は、既に管理対象のファイルについてターゲット側の変更を source に書き戻すコマンドです。暗号化対象のファイルなら自動で `.age` に再暗号化してくれます。

どちらでもいいですが、`chezmoi edit` の方が「復号 → 編集 → 再暗号化」を1コマンドで完結できるので楽です。

### 新しい秘密ファイルを追加したいとき

```bash
# 1. 対象ファイルのパーミッションを確認・修正
#    （private_ を付けたい場合はディレクトリを 700 にしておく）
chmod 700 ~/.ssh

# 2. 暗号化して chezmoi に追加
chezmoi add --encrypt ~/.ssh/id_ed25519

# 3. ソースディレクトリで確認・コミット
chezmoi cd
git add -A
git commit -m "feat: add encrypted ssh key"
git push
```

### age 鍵を再生成したいとき

鍵の漏洩が疑われる場合や、鍵をローテーションしたい場合の手順です。

```bash
# 1. 新しい鍵ペアを生成
age-keygen -o ~/.config/age/key.txt

# 2. 新しい公開鍵を .chezmoi.yaml.tmpl の recipient に記載
chezmoi edit-config-template

# 3. 既存の暗号化ファイルを再暗号化（古い鍵で復号 → 新しい鍵で暗号化）
chezmoi re-add

# 4. .key.txt.age も再暗号化
age --encrypt --passphrase --output .key.txt.age ~/.config/age/key.txt

# 5. コミット
chezmoi cd
git add -A
git commit -m "chore: rotate age key"
git push
```

## 参考文献

[^1]: [age-encryption.org/v1 — age 公式仕様](https://age-encryption.org/v1) — 暗号化方式（X25519, ChaCha20-Poly1305）および scrypt recipient の仕様を定義
[^2]: [age scrypt.go — リファレンス実装](https://github.com/FiloSottile/age/blob/main/scrypt.go) — scrypt パラメータ（N=2^18, r=8, p=1, dkLen=32）の実装
[^3]: [The scrypt Password-Based Key Derivation Function (RFC 7914)](https://datatracker.ietf.org/doc/html/rfc7914) — scrypt のメモリハード特性の仕様
