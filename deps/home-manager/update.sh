#! /usr/bin/env nix-shell
#! nix-shell -p nix-prefetch-git -i bash

# Example usage: ./update.sh --rev release-19.03
HERE=$(dirname $0)
nix-prefetch-git https://github.com/rycee/home-manager $1 > $HERE/thunk.json
