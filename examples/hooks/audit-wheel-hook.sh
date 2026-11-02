# Setup hook that audits the wheels in `dist/` with auditwheel and replaces
# them by wheels with the manylinux platform tag. The build fails when:
#
# - The wheel is not compliant with the platform.
# - auditwheel has to bundle external libraries to make the wheel compliant.
# - A shared object in the wheel has an RPATH (e.g. a Nix store path).

manylinuxAuditWheel() {
    echo "Executing manylinuxAuditWheel"

    local whl repaired outdir unpacked soLib rpath
    local -a soLibs

    for whl in dist/*.whl; do
        echo "Wheel: $whl"
        @auditwheel@ show "$whl"

        outdir=$(mktemp -d)
        # auditwheel calls `strip` (for `--strip`), which is not in its wrapper.
        PATH="@binutils@/bin:$PATH" \
            @auditwheel@ repair --strip --plat @platform@ --wheel-dir "$outdir" "$whl"

        repaired=$(echo "$outdir"/*.whl)
        echo "Repaired wheel: $repaired"

        case "$repaired" in
            *-@platform@.whl | *.@platform@.whl) ;;
            *)
                echo "error: wheel does not have a @platform@ platform tag" >&2
                exit 1
                ;;
        esac

        if @unzip@ -l "$repaired" | grep -q '\.libs/'; then
            echo "error: auditwheel had to bundle external libraries" >&2
            @unzip@ -l "$repaired" >&2
            exit 1
        fi

        unpacked=$(mktemp -d)
        @unzip@ -q "$repaired" -d "$unpacked"
        mapfile -d '' soLibs < <(find "$unpacked" -type f -name '*.so*' -print0)
        for soLib in "${soLibs[@]}"; do
            rpath=$(@patchelf@ --print-rpath "$soLib")
            if [ -n "$rpath" ]; then
                echo "error: $soLib has an RPATH: $rpath" >&2
                exit 1
            fi
        done

        rm "$whl"
        mv "$repaired" dist/
        rm -rf "$outdir" "$unpacked"
    done

    echo "Finished executing manylinuxAuditWheel"
}

postBuildHooks+=(manylinuxAuditWheel)
