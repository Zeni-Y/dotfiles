{
  description = "Dotfiles - Nix で CLI ツールを宣言的に管理";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # 全プラットフォーム共通のパッケージ
      commonPackages =
        pkgs: with pkgs; [
          # シェル / ターミナル
          fish
          starship
          yazi
          fzf

          # Git ツール
          chezmoi
          gh
          ghq

          # クラウド / インフラ
          awscli2
          google-cloud-sdk

          # データ処理 / JSON / YAML
          jq
          yq-go

          # セキュリティ
          age

          # Lint / フォーマッタ
          shellcheck
          shfmt

          # ファイル / ディレクトリ
          eza
          fd

          # パッケージマネージャ / ビルドツール
          bun
          uv

          # Web / ドキュメント
          hugo

          # テスト
          bats

          # LSP / 開発ツール
          bash-language-server
          pyright
        ];
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.buildEnv {
            name = "dotfiles-packages";
            paths = commonPackages pkgs;
          };
        }
      );
    };
}
