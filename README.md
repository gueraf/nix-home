# Preparation

```sh
curl -L https://nixos.org/nix/install | sh
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install
```

```sh
cs ~
gh repo clone gueraf/nix-home
cd ~/.config
ln -s ~/nix-home nixpkgs
```