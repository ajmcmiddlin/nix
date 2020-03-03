#! /usr/bin/env nix-shell
#! nix-shell -p nix-prefetch-git -i bash
nix-prefetch-git /home/andrew/git/nix $1 > /etc/nixos/thunk.json
