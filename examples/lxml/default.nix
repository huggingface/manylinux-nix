{
  pkgs,
  manylinux_2_28,
  hooks,
}:

let
  inherit (manylinux_2_28) stdenv;

  python3Packages = pkgs.python3Packages;

  buildPythonPackage = python3Packages.buildPythonPackage.override { inherit stdenv; };

  # Use statically linked libxmlt, libxslt, and zlib.
  libxml2 =
    (pkgs.libxml2.override {
      inherit stdenv zlib;
      enableShared = false;
      enableStatic = true;
      zlibSupport = true;
    }).overrideAttrs
      {
        # The test suite expects shared libraries (module loading).
        doCheck = false;
      };

  libxslt =
    (pkgs.libxslt.override {
      inherit stdenv libxml2;
      pythonSupport = false;
      cryptoSupport = false;
    }).overrideAttrs
      (prevAttrs: {
        # libxml2.pc requires zlib.
        buildInputs = prevAttrs.buildInputs ++ [ zlib.dev ];

        configureFlags = prevAttrs.configureFlags ++ [
          "--enable-static"
          "--disable-shared"
          "--with-pic"
        ];
      });

  zlib = pkgs.zlib.override {
    inherit stdenv;
    shared = false;
    splitStaticOutput = false;
  };
in
buildPythonPackage (finalAttrs: {
  pname = "lxml";
  version = "6.1.3";
  pyproject = true;

  src = pkgs.fetchFromGitHub {
    owner = "lxml";
    repo = "lxml";
    tag = "lxml-${finalAttrs.version}-1";
    hash = "sha256-n+MBUmoky6VTjU7H6+Gp0mxPeZIwK7uB6/RUOjvq0SU=";
  };

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail "Cython>=3.2.9,<3.3" "Cython>=3.2.9"
  '';

  build-system = [
    python3Packages.cython
    python3Packages.setuptools
  ];

  nativeBuildInputs = [
    pkgs.pkg-config
    libxml2.dev
    libxslt.dev

    # Keep hooks in this order.
    hooks.manylinuxRemoveWheelRpathHook
    hooks.manylinuxAuditWheelHook
  ];

  buildInputs = [
    libxml2
    libxslt
    zlib
  ];

  # In a static build, lxml ships the headers of the libraries in the wheel and
  # creates files in the include directories. So, they have to be writable.
  preBuild = ''
    mkdir static-include-libxml2 static-include-libxslt
    cp -r ${libxml2.dev}/include/libxml2/. static-include-libxml2/
    cp -r ${libxslt.dev}/include/. static-include-libxslt/
    chmod -R u+w static-include-libxml2 static-include-libxslt

    export LXML_STATIC_INCLUDE_DIRS="$PWD/static-include-libxml2:$PWD/static-include-libxslt"
  '';

  env = {
    STATIC = "true";
    LXML_STATIC_LIBRARY_DIRS = "${zlib.out}/lib";
    LXML_STATIC_BINARIES = "${libxslt.out}/lib/libexslt.a:${libxslt.out}/lib/libxslt.a:${libxml2.out}/lib/libxml2.a";
  };

  pythonImportsCheck = [
    "lxml"
    "lxml.etree"
  ];

  # The tests are meant to be run in-place, in the same directory as src.
  doCheck = false;
})
