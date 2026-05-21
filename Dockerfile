ARG TARGETARCH=amd64
FROM --platform=linux/${TARGETARCH} nvidia/cuda:12.9.1-devel-ubuntu24.04
EXPOSE 22
ENV CUDA_HOME=/usr/local/cuda-12.9/
ENV CUDA_LIB_PATH=/usr/local/cuda-12.9/lib64

# RUN ulimit -l unlimited
RUN echo "* soft memlock unlimited" | tee /etc/security/limits.conf
RUN echo "* hard memlock unlimited" | tee /etc/security/limits.conf

# Install app dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ca-certificates \
    cmake \
    curl \
    dnsutils \
    git \
    iproute2 \
    iputils-ping \
    ipython3 \
    less \
    npm \
    nvtop \
    parallel \
    pipx \
    pigz \
    python3 \
    python-is-python3 \
    python3-nbformat \
    python3-pip \
    software-properties-common \
    sudo \
    telnet \
    time \
    tini \
    tmux \
    traceroute \
    vim \
    openssh-server \
    unzip \
    wget \
    zip \
    zstd \
    zlib1g-dev && \
    apt clean

# Configure SSH
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Install docker (https://docs.docker.com/engine/install/ubuntu/)
RUN curl -fsSL https://get.docker.com -o get-docker.sh && \
    sh get-docker.sh && \
    rm get-docker.sh && \
    groupadd docker || true

# GCP repo
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

# Initialize jupyter
# RUN jupyter nbextension enable --py --sys-prefix widgetsnbextension

RUN curl -fSsL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/3bf863cc.pub | gpg --dearmor | tee /usr/share/keyrings/nvidia-drivers.gpg > /dev/null 2>&1
RUN echo 'deb [signed-by=/usr/share/keyrings/nvidia-drivers.gpg] https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/ /' | tee /etc/apt/sources.list.d/cuda.list
# RUN echo 'deb [signed-by=/usr/share/keyrings/nvidia-drivers.gpg] https://developer.download.nvidia.com/devtools/repos/ubuntu2404/x86_64/ /' | tee /etc/apt/sources.list.d/nvidia-devtools.list

# Add repo for vscode
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg && \
    install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg && \
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | tee /etc/apt/sources.list.d/vscode.list > /dev/null && \
    rm -f packages.microsoft.gpg

# Install GitHub CLI
RUN (type -p wget >/dev/null || (apt update && apt install wget -y)) && \
    mkdir -p -m 755 /etc/apt/keyrings && \
    wget -nv -O /tmp/githubcli-archive-keyring.gpg https://cli.github.com/packages/githubcli-archive-keyring.gpg && \
    cat /tmp/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null && \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    mkdir -p -m 755 /etc/apt/sources.list.d && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    rm /tmp/githubcli-archive-keyring.gpg

RUN apt-get update && \
    apt-get install -y \
    code \
    gh \
    google-cloud-cli \
    google-cloud-sdk-gke-gcloud-auth-plugin
RUN apt clean

# RUN sudo npm install -g @bazel/bazelisk

# Add Tini (to avoid zombie processes, e.g. from bazel)
ENV TINI_VERSION="v0.19.0"
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

# Create fabian user or rename it, if it exists.
# RUN if cat /etc/passwd | grep 1000; then \
#     usermod -l fabian -d /home/fabian -m $(cat /etc/passwd | grep 1000 | grep -oP "^[^:]+") --shell /bin/bash --password ""; \
#     echo foo; \
#     else \
#     useradd --shell /bin/bash --password "" --home /home/fabian fabian; \
#     fi
RUN useradd --uid 1010 --shell /bin/bash --password "" --home /home/fabian fabian && \
    echo "fabian ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN mkdir -p /home/fabian/ && chown fabian /home/fabian/ && \
    mkdir -p /home/fabian/.ssh && \
    chown fabian:fabian /home/fabian/.ssh && \
    chmod 700 /home/fabian/.ssh

COPY . /home/fabian/nix_home
RUN chown -R fabian /home/fabian/nix_home
USER fabian
# Home manager needs the USER env variable to be set... :(
ENV USER=fabian

# Install nix
# RUN curl -L https://nixos.org/nix/install | /bin/bash
RUN wget https://nixos.org/nix/install -O /tmp/nix.sh && \
    chmod +x /tmp/nix.sh && \
    ./tmp/nix.sh && \
    rm /tmp/nix.sh

RUN . $HOME/.nix-profile/etc/profile.d/nix.sh && \
    $HOME/.nix-profile/bin/nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager && \
    $HOME/.nix-profile/bin/nix-channel --update && \
    $HOME/.nix-profile/bin/nix-shell '<home-manager>' -A install && \
    rm -f ~/.bashrc && \
    rm -rf ~/.cache && \
    $HOME/.nix-profile/bin/home-manager switch -f /home/fabian/nix_home/home.nix && \
    atuin init bash >> /home/fabian/nix_home/dotfiles/bashrc && \
    $HOME/.nix-profile/bin/home-manager switch -f /home/fabian/nix_home/home.nix && \
    $HOME/.nix-profile/bin/nix-collect-garbage --delete-old

RUN git config --global pull.rebase true
RUN git config --global core.editor "vim"
RUN git config --global user.name "Fabian Guera" && \
    git config --global user.email "fabian@odyssey.systems"
RUN $HOME/.nix-profile/bin/jj config set --user user.name "Fabian Guera" && \
    $HOME/.nix-profile/bin/jj config set --user user.email "fabian@odyssey.systems" && \
    $HOME/.nix-profile/bin/jj config set --user ui.default-command log && \
    $HOME/.nix-profile/bin/jj config set --user ui.editor vim

RUN pipx install huggingface_hub[cli] ninja
RUN sudo npm install -g @github/copilot

RUN sudo usermod -aG docker $USER || true && \
    sudo newgrp docker || true

# RUN sudo chmod u+s $(which nsys) && \
#     sudo chmod u+s $(which ncu)

RUN cd /tmp/ && \
    if [ "${TARGETARCH}" = "amd64" ]; then \
        wget https://github.com/glotlabs/gdrive/releases/download/3.9.1/gdrive_linux-x64.tar.gz && \
        tar -xz < gdrive_linux-x64.tar.gz && \
        sudo mv gdrive /bin/ && \
        rm gdrive_linux-x64.tar.gz; \
    elif [ "${TARGETARCH}" = "arm64" ]; then \
        wget https://raw.githubusercontent.com/AnimMouse/gdrive-binaries/master/linux/gdrive-linux-arm64 && \
        sudo mv gdrive-linux-arm64 /bin/gdrive && \
        sudo chmod +x /bin/gdrive; \
    fi

ENTRYPOINT ["/tini", "--"]
CMD ["/bin/bash", "-c", "service ssh start && tmux new -s main -d; sleep infinity"]
