{ lib, manylinux_2_28 }:

# Check that binaries built with the manylinux stdenv do not require symbol
# versions newer than what manylinux_2_28 guarantees.

let
  # Maximum symbol versions allowed by manylinux_2_28.
  maxVersions = {
    GLIBC = "2.28";
    GLIBCXX = "3.4.24";
    CXXABI = "1.3.11";
    GCC = "7.0.0";
  };

  mkSymbolCheck =
    {
      name,
      source,
      stdenv,
    }:
    stdenv.mkDerivation {
      pname = "manylinux-symbol-check-${name}";
      version = "0";

      dontUnpack = true;

      buildPhase = ''
        runHook preBuild

        $CXX -std=c++17 -O1 ${source} -o program
        $CXX -std=c++17 -O1 -shared -fPIC ${source} -o libprogram.so

        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall

        check_max_version() {
          local file=$1 prefix=$2 max=$3

          # Only versions of undefined (imported) symbols matter.
          local found
          found=$(objdump -T "$file" \
            | grep -F '*UND*' \
            | grep -oE "[( ]''${prefix}_[0-9][0-9.]*" \
            | sed -E "s/^[( ]''${prefix}_//" \
            | sort -uV \
            | tail -n1 || true)

          echo "$file: highest $prefix version: ''${found:-none} (max: $max)"

          if [ -n "$found" ] && \
             [ "$(printf '%s\n%s\n' "$found" "$max" | sort -V | tail -n1)" != "$max" ]; then
            echo "error: $file requires ''${prefix}_$found, newer than ''${prefix}_$max" >&2
            return 1
          fi
        }

        for file in program libprogram.so; do
          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (prefix: max: "check_max_version $file ${prefix} ${max}") maxVersions
          )}
        done

        touch $out

        runHook postInstall
      '';
    };

  mkChecks =
    manylinux:
    let
      inherit (manylinux) stdenv;
    in
    {
      symbols-basic = mkSymbolCheck {
        name = "basic";
        source = ./basic.cpp;
        inherit stdenv;
      };

      # std::to_chars for floating point requires GLIBCXX_3.4.29 from the
      # system libstdc++. The toolset statically links these symbols, so
      # the resulting binaries must still be within the limits.
      symbols-newer-libstdcxx = mkSymbolCheck {
        name = "newer-libstdcxx";
        source = ./newer-libstdcxx.cpp;
        inherit stdenv;
      };
    };
in
mkChecks manylinux_2_28
