{ packageMetadata, patchelf-old }:

final: prev:

prev.lib.mapAttrs (
  pname: metadata:
  final.callPackage ./generic.nix {
    inherit pname patchelf-old;
    inherit (metadata) components deps version;
    manylinuxPackages = final;
  }
) packageMetadata
