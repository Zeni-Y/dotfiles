---
title: "はじめに"
---

# はじめに

## この Book の目的

この Book は、**chezmoi** を中心としたモダンな dotfiles 管理の実践ガイドです。

「dotfiles、Git で管理したいけど何使えばいいんだろう」「新しいマシンのセットアップ毎回めんどくさいな...」そんな方に向けて、筆者が実際に運用している dotfiles リポジトリをベースに以下の内容を解説します。

- [chezmoi](https://www.chezmoi.io/) によるテンプレートベースの dotfiles 管理
- [sheldon](https://sheldon.cli.rs/) + zsh-defer による高速なシェル環境
- [mise](https://mise.jdx.dev/) による言語ランタイム・CLI ツールの一元管理
- [eza](https://github.com/eza-community/eza), [bat](https://github.com/sharkdp/bat), [fd](https://github.com/sharkdp/fd), [ripgrep](https://github.com/BurntSushi/ripgrep) などのモダン CLI ツール
- [age](https://github.com/FiloSottile/age) 暗号化によるセキュリティ
- macOS / Ubuntu Desktop / Ubuntu Server のクロスプラットフォーム対応
- [Zed](https://zed.dev/) エディタの設定と管理

筆者の技術選定の基本方針は **「必要十分でシンプル」** です。複雑な設定より覚えやすくて見返しやすいものを優先しています。この Book 自体もその考え方で書いているので、「とりあえずこれだけ押さえておけば大丈夫」というラインを意識しています。

## 対象読者

- Linux / macOS のターミナルを日常的に使っている人
- シェルの基礎知識（環境変数、PATH、シェルスクリプト）がある人
- dotfiles を管理したいけど、どのツールを使えばいいか分からない人
- 既に dotfiles を管理しているけど、もっと良い方法を探している人

## 前提知識

- シェル（bash / zsh）の基本操作
- Git の基本操作（clone, commit, push）
- テキストエディタの操作

## 全体の構成

| チャプター | 内容 |
|-----------|------|
| dotfiles とは何か | dotfiles の基礎と管理手法の比較 |
| chezmoi 入門 | 基本コマンドとファイル構造 |
| chezmoi テンプレートと応用 | Go template、スクリプト、高度な機能 |
| zsh と sheldon | プラグイン管理と遅延読み込み |
| mise によるランタイム管理 | 言語・ツールのバージョン管理 |
| モダン CLI ツール群 | eza, bat, fd, ripgrep, starship 等 |
| fzf でインタラクティブ検索 | ファジー検索とカスタマイズ |
| セキュリティと暗号化 | age による秘密情報管理 |
| クロスプラットフォーム対応 | OS / system 別の分岐管理 |
| 開発ワークフロー | 変更サイクルとテスト手法 |
| リファレンス | コマンドチートシート・参考リンク |
| Zed エディタ | 設定・キーバインド・WSL 連携 |

:::message
この Book で紹介する設定はすべて筆者の dotfiles リポジトリで実際に動作しているものです。リポジトリを参照しながら読むとより理解が深まると思います。
:::
