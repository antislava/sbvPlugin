{ compilerVersion ? "ghc865" }:
let
  # pinning nixpkgs
  # pkgs = import (fetchGit (import ./version.nix)) { };
  pkgs = import <nixpkgs> { config = { allowBroken = true; }; };
  compiler = pkgs.haskell.packages."${compilerVersion}";
  pkg = compiler.developPackage {
    root = ./.;
    source-overrides = {
    #   HUnit = "1.5.0.0"; # Let's say the GHC 8.4.2 haskellPackages uses 1.6.0.0 and your test suite is incompatible with >= 1.6.0.0
    };
  };
  # in case your package source depends on any libraries directly, not just transitively.
  buildInputs = with pkgs; [ z3 haskellPackages.fast-tags];
in pkg.overrideAttrs(attrs: {
  buildInputs = attrs.buildInputs ++ buildInputs;
})
