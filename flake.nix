{
  description = "Glimpse shell (unofficial Nix package)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          glimpse = pkgs.callPackage ./package.nix { };
          default = self.packages.${system}.glimpse;
        }
      );

      nixosModules = {
        glimpse = import ./module.nix;
        default = self.nixosModules.glimpse;
      };

      overlays.default = final: prev: {
        glimpse = self.packages.${final.system}.glimpse;
      };
    };
}
