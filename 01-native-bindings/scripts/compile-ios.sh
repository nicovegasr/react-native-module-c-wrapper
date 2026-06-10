#!/usr/bin/env bash
#
# compile-ios.sh — empaqueta libcaesar como Caesar.xcframework
# Cómo funciona, paso a paso: ./README.md
#
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT_DIR="$SCRIPT_DIR/.."
readonly SOURCE_DIR="$ROOT_DIR/c-library"

readonly LIBRARY_NAME="caesar"
readonly FRAMEWORK_NAME="Caesar"
readonly MINIMUM_IOS_VERSION="16.0"

readonly BUILD_DIR="$ROOT_DIR/build/ios"
readonly PUBLIC_HEADERS_DIR="$BUILD_DIR/headers"
readonly DEVICE_DIR="$BUILD_DIR/ios-arm64"
readonly SIMULATOR_ARM64_DIR="$BUILD_DIR/ios-sim-arm64"
readonly SIMULATOR_X86_DIR="$BUILD_DIR/ios-sim-x86_64"
readonly SIMULATOR_FAT_DIR="$BUILD_DIR/ios-sim"

ensure_full_xcode_is_installed() {
    if xcrun --sdk iphoneos --show-sdk-path >/dev/null 2>&1; then
        return 0
    fi

    {
        echo "ERROR: no se encuentra la SDK 'iphoneos'."
        echo "       Necesitas Xcode.app completo, no solo Command Line Tools."
        echo "       Instala Xcode desde el App Store y luego ejecuta:"
        echo "         sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
    } >&2
    exit 1
}

prepare_build_layout() {
    echo "==> Limpiando artefactos previos"
    rm -rf "$BUILD_DIR"
    mkdir -p \
        "$DEVICE_DIR" \
        "$SIMULATOR_ARM64_DIR" \
        "$SIMULATOR_X86_DIR" \
        "$SIMULATOR_FAT_DIR" \
        "$PUBLIC_HEADERS_DIR"
}

publish_public_header() {
    cp "$SOURCE_DIR/${LIBRARY_NAME}.h" "$PUBLIC_HEADERS_DIR/"
}

compile_static_library_for() {
    local sdk_name="$1" architecture="$2" target_triple="$3" output_dir="$4"

    local sdk_path
    sdk_path=$(xcrun --sdk "$sdk_name" --show-sdk-path)

    local object_file="$output_dir/${LIBRARY_NAME}.o"
    local archive_file="$output_dir/lib${LIBRARY_NAME}.a"

    xcrun --sdk "$sdk_name" clang -arch "$architecture" \
        -target "$target_triple" \
        -isysroot "$sdk_path" \
        -O2 -Wall -Wextra \
        -c "$SOURCE_DIR/${LIBRARY_NAME}.c" -o "$object_file"

    xcrun --sdk "$sdk_name" ar rcs "$archive_file" "$object_file"
}

compile_static_library_for_device() {
    echo "==> Compilando libcaesar para iOS device (arm64)"
    compile_static_library_for \
        "iphoneos" "arm64" \
        "arm64-apple-ios${MINIMUM_IOS_VERSION}" \
        "$DEVICE_DIR"
}

compile_static_library_for_simulator_arm64() {
    echo "==> Compilando libcaesar para iOS simulator (arm64)"
    compile_static_library_for \
        "iphonesimulator" "arm64" \
        "arm64-apple-ios${MINIMUM_IOS_VERSION}-simulator" \
        "$SIMULATOR_ARM64_DIR"
}

compile_static_library_for_simulator_x86() {
    echo "==> Compilando libcaesar para iOS simulator (x86_64)"
    compile_static_library_for \
        "iphonesimulator" "x86_64" \
        "x86_64-apple-ios${MINIMUM_IOS_VERSION}-simulator" \
        "$SIMULATOR_X86_DIR"
}

# lipo SOLO une arquitecturas DENTRO de la misma plataforma (simulator + simulator).
# NUNCA mezclar device + simulator: para esa separación está el xcframework.
merge_simulator_architectures_into_fat_binary() {
    echo "==> Uniendo simulator arm64 + x86_64 con lipo"
    xcrun lipo -create \
        "$SIMULATOR_ARM64_DIR/lib${LIBRARY_NAME}.a" \
        "$SIMULATOR_X86_DIR/lib${LIBRARY_NAME}.a" \
        -output "$SIMULATOR_FAT_DIR/lib${LIBRARY_NAME}.a"
}

assemble_xcframework() {
    local framework_path="$BUILD_DIR/${FRAMEWORK_NAME}.xcframework"

    echo "==> Ensamblando ${FRAMEWORK_NAME}.xcframework"
    rm -rf "$framework_path"
    xcodebuild -create-xcframework \
        -library "$DEVICE_DIR/lib${LIBRARY_NAME}.a"        -headers "$PUBLIC_HEADERS_DIR" \
        -library "$SIMULATOR_FAT_DIR/lib${LIBRARY_NAME}.a" -headers "$PUBLIC_HEADERS_DIR" \
        -output  "$framework_path"
}

announce_artifact() {
    echo ""
    echo "✓ Listo: $BUILD_DIR/${FRAMEWORK_NAME}.xcframework"
}

main() {
    ensure_full_xcode_is_installed
    prepare_build_layout
    publish_public_header

    compile_static_library_for_device
    compile_static_library_for_simulator_arm64
    compile_static_library_for_simulator_x86
    merge_simulator_architectures_into_fat_binary

    assemble_xcframework
    announce_artifact
}

main "$@"
