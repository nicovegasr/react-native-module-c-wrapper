#!/usr/bin/env bash
#
# setup.sh — prepara los artefactos prebuilt para que Gradle pueda
# compilar el módulo AAR de Caesar.
#
# Qué hace:
#   1. Verifica que `scripts/compile-android.sh` ya ha producido los .so.
#   2. Copia esos .so a `src/main/jniLibs/<abi>/`.
#   3. Copia `caesar.h` a `src/main/cpp-include/`.
#
# Por qué NO recompila libcaesar.so desde Gradle:
#   Romper la reproducibilidad respecto al build oficial del monorepo.
#   El binario que llega al AAR debe ser bit a bit el mismo que el que
#   produce scripts/compile-android.sh.
#
# Es idempotente: borra los destinos antes de copiar. Llámalo cuantas
# veces necesites; no hay efecto acumulativo.

set -euo pipefail

# ─── Configuración (rutas y datos del módulo) ──────────────────────────
readonly MODULE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly MONOREPO_ROOT="$MODULE_ROOT/.."

readonly PREBUILT_BINARIES_ROOT="$MONOREPO_ROOT/build/android"
readonly C_HEADER_SOURCE_PATH="$MONOREPO_ROOT/c-library/caesar.h"

readonly GRADLE_JNILIBS_DIR="$MODULE_ROOT/src/main/jniLibs"
readonly GRADLE_C_INCLUDE_DIR="$MODULE_ROOT/src/main/cpp-include"

readonly SUPPORTED_ABIS=("arm64-v8a" "x86_64")

readonly COMPILE_SCRIPT_RELATIVE_PATH="../scripts/compile-android.sh"

# ─── Helpers de aborto con instrucciones ───────────────────────────────
abort_with_instruction_to_compile_first() {
    local reason="$1"
    {
        echo "ERROR: $reason"
        echo "       Ejecuta primero: bash $COMPILE_SCRIPT_RELATIVE_PATH"
    } >&2
    exit 1
}

# ─── Pasos del setup ───────────────────────────────────────────────────
ensure_prebuilt_binaries_exist() {
    if [ ! -d "$PREBUILT_BINARIES_ROOT" ]; then
        abort_with_instruction_to_compile_first \
            "no existe $PREBUILT_BINARIES_ROOT"
    fi

    for abi in "${SUPPORTED_ABIS[@]}"; do
        local prebuilt_so_path="$PREBUILT_BINARIES_ROOT/$abi/libcaesar.so"
        if [ ! -f "$prebuilt_so_path" ]; then
            abort_with_instruction_to_compile_first \
                "falta el artefacto prebuilt $prebuilt_so_path"
        fi
    done
}

ensure_c_header_exists() {
    if [ ! -f "$C_HEADER_SOURCE_PATH" ]; then
        abort_with_instruction_to_compile_first \
            "no se encuentra $C_HEADER_SOURCE_PATH"
    fi
}

copy_prebuilt_shared_objects_to_jnilibs() {
    echo "==> Copiando libcaesar.so prebuilt a src/main/jniLibs/"
    rm -rf "$GRADLE_JNILIBS_DIR"
    mkdir -p "$GRADLE_JNILIBS_DIR"

    for abi in "${SUPPORTED_ABIS[@]}"; do
        local destination_dir="$GRADLE_JNILIBS_DIR/$abi"
        mkdir -p "$destination_dir"
        cp "$PREBUILT_BINARIES_ROOT/$abi/libcaesar.so" "$destination_dir/"
        echo "    + $destination_dir/libcaesar.so"
    done
}

copy_c_header_for_jni_bridge_to_include_dir() {
    echo "==> Copiando caesar.h a src/main/cpp-include/"
    rm -rf "$GRADLE_C_INCLUDE_DIR"
    mkdir -p "$GRADLE_C_INCLUDE_DIR"
    cp "$C_HEADER_SOURCE_PATH" "$GRADLE_C_INCLUDE_DIR/"
    echo "    + $GRADLE_C_INCLUDE_DIR/caesar.h"
}

print_next_steps() {
    cat <<MESSAGE

✓ Módulo listo. Ahora:
    bash run-tests.sh             # tests instrumentados en emulador
    ./gradlew assembleRelease     # genera el AAR en build/outputs/aar/
MESSAGE
}

# ─── Main ──────────────────────────────────────────────────────────────
main() {
    ensure_prebuilt_binaries_exist
    ensure_c_header_exists
    copy_prebuilt_shared_objects_to_jnilibs
    copy_c_header_for_jni_bridge_to_include_dir
    print_next_steps
}

main "$@"
