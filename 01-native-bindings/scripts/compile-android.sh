#!/usr/bin/env bash
#
# compile-android.sh — empaqueta libcaesar como .so por ABI para Android API 34+
# Cómo funciona, paso a paso: ./README.md
#
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT_DIR="$SCRIPT_DIR/.."
readonly SOURCE_DIR="$ROOT_DIR/c-library"

readonly LIBRARY_NAME="caesar"
readonly ANDROID_MIN_API_LEVEL="34"
readonly MINIMUM_SUPPORTED_NDK_MAJOR=25
readonly TARGET_ABIS=("arm64-v8a" "x86_64")
readonly REQUIRED_EXPORTED_SYMBOLS=("encrypt" "decrypt")

readonly BUILD_DIR="$ROOT_DIR/build/android"
readonly PUBLIC_HEADERS_DIR="$BUILD_DIR/include"

ndk_from_environment_variables() {
    local candidate
    for candidate in \
        "${ANDROID_NDK_HOME:-}" \
        "${ANDROID_NDK_ROOT:-}" \
        "${ANDROID_NDK:-}"
    do
        if [ -n "$candidate" ] && [ -d "$candidate" ]; then
            echo "$candidate"
            return 0
        fi
    done
    return 1
}

latest_ndk_installed_in_android_sdk() {
    local sdk_ndk_parent
    for sdk_ndk_parent in \
        "${ANDROID_HOME:-}/ndk" \
        "${ANDROID_SDK_ROOT:-}/ndk" \
        "$HOME/Library/Android/sdk/ndk"
    do
        if [ -d "$sdk_ndk_parent" ]; then
            local latest_version
            latest_version=$(ls -1 "$sdk_ndk_parent" 2>/dev/null | sort -V | tail -n 1 || true)
            if [ -n "$latest_version" ] && [ -d "$sdk_ndk_parent/$latest_version" ]; then
                echo "$sdk_ndk_parent/$latest_version"
                return 0
            fi
        fi
    done
    return 1
}

locate_android_ndk() {
    ndk_from_environment_variables && return 0
    latest_ndk_installed_in_android_sdk && return 0
    return 1
}

abort_with_ndk_install_instructions() {
    {
        echo "ERROR: no se encuentra el Android NDK."
        echo "       Busqué (en orden):"
        echo "         - \$ANDROID_NDK_HOME"
        echo "         - \$ANDROID_NDK_ROOT"
        echo "         - \$ANDROID_NDK"
        echo "         - \$ANDROID_HOME/ndk/*"
        echo "         - \$ANDROID_SDK_ROOT/ndk/*"
        echo "         - \$HOME/Library/Android/sdk/ndk/*"
        echo ""
        echo "       Necesitas el NDK r${MINIMUM_SUPPORTED_NDK_MAJOR} o posterior (LTS actual recomendada: r27)."
        echo ""
        echo "       Opción 1 — Android Studio: SDK Manager → SDK Tools"
        echo "                  → marca 'NDK (Side by side)' → escoge la r27 LTS."
        echo ""
        echo "       Opción 2 — CLI (sdkmanager):"
        echo "         sdkmanager --list | grep '^  ndk;27'   # ver builds de r27"
        echo "         sdkmanager --install \"ndk;<version>\"  # instala la elegida"
        echo "         export ANDROID_NDK_HOME=\"\$ANDROID_HOME/ndk/<version>\""
    } >&2
    exit 1
}

ndk_major_version_at() {
    local ndk_path="$1"
    awk -F'= *' '/Pkg.Revision/ {split($2,a,"."); print a[1]}' "$ndk_path/source.properties"
}

ensure_ndk_version_is_supported() {
    local ndk_path="$1"

    if [ ! -f "$ndk_path/source.properties" ]; then
        echo "ERROR: $ndk_path no parece un NDK válido (falta source.properties)." >&2
        exit 1
    fi

    local detected_major
    detected_major=$(ndk_major_version_at "$ndk_path")

    if [ -z "$detected_major" ] || [ "$detected_major" -lt "$MINIMUM_SUPPORTED_NDK_MAJOR" ]; then
        {
            echo "ERROR: se requiere NDK r${MINIMUM_SUPPORTED_NDK_MAJOR} o posterior."
            echo "       Versión detectada: r${detected_major:-?} en $ndk_path"
            echo "       Actualiza desde Android Studio (SDK Manager → SDK Tools → NDK)."
        } >&2
        exit 1
    fi
}

# En macOS el toolchain prebuilt es universal binary desde NDK r23: el host
# tag es siempre 'darwin-x86_64' incluso en Apple Silicon.
detect_host_toolchain_tag() {
    case "$(uname -s)" in
        Darwin) echo "darwin-x86_64" ;;
        Linux)  echo "linux-x86_64" ;;
        *) echo "ERROR: host no soportado: $(uname -s)" >&2; exit 1 ;;
    esac
}

resolve_host_toolchain() {
    local ndk_path="$1"
    local host_tag
    host_tag=$(detect_host_toolchain_tag)

    local toolchain_path="$ndk_path/toolchains/llvm/prebuilt/$host_tag"
    if [ ! -d "$toolchain_path" ]; then
        {
            echo "ERROR: toolchain no encontrado en $toolchain_path"
            echo "       ¿NDK corrupto o instalación parcial?"
        } >&2
        exit 1
    fi
    echo "$toolchain_path"
}

compiler_triple_for() {
    case "$1" in
        arm64-v8a) echo "aarch64-linux-android" ;;
        x86_64)    echo "x86_64-linux-android" ;;
        *) echo "ERROR: ABI no soportada: $1" >&2; exit 1 ;;
    esac
}

