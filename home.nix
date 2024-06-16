{ config, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  home.username = "fabian";
  home.homeDirectory = "/home/fabian";

  # Do not change!
  home.stateVersion = "23.11";

  home.packages = [
    pkgs.home-manager

    pkgs.tmux
    pkgs.vim
    pkgs.gedit
    pkgs.sublime
    pkgs.git
    pkgs.htop

    pkgs.vscode
    pkgs.vscode-extensions.ms-python.python
    pkgs.vscode-extensions.bazelbuild.vscode-bazel

    pkgs.bazel
    pkgs.bazel-watcher
    pkgs.bazel-buildtools

    pkgs.kubernetes
    pkgs.kubernetes-helm
    pkgs.openfortivpn
  ];

  home.file = {
    ".bashrc".source = ./dotfiles/bashrc;
    ".bash_tmux".source = ./dotfiles/bash_tmux;
    ".tmux.conf".source = ./dotfiles/tmux_conf;
  };

  programs.home-manager.enable = true;
}
