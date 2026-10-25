{
  description = "Nix overlay for building manylinux-compatible binaries";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";

    # nixpkgs from around the time glibc 2.28 was released. Used to build a
    # glibc 2.28, which fails to build with current compilers.
    nixpkgs-20191230 = {
      url = "github:NixOS/nixpkgs/a9eb3eed170fa916e0a8364e5227ee661af76fde";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-20191230,
    }:
    let
      inherit (nixpkgs) lib;

      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = lib.genAttrs systems;

      overlay = import ./overlay.nix { inherit nixpkgs-20191230; };

      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        };
    in
    {
      overlays.default = overlay;

      legacyPackages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          inherit (pkgs) manylinux_2_28;
        }
      );

      checks = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        import ./tests { inherit (pkgs) lib manylinux_2_28; }
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
    };
}
