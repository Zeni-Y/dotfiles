---
title: "Git コミット署名"
---

# Git コミット署名

## なぜ署名が必要なのか

Git では `user.name` と `user.email` を自由に設定できます。つまり、こんなことができてしまいます。

```bash
git config user.name "Linus Torvalds"
git config user.email "torvalds@linux-foundation.org"
```

これで他人になりすましたコミットが作れます。Git 自体には「このコミットが本当にその人によるものか」を検証する仕組みがないんですよね。

**コミット署名**は、「このコミットは確かに本人が作った」ことを暗号的に証明する仕組みです。GitHub では署名付きコミットに "Verified" バッジが表示されるので、見た目にもわかりやすいです。

:::message
個人開発では必須ではありません。ただ、OSS のコントリビューションや業務での利用では、なりすまし防止として重要になります。
:::

## GPG 署名と SSH 署名

コミット署名の方法は2つあります。

### GPG 署名（従来の方法）

[GPG (GNU Privacy Guard)](https://gnupg.org/) は暗号化・署名・認証を行う汎用ツールで、Git は以前から GPG による署名に対応していました。たとえば [shunk031/dotfiles](https://github.com/shunk031/dotfiles) では `private_dot_gnupg/` ディレクトリで GPG 鍵一式を chezmoi + age で管理しています。

```
private_dot_gnupg/
├── gpg-agent.conf.tmpl              # pinentry の設定
├── encrypted_pubring.kbx.age        # 公開鍵リング
├── encrypted_private_trustdb.gpg.age # 信頼データベース
├── private_openpgp-revocs.d/        # 失効証明書
└── private_private-keys-v1.d/       # 秘密鍵
```

ただ、GPG は設定が多くて大変です。鍵の生成、gpg-agent の設定、pinentry プログラムの指定（OS ごとに異なる）、鍵サーバーへの登録...。dotfiles の署名のためだけにこれをやるのは正直めんどくさいですよね。

### SSH 署名（Git 2.34+ の新しい方法）

Git 2.34（2021年リリース）から、**SSH 鍵でコミットに署名できる**ようになりました[^1]。SSH 鍵はほとんどの開発者が既に持っているので、新しい鍵を生成する必要がありません。

| | GPG 署名 | SSH 署名 |
|---|---|---|
| 必要な鍵 | GPG 鍵ペア（別途生成が必要） | SSH 鍵（既存のものを流用可） |
| 設定の複雑さ | 高い（鍵生成、gpg-agent、pinentry 等） | シンプル（Git の設定3行） |
| 管理するもの | `~/.gnupg/` 以下の複数ファイル | 既存の SSH 鍵をそのまま使う |
| Git の対応 | 以前から対応 | Git 2.34+（2021年〜） |
| GitHub 対応 | あり | あり |

SSH 鍵を既に chezmoi で管理しているなら、**追加の鍵管理なしで**署名を始められます。必要十分でシンプル。これが SSH 署名を選ぶ理由です。

### 設定名が `gpg` なのは歴史的経緯

SSH 署名を設定していると、こんな疑問が浮かぶと思います。「SSH 署名なのに、なぜ設定名が `gpg.format` や `commit.gpgsign` なの？」

これは Git がもともと GPG しかサポートしていなかったためです。署名関連の設定名がすべて `gpg` で固定された後に SSH 署名が追加されたので、**既存の設定名との互換性を維持するため**にそのまま残されました[^1]。紛らわしいですが、そういうものです。

## SSH 署名の設定

### Git の設定

chezmoi で管理している Git の設定ファイルに以下を追加します。

```toml
# dot_config/git/config.tmpl

[user]
	name = zenimoto
	email = {{ .email | quote }}
	signingkey = ~/.ssh/id_ed25519.pub
[gpg]
	format = ssh
[commit]
	gpgsign = true
[tag]
	gpgsign = true
```

| 設定 | 値 | 説明 |
|---|---|---|
| `user.signingkey` | `~/.ssh/id_ed25519.pub` | 署名に使う SSH 公開鍵のパス |
| `gpg.format` | `ssh` | 署名形式を SSH に指定 |
| `commit.gpgsign` | `true` | 全コミットに自動で署名 |
| `tag.gpgsign` | `true` | 全タグにも自動で署名 |

`commit.gpgsign = true` にしておくと、毎回 `git commit -S` を付けなくても自動で署名されるので楽です。

### GitHub に Signing Key を登録

Git の設定だけでは、GitHub 上で "Verified" バッジは表示されません。GitHub に同じ公開鍵を **Signing Key** として登録する必要があります。

:::message
SSH 鍵を Authentication Key として既に登録していても、Signing Key は **別途登録が必要**です。GitHub は認証用と署名用の鍵を別々に管理しています。
:::

登録手順:

1. [GitHub SSH and GPG keys 設定ページ](https://github.com/settings/keys) を開く
2. **New SSH key** をクリック
3. **Key type** を **Signing Key** に変更
4. 自分の SSH 公開鍵（`~/.ssh/id_ed25519.pub` の内容）を貼り付けて保存

### 動作確認

設定が正しいか確認してみましょう。

```bash
# テストコミットを作成して署名を確認
echo "test" >> /tmp/test.txt
cd /tmp && git init test-signing && cd test-signing
git add -A && git commit --allow-empty -m "test: verify ssh signing"
git log --show-signature -1
```

`Good "git" signature` のような出力が表示されれば成功です。

## 参考文献

[^1]: [Git - git-config Documentation (gpg.format)](https://git-scm.com/docs/git-config#Documentation/git-config.txt-gpgformat) — SSH 署名の設定仕様
