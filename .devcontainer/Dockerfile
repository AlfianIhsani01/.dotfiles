FROM ghcr.io/void-linux/void-musl-full:20250601r1
RUN xbps-install -Syu xbps && xbps-install -y \
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
    bash \
    sudo \
    which \
    && xbps-remove -O

# COPY ./utils.sh /utils.sh
# RUN chmod +x /utils.sh

COPY ./setup.sh /setup.sh
RUN chmod +x /setup.sh
RUN /setup.sh

ENTRYPOINT ["/usr/local/share/ssh-init.sh"]

# RUN useradd -m -G wheel akal && \
#     echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
# USER akal
