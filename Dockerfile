FROM ubuntu:24.04

ARG USERNAME=user
ARG USER_UID=1000
ARG USER_GID=$USER_UID

ENV TZ=Asia/Tokyo
ENV DEBIAN_FRONTEND=noninteractive
# chezmoi apply 時に age 暗号化をスキップ
ENV CI=true

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 必要最小限のパッケージ（mise, sheldon 等は chezmoi apply で導入される）
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl git sudo locales ca-certificates \
        build-essential zsh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    locale-gen ja_JP.UTF-8

# ユーザー作成（zsh をログインシェルに設定）
RUN groupadd --gid $USER_GID $USERNAME && \
    useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -G sudo -s /bin/zsh && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# chezmoi インストール
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin

USER $USERNAME
WORKDIR /home/$USERNAME/.local/share/chezmoi
