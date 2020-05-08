#! /usr/bin/env nix-shell
#! nix-shell -p nix-prefetch-git -i bash

# Example usage: ./update.sh --rev release-19.03
HERE=$(dirname $0)
if (( $# < 1 )); then
  echo "Need to provide release branch as first and only argument --- e.g. release-20.03"
  exit 1
fi

nix-prefetch-git https://github.com/rycee/home-manager --rev refs/heads/${1} > $HERE/thunk-temp.json

# Cry deeply.
head -n 2 $HERE/thunk-temp.json > $HERE/thunk.json
echo "  \"ref\": \"refs/heads/${1}\"," >> $HERE/thunk.json
tail -n +3 $HERE/thunk-temp.json >> $HERE/thunk.json
rm $HERE/thunk-temp.json

