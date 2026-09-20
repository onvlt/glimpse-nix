let
  pkgs = import <nixpkgs> { };
in
{
  glimpse = pkgs.callPackage ./package.nix { };
}
