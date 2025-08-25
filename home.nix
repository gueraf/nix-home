{ config, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;
  targets.genericLinux.enable = true;
  home.username = "fabian";
  home.homeDirectory = "/home/fabian";

  # Do not change!
  home.stateVersion = "23.11";

  home.activation = {
    linkDesktopApplications = {
      after = [ "writeBoundary" "createXdgUserDirectories" ];
      before = [ ];
      data = "/usr/bin/sudo /usr/bin/chmod -R 777 $HOME/.nix-profile/share/applications && if [ -x /usr/bin/update-desktop-database ]; then /usr/bin/update-desktop-database $HOME/.nix-profile/share/applications; fi";
    };
  };

  home.packages = [
    pkgs.tmux
    pkgs.vim
    pkgs.git
    pkgs.git-crecord
    pkgs.jujutsu
    pkgs.htop
    pkgs.gh
    pkgs.hatch

    pkgs.bash-preexec
    pkgs.atuin
    # pkgs.mysql-workbench
    # pkgs.vscode
    # pkgs.vscode-extensions.ms-python.python
    # pkgs.vscode-extensions.bazelbuild.vscode-bazel
    # pkgs.vscode-extensions.ms-toolsai.jupyter
    # pkgs.vscode-extensions.ms-kubernetes-tools.vscode-kubernetes-tools

    pkgs.bazel-watcher
    pkgs.bazel-buildtools

    # pkgs.wl-clipboard

    pkgs.kubernetes
    # pkgs.kubernetes-helm
    # pkgs.krew
    # pkgs.openfortivpn
    # pkgs.ookla-speedtest

    # pkgs.slack

    # pkgs.go
    pkgs.bmon
    pkgs.bazel-buildtools
    pkgs.bazelisk

    pkgs.uv
    pkgs.azure-cli
    pkgs.google-cloud-sdk
    pkgs.kubelogin
  ];

  home.file = {
    ".bash_profile".source = ./dotfiles/bash_profile;
    ".bashrc".source = ./dotfiles/bashrc;
    ".bash_tmux".source = ./dotfiles/bash_tmux;
    ".bash-preexec.sh".source = ./dotfiles/bash-preexec.sh;
    ".tmux.conf".source = ./dotfiles/tmux_conf;
    ".jupyter/jupyter_notebook_config.py".source = ./dotfiles/jupyter_jupyter_config.py;
    ".jupyter/jupyter_server_config.py".source = ./dotfiles/jupyter_jupyter_config.py; 
  };

  programs.home-manager.enable = true;
}
