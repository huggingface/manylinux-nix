{
  pkgs,
  manylinux_2_28,
  hooks,
}:

let
  python3Packages = pkgs.python3Packages;

  buildPythonPackage = python3Packages.buildPythonPackage.override {
    inherit (manylinux_2_28) stdenv;
  };

  # Extended test vectors for the test suite (pure Python).
  test-vectors = python3Packages.buildPythonPackage rec {
    pname = "pycryptodome-test-vectors";
    version = "1.0.14";
    pyproject = true;

    src = pkgs.fetchPypi {
      inherit pname version;
      hash = "sha256-1De0SjXcr8BibDVhv7G1BqG3x0RcxfudNuI3QWG8mjc=";
      extension = "zip";
    };

    build-system = [ python3Packages.setuptools ];

    doCheck = false;
  };
in
buildPythonPackage (finalAttrs: {
  pname = "pycryptodome";
  version = "3.23.0";
  pyproject = true;

  src = pkgs.fetchFromGitHub {
    owner = "Legrandin";
    repo = "pycryptodome";
    tag = "v${finalAttrs.version}";
    hash = "sha256-x8QkRBwM/H/n7yHGjE8UfBhOzkGr0PBixe9g4EuZLUg=";
  };

  build-system = [ python3Packages.setuptools ];

  nativeBuildInputs = [
    # Keep hooks in this order.
    hooks.manylinuxRemoveWheelRpathHook
    hooks.manylinuxAuditWheelHook
  ];

  pythonImportsCheck = [ "Crypto" ];

  checkInputs = [ test-vectors ];

  checkPhase = ''
    runHook preCheck

    grep -q -- '-abi3-' $out/${pkgs.python3.sitePackages}/*.dist-info/WHEEL || {
      echo "error: wheel is not an abi3 wheel" >&2
      exit 1
    }

    python -m Crypto.SelfTest

    runHook postCheck
  '';
})
