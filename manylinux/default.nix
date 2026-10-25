{
  lib,
  callPackage,
  newScope,
  pkgs,

  # Source of nixpkgs from around the time glibc 2.28 was released, used
  # to build a glibc that matches the manylinux_2_28 baseline.
  nixpkgs-20191230,
}:

{
  packageMetadata,
}:

let
  patchelf-old = callPackage ./patchelf-old.nix { };

  fixedPoint = final: {
    inherit lib;
  };
  composed = lib.composeManyExtensions [
    # Base package set.
    (import ./components.nix { inherit packageMetadata patchelf-old; })

    # Package-specific overrides.
    (import ./overrides.nix)

    # Unwrapped gcc (gcc13-unwrapped, gcc14-unwrapped, etc.)
    (import ./gcc-unwrapped.nix)

    # stdenvs (gcc13Stdenv, gcc14Stdenv, etc.)
    (import ./stdenv.nix { inherit pkgs nixpkgs-20191230; })

    # Use the gcc14 stdenv by default.
    (final: prev: { stdenv = final.gcc14Stdenv; })
  ];
in
lib.makeScope newScope (lib.extends composed fixedPoint)
