# dotfiles Docker テスト用 PowerShell スクリプト
# Windows 環境で Makefile の代替として使用
#
# 使い方:
#   .\Makefile.ps1 docker          # ビルド＆実行
#   .\Makefile.ps1 docker-rebuild  # キャッシュなしで再ビルド
#   .\Makefile.ps1 init            # chezmoi init --apply
#   .\Makefile.ps1 update          # chezmoi apply
#   .\Makefile.ps1 reset           # chezmoi state リセット
#   .\Makefile.ps1 diff            # chezmoi diff
#   .\Makefile.ps1 data            # chezmoi data

param(
    [Parameter(Position = 0)]
    [ValidateSet("docker", "docker-rebuild", "init", "update", "reset", "diff", "data")]
    [string]$Target = "docker"
)

$ImageName = "dotfiles"
$Username = $env:USERNAME.ToLower()

function Invoke-DockerBuild {
    param([switch]$NoCache)

    $args = @(
        "build", "-t", $ImageName, "."
        "--build-arg", "USERNAME=$Username"
        "--build-arg", "USER_UID=1000"
        "--build-arg", "USER_GID=1000"
    )
    if ($NoCache) { $args += "--no-cache" }

    docker @args
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

switch ($Target) {
    "docker" {
        # イメージが存在しなければビルド
        docker inspect $ImageName 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Invoke-DockerBuild
        }
        # コンテナ実行
        docker run -it --rm `
            -v "${PWD}:/home/${Username}/.local/share/chezmoi" `
            --hostname dotfiles-test `
            $ImageName /bin/bash --login
    }
    "docker-rebuild" {
        Invoke-DockerBuild -NoCache
    }
    "init" {
        chezmoi init --apply --verbose
    }
    "update" {
        chezmoi apply --verbose
    }
    "reset" {
        chezmoi state delete-bucket --bucket=scriptState
    }
    "diff" {
        chezmoi diff
    }
    "data" {
        chezmoi data
    }
}
