{ lib, pkgs }:

# Tests for the wheel hooks.

let
  hooks = import ../. { inherit lib pkgs; };

  # Wheel built with the standard nixpkgs stdenv, so must fail
  # compliance check.
  nonCompliantWheel = pkgs.python3Packages.buildPythonPackage {
    pname = "noncompliant";
    version = "0";
    pyproject = true;
    src = ./non-compliant;
    build-system = [ pkgs.python3Packages.setuptools ];
    nativeBuildInputs = [ hooks.manylinuxAuditWheelHook ];
    doCheck = false;
  };
in
{
  audit-wheel-hook-rejects-non-compliant = pkgs.testers.testBuildFailure' {
    drv = nonCompliantWheel;
    expectedBuilderExitCode = 2;
    expectedBuilderLogEntries = [ "too-recent versioned symbols" ];
  };
}
