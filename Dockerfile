FROM node:18-bullseye

ARG USERNAME=node
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    bash-completion \
    ca-certificates \
    curl \
    git \
    gnupg \
    htop \
    iptables \
    jq \
    less \
    lsb-release \
    net-tools \
    openssh-client \
    procps \
    ripgrep \
    sudo \
    tmux \
    tzdata \
    unzip \
    vim \
    wget \
    xauth \
    zsh

# Install Claude Code CLI
RUN npm install -g @anthropic/claude-code

# Install GitHub CLI for PR creation
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh

# Add firewall initialization script
COPY docker/init-firewall.sh /usr/local/bin/init-firewall.sh
RUN chmod +x /usr/local/bin/init-firewall.sh

# Shell configuration
RUN mkdir -p /commandhistory \
    && touch /commandhistory/.bash_history \
    && chown -R $USER_UID:$USER_GID /commandhistory \
    && echo 'export HISTFILE=/commandhistory/.bash_history' >> /home/$USERNAME/.bashrc

# Setup ZSH with Oh My Zsh
RUN chsh -s $(which zsh) $USERNAME
ENV POWERLEVEL9K_DISABLE_GITSTATUS=true

# Create .claude config directory
RUN mkdir -p /home/$USERNAME/.claude \
    && chown -R $USERNAME:$USERNAME /home/$USERNAME/.claude

# Allow node user to run specific commands with sudo
RUN echo "$USERNAME ALL=(ALL) NOPASSWD: /usr/local/bin/init-firewall.sh" | tee -a /etc/sudoers.d/$USERNAME

# Setup global node modules
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$NPM_CONFIG_PREFIX/bin:$PATH
RUN mkdir -p $NPM_CONFIG_PREFIX/lib \
    && chown -R $USERNAME:$USERNAME $NPM_CONFIG_PREFIX

USER $USERNAME
WORKDIR /workspace
CMD ["sleep", "infinity"]