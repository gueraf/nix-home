{ config, pkgs, lib, ... }:

let
  username = builtins.getEnv "USER";
  tabbyTerminal = let
    version = "1.0.238";
    src = if pkgs.stdenv.hostPlatform.isAarch64 then
      pkgs.fetchurl {
        url = "https://github.com/Eugeny/tabby/releases/download/v${version}/tabby-${version}-linux-arm64.deb";
        sha256 = "1l1pl73rvk8xsp17wki0x8rlvsz24cik9ajkwbsdkqdqala3i7m7";
      }
    else
      pkgs.fetchurl {
        url = "https://github.com/Eugeny/tabby/releases/download/v${version}/tabby-${version}-linux-x64.deb";
        sha256 = "070x5njk07rdpx98paalcb4liplj7nyr8znbk35wvdgjhjmbk8jy";
      };
  in pkgs.stdenv.mkDerivation {
    pname = "tabby-terminal";
    inherit version src;

    nativeBuildInputs = [
      pkgs.dpkg
      pkgs.autoPatchelfHook
      pkgs.makeWrapper
    ];

    buildInputs = [
      pkgs.alsa-lib
      pkgs.at-spi2-atk
      pkgs.at-spi2-core
      pkgs.brotli
      pkgs.bzip2
      pkgs.cairo
      pkgs.cups
      pkgs.dbus
      pkgs.expat
      pkgs.fontconfig
      pkgs.freetype
      pkgs.gdk-pixbuf
      pkgs.glib
      pkgs.gtk3
      pkgs.libdrm
      pkgs.libglvnd
      pkgs.libnotify
      pkgs.libpng
      pkgs.libsecret
      pkgs.libx11
      pkgs.libxcb
      pkgs.libxcomposite
      pkgs.libxdamage
      pkgs.libxext
      pkgs.libxfixes
      pkgs.libxkbcommon
      pkgs.libxrandr
      pkgs.libxtst
      pkgs.mesa
      pkgs.nspr
      pkgs.nss
      pkgs.pango
      pkgs.stdenv.cc.cc.lib
      pkgs.systemd
      pkgs.vulkan-loader
      pkgs.zlib
    ];

    unpackPhase = "dpkg-deb -x $src .";

    installPhase = ''
      runHook preInstall

      mkdir -p $out/opt $out/bin $out/share
      cp -r opt/Tabby $out/opt/Tabby
      cp -r usr/share/* $out/share/

      find $out/opt/Tabby -path "*/prebuilds/*" -type f ! -path "*/prebuilds/${if pkgs.stdenv.hostPlatform.isAarch64 then "linux-arm64" else "linux-x64"}/*" -delete
      find $out/opt/Tabby -name "*.musl.node" -delete
      find $out/opt/Tabby -name "russh.*.node" ! -name "russh.${if pkgs.stdenv.hostPlatform.isAarch64 then "linux-arm64-gnu" else "linux-x64-gnu"}.node" -delete

      makeWrapper $out/opt/Tabby/tabby $out/bin/tabby \
        --add-flags "--no-sandbox --ozone-platform=x11" \
        --set-default LIBGL_DRIVERS_PATH "${pkgs.mesa}/lib/dri" \
        --set-default GBM_BACKENDS_PATH "${pkgs.mesa}/lib/gbm" \
        --set-default __EGL_VENDOR_LIBRARY_DIRS "${pkgs.mesa}/share/glvnd/egl_vendor.d" \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ pkgs.libglvnd pkgs.vulkan-loader pkgs.mesa pkgs.systemd ]}"

      substituteInPlace $out/share/applications/tabby.desktop \
        --replace-fail "/opt/Tabby/tabby" "$out/bin/tabby"

      runHook postInstall
    '';
  };
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
    tabbyTerminal
    (pkgs.writeShellScriptBin "xdg-open" ''
      if [ -n "''${WAYLAND_DISPLAY:-}" ] && [ -z "''${XDG_ACTIVATION_TOKEN:-}" ] && [ -x /usr/bin/python3 ]; then
        token="$(env -u LD_LIBRARY_PATH GDK_BACKEND=wayland /usr/bin/python3 -c '
import ctypes
try:
    gdk = ctypes.CDLL("libgdk-3.so.0")
    gio = ctypes.CDLL("libgio-2.0.so.0")
    wl = ctypes.CDLL("libwayland-client.so.0")
    gdk.gdk_init(ctypes.byref(ctypes.c_int(0)), None)
    gdk.gdk_display_get_default.restype = ctypes.c_void_p
    d = gdk.gdk_display_get_default()
    if d:
        ctypes.c_void_p.from_address(d + 0x160).value = 0
        gdk.gdk_display_get_app_launch_context.argtypes = [ctypes.c_void_p]
        gdk.gdk_display_get_app_launch_context.restype = ctypes.c_void_p
        ctx = gdk.gdk_display_get_app_launch_context(d)
        gio.g_app_launch_context_get_startup_notify_id.argtypes = [
            ctypes.c_void_p, ctypes.c_void_p, ctypes.c_void_p
        ]
        gio.g_app_launch_context_get_startup_notify_id.restype = ctypes.c_char_p
        token_bytes = gio.g_app_launch_context_get_startup_notify_id(ctx, None, None)
        if token_bytes:
            gdk.gdk_wayland_display_get_wl_display.argtypes = [ctypes.c_void_p]
            gdk.gdk_wayland_display_get_wl_display.restype = ctypes.c_void_p
            wl_d = gdk.gdk_wayland_display_get_wl_display(d)
            if wl_d:
                wl.wl_display_roundtrip.argtypes = [ctypes.c_void_p]
                wl.wl_display_roundtrip(wl_d)
            print(token_bytes.decode("utf-8", errors="ignore"))
except Exception:
    pass
' 2>/dev/null)"
        if [ -n "$token" ]; then
          export XDG_ACTIVATION_TOKEN="$token"
          export DESKTOP_STARTUP_ID="$token"
        fi
      fi
      unset LD_LIBRARY_PATH
      exec /usr/bin/xdg-open "$@"
    '')
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
    ".config/tabby/plugins/node_modules/tabby-startup-tabs/package.json".source = ./dotfiles/tabby_startup_tabs_package.json;
    ".config/tabby/plugins/node_modules/tabby-startup-tabs/index.js".source = ./dotfiles/tabby_startup_tabs_index.js;
    ".claude/settings.json".source = ./dotfiles/claude_settings.json;
    ".local/bin/git-pclone" = { source = ./dotfiles/git-pclone; executable = true; };
  };

  home.activation.installTabbyConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.coreutils}/bin/mkdir -p "$HOME/.config/tabby"
    ${pkgs.coreutils}/bin/install -m 644 ${./dotfiles/tabby_config.yaml} "$HOME/.config/tabby/config.yaml"
  '';

  home.activation.addGitCorePpa = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export PATH="/usr/bin:/usr/sbin:/bin:/sbin:$PATH"
    if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null && command -v add-apt-repository >/dev/null 2>&1; then
      if ! grep -r "git-core" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null | grep -q "git-core"; then
        echo "Adding git-core PPA for latest stable git..."
        sudo add-apt-repository -y ppa:git-core/ppa
        sudo apt-get update -qq
      fi
    fi
  '';

  home.activation.installExternalCliTools = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -e
    state_dir="$HOME/.local/state/nix-home"
    ${pkgs.coreutils}/bin/mkdir -p "$state_dir"

    install_cli() {
      marker="$1"
      url="$2"

      if [ -f "$state_dir/$marker" ]; then
        return
      fi

      echo "Installing CLI from $url"
      (
        set -e
        export PATH="${lib.makeBinPath [
          pkgs.bash
          pkgs.coreutils
          pkgs.curl
          pkgs.findutils
          pkgs.gnugrep
          pkgs.gnused
          pkgs.gnutar
          pkgs.gzip
          pkgs.unzip
          pkgs.xz
        ]}:$PATH"
        tmp_dir="$(${pkgs.coreutils}/bin/mktemp -d)"
        trap '${pkgs.coreutils}/bin/rm -rf "$tmp_dir"' EXIT
        tmp_script="$tmp_dir/install.sh"
        ${pkgs.curl}/bin/curl -fsSL "$url" -o "$tmp_script"
        ${pkgs.bash}/bin/bash "$tmp_script"
      ) || return 1
      ${pkgs.coreutils}/bin/touch "$state_dir/$marker"
      echo "Installed CLI from $url"
    }

    install_cli "antigravity-cli-installed" "https://antigravity.google/cli/install.sh"
    install_cli "claude-cli-installed" "https://claude.ai/install.sh"
  '';

  programs.home-manager.enable = true;
}
