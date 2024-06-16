# Setup
```sh
curl -L https://nixos.org/nix/install | sh
. /home/fabian/.nix-profile/etc/profile.d/nix.sh
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install
```

```sh
cd ~
gh repo clone gueraf/nix-home
cd ~/.config
ln -s ~/nix-home ~/.config/nixpkgs
```

```sh
home-manager switch -f ~/nix-home/home.nix
```

