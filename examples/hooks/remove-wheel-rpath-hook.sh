# Hook that removes the rpath from shared objects in wheels.

manylinuxRemoveWheelRpath() {
    echo "Executing manylinuxRemoveWheelRpath"

    local whl unpacked soLib
    local -a soLibs

    for whl in dist/*.whl; do
        unpacked=$(mktemp -d)

        @wheel@ unpack --dest "$unpacked" "$whl"

        mapfile -d '' soLibs < <(find "$unpacked" -type f -name '*.so*' -print0)
        for soLib in "${soLibs[@]}"; do
            @patchelf@ --remove-rpath "$soLib"
        done

        # Packing regenerates the RECORD file.
        rm "$whl"
        @wheel@ pack --dest-dir dist "$unpacked"/*
        rm -rf "$unpacked"
    done

    echo "Finished executing manylinuxRemoveWheelRpath"
}

postBuildHooks+=(manylinuxRemoveWheelRpath)
