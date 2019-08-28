# Nix

This repo contains all of the nix configuration I use to manage my machines.

I have stolen the architecture from [Ben Kolera](https://github.com/benkolera/nix).

You probably don't want to use this repo as-is, but I extend Ben's invitation to take whatever is
useful to you.

## Installation

1. Download `update.sh` in the root of the repository and put it in `/etc/nixos`
2. Download `configuration.nix.example` as `/etc/nixos/configuration.nix`
3. Edit `/etc/nixos/configuration.nix` such that `default.nix` uses the correct machine.
4. Run `sudo nixos-rebuild switch** as normal.

## Machine specific config

**TODO**

## update.sh pattern

There is a common pattern used herein. Whenever we bring in external dependencies, we create a directory with an `update.sh` script. For example:

```nix
#! /usr/bin/env nix-shell
#! nix-shell -p nix-prefetch-git -i bash

# Example usage: ./update.sh --rev release-19.03
HERE=$(dirname $0)
nix-prefetch-git https://github.com/rycee/home-manager $1 > $HERE/thunk.json
```

These scripts run in a nix shell (see the `#!` lines) and prefetch the dependency, putting the
details in a `thunk.json` file. In doing so, `update.sh` may be run to update the details of the git
repository to the desired revision. For example, the above script could be called like so to get the
latest revision of the nixos 19.03 stream:

```sh
$ ./update.sh --rev release-19.03
```

The final piece is a `default.nix` that imports the json and downloads the required resource. Given
this is all nix, if the inputs (e.g. the `thunk.json`) haven't changed, then the result of the
derivation won't change, and nix won't need to do any work.
