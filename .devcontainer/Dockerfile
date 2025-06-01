FROM artixlinux/artixlinux:base-runit

# Initialize pacman keyring and update system
RUN pacman-key --init && \
    pacman-key --populate artix && \
    pacman -Sy --noconfirm archlinux-keyring artix-keyring && \
    pacman -Syu --noconfirm

# Install required packages
RUN pacman -S --noconfirm \
    base-devel \
    curl \
    wget \
    tailscale \
    git \
    neovim \
    tmux \
    ripgrep \
    openssh \
    openssl \
    lsof \
    zsh \
    bash \
    sudo \
    nodejs \
    npm \
    tar \
    unzip \
    which \
    && pacman -Scc --noconfirm

RUN useradd -m -s /bin/zsh -G wheel akal && \
    echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER akal
