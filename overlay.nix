{ nixpkgs-20191230 }:

final: prev:

let
  inherit (prev) lib;

  flattenVersion = lib.replaceStrings [ "." ] [ "_" ];
  readPackageMetadata = path: builtins.fromJSON (builtins.readFile path);

  arch = prev.stdenv.hostPlatform.uname.processor;

  # Supported manylinux versions are discovered from `metadata/`. Each
  # directory `metadata/X.Y` contains the package metadata for one manylinux
  # version, with one `<arch>.json` file per supported architecture (generated
  # by `scripts/rhel2nix.py`). Version `X.Y` is exposed as the `manylinux_X_Y`
  # package set.
  versions = lib.attrNames (
    lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./metadata)
  );

  mkManylinuxPackages = final.callPackage ./manylinux { inherit nixpkgs-20191230; };
in
lib.listToAttrs (
  map (version: {
    name = "manylinux_${flattenVersion version}";
    value = mkManylinuxPackages {
      packageMetadata = readPackageMetadata ./metadata/${version}/${arch}.json;
    };
  }) versions
)
