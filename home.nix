{ config, pkgs, ... }:

let
  username = builtins.getEnv "USER";
in
{
  nixpkgs.config.allowUnfree = true;
  targets.genericLinux.enable = true;
  targets.genericLinux.gpu.enable = !pkgs.stdenv.hostPlatform.isAarch64;
  home.username = username;
  home.homeDirectory = "/home/${username}";

  # Do not change!
  home.stateVersion = "23.11";



  home.packages = [
    # pkgs.tmux  # Installed via APT in once.sh instead
    # pkgs.vim
    # pkgs.git
    # pkgs.git-crecord
    pkgs.jujutsu
    pkgs.htop
    # pkgs.gh  # Installed via APT in Dockerfile instead
    # pkgs.hatch
    pkgs.act

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
    pkgs.k9s
    # pkgs.kubernetes-helm
    # pkgs.krew
    # pkgs.openfortivpn
    # pkgs.ookla-speedtest

    pkgs.slack-cli

    # pkgs.go
    pkgs.bmon
    pkgs.bazelisk

    # pkgs.uv
    # pkgs.azure-cli
    pkgs.kubelogin
    # pkgs.terraform
    pkgs.rclone
  ];

  home.file = {
    ".bash_profile".source = ./dotfiles/bash_profile;
    ".bashrc".source = ./dotfiles/bashrc;
    ".bash_tmux".source = ./dotfiles/bash_tmux;
    ".bash-preexec.sh".source = ./dotfiles/bash-preexec.sh;
    ".tmux.conf".source = ./dotfiles/tmux_conf;
    ".jupyter/jupyter_notebook_config.py".source = ./dotfiles/jupyter_jupyter_config.py;
    ".jupyter/jupyter_server_config.py".source = ./dotfiles/jupyter_jupyter_config.py;
    ".config/k9s/plugins/start_gpu_pod.yaml".source = ./dotfiles/k9s_plugin_start_gpu_pod.yaml;
    ".config/k9s/views.yaml".source = ./dotfiles/k9s_views_pytorchjob.yaml;
    ".config/k9s/plugins/pytorchjob_summary.yaml".source = ./dotfiles/k9s_plugin_pytorchjob_summary.yaml;
    ".claude/settings.json".source = ./dotfiles/claude_settings.json;
  };

  programs.home-manager.enable = true;
}
