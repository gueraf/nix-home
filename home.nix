{ config, pkgs, ... }:

{
  home.username = "fabian";
  home.homeDirectory = "/home/fabian";

  # Do not change!
  home.stateVersion = "23.11";

  home.packages = [
    pkgs.tmux
  ];

  home.file = {
    ".bashrc".source = ./dotfiles/bashrc;
    ".bash_tmux".source = ./dotfiles/bash_tmux;
    ".tmux.conf".source = ./dotfiles/tmux_conf;
  };

  programs.home-manager.enable = true;
}
