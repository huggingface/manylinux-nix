{ patchelf }:

# Temporary: revert patchelf 0.15.2 -> 0.19.2 (NixOS/nixpkgs#569010), which
# causes segfaults (e.g. cc1plus) in binaries patched by autoPatchelfHook.
# Remove once nixpkgs ships a fixed patchelf. Can possibly be removed once
# https://github.com/NixOS/patchelf/pull/672 propagates to the channels.
(patchelf.override (old: {
  fetchurl =
    args: old.fetchurl (args // { hash = "sha256-F3RfVkFZyOIo/EEtplogSLhGxLa0Igt3y/IkFuAvLXw="; });
})).overrideAttrs
  {
    version = "0.15.2";
    __intentionallyOverridingVersion = true;
  }
