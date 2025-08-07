FROM nvidia/cuda:12.6.3-devel-ubuntu24.04
ENV CUDA_HOME=/usr/local/cuda-12.6/
ENV CUDA_LIB_PATH=/usr/local/cuda-12.6/lib64
# FROM nvidia/cuda:12.9.1-devel-ubuntu24.04

# RUN ulimit -l unlimited
RUN echo "* soft memlock unlimited" | tee /etc/security/limits.conf
RUN echo "* hard memlock unlimited" | tee /etc/security/limits.conf

# Install app dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    7zip \
    aria2 \
    ca-certificates \
    curl \
    dnsutils \
    git \
    git-crecord \
    iproute2 \
    iputils-ping \
    ipython3 \
    jupyter-nbconvert \
    jupyter-notebook \
    less \
    npm \
    nvtop \
    parallel \
    pipx \
    perftest \
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
    unzip \
    wget \
    zip \
    zstd && \
    apt clean

# Install docker (https://docs.docker.com/engine/install/ubuntu/)
RUN curl -fsSL https://get.docker.com -o get-docker.sh && \
    sudo sh get-docker.sh && \
    rm get-docker.sh && \
    sudo groupadd docker || true && \
    sudo usermod -aG docker $USER || true && \
    newgrp docker || true

# Initialize jupyter
RUN jupyter nbextension enable --py --sys-prefix widgetsnbextension

# Add repo for nsight profiler
RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub && \
    apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/3bf863cc.pub
RUN export ARCH=$(dpkg --print-architecture) && \
    export REL=$(. /etc/lsb-release; echo "$DISTRIB_RELEASE" | tr -d .) && \
    add-apt-repository "deb https://developer.download.nvidia.com/devtools/repos/ubuntu$REL/$ARCH/ /"

# Add repo for vscode
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg && \
    install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg && \
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | tee /etc/apt/sources.list.d/vscode.list > /dev/null && \
    rm -f packages.microsoft.gpg

RUN apt-get update && \
    apt-get install -y nsight-systems code libcusparselt0 libcusparselt-dev libcudnn9-cuda-12 && \
    apt clean

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
RUN mkdir -p /home/fabian/ && chown fabian /home/fabian/

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
RUN git config --global user.name "Fabian Guera" && \
    git config --global user.email "fabian@odyssey.systems"
RUN $HOME/.nix-profile/bin/jj config set --user user.name "Fabian Guera" && \
    $HOME/.nix-profile/bin/jj config set --user user.email "fabian@odyssey.systems" && \
    $HOME/.nix-profile/bin/jj config set --user ui.default-command log && \
    $HOME/.nix-profile/bin/jj config set --user ui.editor vim

# RUN sudo chmod u+s $(which nsys) && \
#     sudo chmod u+s $(which ncu)

ENTRYPOINT ["/tini", "--"]
CMD ["/bin/bash", "-c", "tmux new -s main -d; sleep infinity"]
