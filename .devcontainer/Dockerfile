FROM fedora:latest

LABEL description="Fedora dev container with SSH and dev tools"

RUN dnf update -y && \
    dnf install -y \
    curl \
    wget \
    iptables \
    tailscale \
    git \
    neovim \
    tmux \
    ripgrep \
    findutils \
    openssh-server \
    openssh-clients \
    openssl \
    lsof \
    bash \
    sudo \
    which && \
    dnf clean all

COPY ./setup.sh /setup.sh
RUN chmod +x /setup.sh && /setup.sh

USER akal
ENTRYPOINT ["/usr/local/share/ssh-init.sh"]
