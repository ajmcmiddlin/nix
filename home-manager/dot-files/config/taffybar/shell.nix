{ nixpkgs ? <nixpkgs> }:
# Use nixpkgs from channel, as that's what we build our system config with.
let
  pkgs = import nixpkgs {
    overlays = [(import ../../../home-overlays/taffybar/default.nix)];
  };

  ghc = pkgs.haskellPackages.ghcWithPackages (hp: with hp;
    [hp.taffybar]
  );
in
  pkgs.stdenv.mkDerivation {
    name = "andrews-taffybar";
    buildInputs = [ghc];
    shellHook = "eval $(egrep ^export ${ghc}/bin/ghc)";
  }
