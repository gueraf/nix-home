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
# cd /nfs/home/gmi/fabian/
gh repo clone gueraf/nix-home
ln -s ~/nix-home ~/.config/nixpkgs
# ln -s /nfs/home/gmi/fabian/nix-home ~/.config/nixpkgs
```

```sh
$HOME/.nix-profile/bin/home-manager switch -f ~/nix-home/home.nix
```

```sh
echo "export XDG_DATA_DIRS="/home/fabian/.nix-profile/share:$XDG_DATA_DIRS" > ~/.profile
```
