{ lib, pkgs }:

let
  python = pkgs.python3;

  arch = pkgs.stdenv.hostPlatform.uname.processor;
in
{
  # Remove the RPATH of shared objects in wheels in `dist/`.
  manylinuxRemoveWheelRpathHook = pkgs.makeSetupHook {
    name = "manylinux-remove-wheel-rpath-hook";
    substitutions = {
      patchelf = lib.getExe pkgs.patchelf;
      wheel = lib.getExe python.pkgs.wheel;
    };
  } ./remove-wheel-rpath-hook.sh;

  # Audit the wheels in `dist/` for manylinux compliance and give them the
  # manylinux platform tag. Must be used after `manylinuxRemoveWheelRpathHook`.
  manylinuxAuditWheelHook = pkgs.makeSetupHook {
    name = "manylinux-audit-wheel-hook";
    substitutions = {
      auditwheel = lib.getExe pkgs.auditwheel;
      binutils = "${pkgs.binutils}";
      patchelf = lib.getExe pkgs.patchelf;
      platform = "manylinux_2_28_${arch}";
      unzip = lib.getExe pkgs.unzip;
    };
  } ./audit-wheel-hook.sh;
}