prepare_build_layout() {
    echo "==> Limpiando artefactos previos"
    rm -rf "$BUILD_DIR"
    mkdir -p "$PUBLIC_HEADERS_DIR"
    local abi
    for abi in "${TARGET_ABIS[@]}"; do
        mkdir -p "$BUILD_DIR/$abi"
    done
}

publish_public_header() {
    cp "$SOURCE_DIR/${LIBRARY_NAME}.h" "$PUBLIC_HEADERS_DIR/"
}

shared_library_path_for() {
    local abi="$1"
    echo "$BUILD_DIR/$abi/lib${LIBRARY_NAME}.so"
}

# Una sola invocación de clang por ABI: .c -> .so. No pasamos por un .o
# intermedio porque solo hay una fuente; el .o sería puro overhead.
compile_shared_library_for() {
    local abi="$1" toolchain_path="$2"

    local triple
    triple=$(compiler_triple_for "$abi")
    local cross_compiler_path="$toolchain_path/bin/${triple}${ANDROID_MIN_API_LEVEL}-clang"
    local shared_library_path
    shared_library_path=$(shared_library_path_for "$abi")

    if [ ! -x "$cross_compiler_path" ]; then
        {
            echo "ERROR: compilador no encontrado: $cross_compiler_path"
            echo "       ¿El NDK soporta API ${ANDROID_MIN_API_LEVEL}?"
        } >&2
        exit 1
    fi

    echo "==> Compilando libcaesar para $abi ($triple, API ${ANDROID_MIN_API_LEVEL})"
    "$cross_compiler_path" \
        -fPIC \
        -O2 \
        -Wall -Wextra \
        -shared \
        -Wl,-soname,"lib${LIBRARY_NAME}.so" \
        "$SOURCE_DIR/${LIBRARY_NAME}.c" \
        -o "$shared_library_path"

    strip_debug_symbols_from "$shared_library_path" "$toolchain_path"
}

strip_debug_symbols_from() {
    local shared_library_path="$1" toolchain_path="$2"
    "$toolchain_path/bin/llvm-strip" --strip-unneeded "$shared_library_path"
}

verify_artifact_architecture() {
    local abi="$1" expected_elf_signature="$2"
    local shared_library_path
    shared_library_path=$(shared_library_path_for "$abi")

    if ! file "$shared_library_path" | grep -q "$expected_elf_signature"; then
        echo "ERROR: $abi no es un ELF '$expected_elf_signature' válido" >&2
        exit 1
    fi
}

verify_soname_matches_library_name() {
    local abi="$1" toolchain_path="$2"
    local shared_library_path
    shared_library_path=$(shared_library_path_for "$abi")
    local expected_soname="lib${LIBRARY_NAME}.so"

    if ! "$toolchain_path/bin/llvm-readelf" -d "$shared_library_path" | grep -q "SONAME.*$expected_soname"; then
        echo "ERROR: SONAME ausente o incorrecto en $abi" >&2
        exit 1
    fi
}

verify_required_symbols_are_exported() {
    local abi="$1" toolchain_path="$2"
    local shared_library_path
    shared_library_path=$(shared_library_path_for "$abi")

    local symbol_alternatives
    symbol_alternatives=$(IFS='|'; echo "${REQUIRED_EXPORTED_SYMBOLS[*]}")

    local exported_symbol_count
    exported_symbol_count=$("$toolchain_path/bin/llvm-nm" -D "$shared_library_path" \
        | grep -E " T ($symbol_alternatives)" | wc -l | tr -d ' ')

    local expected_count=${#REQUIRED_EXPORTED_SYMBOLS[@]}
    if [ "$exported_symbol_count" -ne "$expected_count" ]; then
        echo "ERROR: se esperaban $expected_count símbolos exportados (${REQUIRED_EXPORTED_SYMBOLS[*]}), se encontraron $exported_symbol_count en $abi" >&2
        exit 1
    fi
}

verify_all_artifacts() {
    local toolchain_path="$1"
    echo "==> Verificando binarios"

    verify_artifact_architecture "arm64-v8a" "ELF 64-bit LSB shared object, ARM aarch64"
    verify_artifact_architecture "x86_64"    "ELF 64-bit LSB shared object, x86-64"
    verify_soname_matches_library_name   "arm64-v8a" "$toolchain_path"
    verify_required_symbols_are_exported "arm64-v8a" "$toolchain_path"
}

announce_artifacts_and_consumer_instructions() {
    echo ""
    echo "✓ Listo:"
    local abi
    for abi in "${TARGET_ABIS[@]}"; do
        echo "    $(shared_library_path_for "$abi")"
    done
    echo "    $PUBLIC_HEADERS_DIR/${LIBRARY_NAME}.h"
    echo ""
    echo "  Para consumir desde un módulo Android Gradle:"
    echo "    copia $BUILD_DIR/{arm64-v8a,x86_64} a android/src/main/jniLibs/"
}

main() {
    local android_ndk_path
    if ! android_ndk_path=$(locate_android_ndk); then
        abort_with_ndk_install_instructions
    fi
    ensure_ndk_version_is_supported "$android_ndk_path"

    local toolchain_path
    toolchain_path=$(resolve_host_toolchain "$android_ndk_path")

    local detected_ndk_major
    detected_ndk_major=$(ndk_major_version_at "$android_ndk_path")
    echo "==> NDK r${detected_ndk_major} en $android_ndk_path"

    prepare_build_layout
    publish_public_header

    local abi
    for abi in "${TARGET_ABIS[@]}"; do
        compile_shared_library_for "$abi" "$toolchain_path"
    done

    verify_all_artifacts "$toolchain_path"
    announce_artifacts_and_consumer_instructions
}

main "$@"
