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
    pkgs.htop
    pkgs.gh

    # pkgs.vscode
    # pkgs.vscode-extensions.ms-python.python
    # pkgs.vscode-extensions.bazelbuild.vscode-bazel
    # pkgs.vscode-extensions.ms-toolsai.jupyter
    # pkgs.vscode-extensions.ms-kubernetes-tools.vscode-kubernetes-tools

    pkgs.bazel
    pkgs.bazel-watcher
    pkgs.bazel-buildtools

    pkgs.kubernetes
    pkgs.kubernetes-helm
    # pkgs.openfortivpn
    pkgs.ookla-speedtest

    # pkgs.slack
  ];

  home.file = {
    ".bashrc".source = ./dotfiles/bashrc;
    ".bash_tmux".source = ./dotfiles/bash_tmux;
    ".tmux.conf".source = ./dotfiles/tmux_conf;
  };

  programs.home-manager.enable = true;
}
