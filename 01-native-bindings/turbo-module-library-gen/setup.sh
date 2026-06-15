#!/usr/bin/env bash
# Prepara las dependencias nativas del módulo RN consumiendo los wrappers
# hermanos:
#  - iOS:     pod local que apunta a swift-implementation/ (gestionado en
#             el Podfile del consumer — p.ej. react-native-test/ios/Podfile;
#             este script no copia nada).
#  - Android: AAR de jni-implementation/ producido por su Gradle build y
#             copiado a android/libs/ — flatDir lo expone al módulo RN.
#
# Idempotente.

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$SCRIPT_DIR/.."
readonly JNI_DIR="$REPO_ROOT/jni-implementation"
readonly AAR_LIBS_DIR="$SCRIPT_DIR/android/libs"
readonly AAR_DEST="$AAR_LIBS_DIR/caesar.aar"

if [ ! -d "$JNI_DIR" ]; then
    echo "ERROR: no existe $JNI_DIR"
    echo "El módulo RN espera el wrapper Kotlin como hermano en el monorepo."
    exit 1
fi

echo "Building Android AAR from jni-implementation/..."
(cd "$JNI_DIR" && ./gradlew --quiet assembleRelease)

readonly AAR_SOURCE="$JNI_DIR/build/outputs/aar/caesar-android-release.aar"
if [ ! -f "$AAR_SOURCE" ]; then
    echo "ERROR: el build no produjo $AAR_SOURCE"
    echo "Comprueba la salida de './gradlew assembleRelease' en jni-implementation/"
    exit 1
fi

mkdir -p "$AAR_LIBS_DIR"
cp "$AAR_SOURCE" "$AAR_DEST"

echo "Setup OK:"
echo "  Android AAR  → android/libs/caesar.aar"
echo "  iOS Swift    → pod 'Caesar' (declarado en el Podfile del consumer por path)"
