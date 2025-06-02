FROM ghcr.io/void-linux/void-musl-full:20250601r1
RUN xbps-install -Syu && xbps-install -y \
    base-devel \
    curl \
    wget \
    iptables \
    tailscale \
    git \
    neovim \
    tmux \
    ripgrep \
    findutils \
    openssh \
    openssl \
    lsof \
    zsh \
    bash \
    sudo \
    shadow \
    tar \
    unzip \
    which \
    && xbps-remove -O

RUN useradd -m -G wheel akal && \
    echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER akal
