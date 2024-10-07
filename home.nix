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
      data = "/usr/bin/sudo /usr/bin/chmod -R 777 $HOME/.nix-profile/share/applications && /usr/bin/update-desktop-database $HOME/.nix-profile/share/applications";
    };
  };

  home.packages = [
    pkgs.tmux
    pkgs.vim
    pkgs.gedit
    pkgs.sublime
    pkgs.git
    pkgs.git-lfs
    pkgs.git-crecord
    pkgs.htop
    pkgs.gh

    pkgs.atuin

    # pkgs.vscode
    # pkgs.vscode-extensions.ms-python.python
    # pkgs.vscode-extensions.bazelbuild.vscode-bazel
    # pkgs.vscode-extensions.ms-toolsai.jupyter
    # pkgs.vscode-extensions.ms-kubernetes-tools.vscode-kubernetes-tools

    pkgs.bazel_7
    pkgs.bazel-watcher
    pkgs.bazel-buildtools

    pkgs.wl-clipboard

    pkgs.kubernetes
    pkgs.kubernetes-helm
    pkgs.krew
    # pkgs.openfortivpn
    pkgs.ookla-speedtest

    # pkgs.slack

    pkgs.go
    pkgs.bmon
  ];

  home.file = {
    ".bashrc".source = ./dotfiles/bashrc;
    ".bash_tmux".source = ./dotfiles/bash_tmux;
    ".bash-preexec.sh".source = ./dotfiles/bash-preexec.sh;
    ".tmux.conf".source = ./dotfiles/tmux_conf;
    ".kube/config".source = ./dotfiles/kube_config;
    ".jupyter/jupyter_notebook_config.py".source = ./dotfiles/jupyter_jupyter_config.py;
    ".jupyter/jupyter_server_config.py".source = ./dotfiles/jupyter_jupyter_config.py; 
  };

  programs.home-manager.enable = true;
}
