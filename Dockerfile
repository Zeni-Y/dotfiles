FROM ubuntu:24.04

ARG USERNAME=user
ARG USER_UID=1000
ARG USER_GID=$USER_UID

ENV TZ=Asia/Tokyo
ENV DEBIAN_FRONTEND=noninteractive
# CI=true で chezmoi の対話プロンプトをスキップ（email, system をデフォルト値で設定）
ENV CI=true

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 必要最小限のパッケージ（mise, sheldon 等は chezmoi apply で導入される）
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl git sudo locales ca-certificates \
        build-essential && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    locale-gen ja_JP.UTF-8

# ユーザー作成
RUN groupadd --gid $USER_GID $USERNAME && \
    useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -G sudo -s /bin/bash && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER $USERNAME
RUN mkdir -p ~/.local/bin ~/.local/share/chezmoi ~/.local/share/fonts
WORKDIR /home/$USERNAME/.local/share/chezmoi

RUN sudo sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin
RUN mkdir -p /tmp
