#!/usr/bin/env bash
#
# run-tests.sh — ejecuta los tests instrumentados de Caesar sobre un
# emulador o device Android conectado.
#
# Equivalente conceptual al run-tests.sh del lado Swift, adaptado a la
# realidad de JNI: no existe una "JVM puro" capaz de cargar un .so de
# Android, así que la única vía honesta es ejecutar contra un runtime
# Android real (emulador o device físico).
#
# Pasos:
#   1. Asegura que setup.sh ya copió los artefactos prebuilt.
#   2. Localiza `adb` (AGP lo necesita para connectedAndroidTest).
#   3. Verifica que al menos un device/emulador está conectado.
#   4. Lanza `gradle connectedAndroidTest`.

set -euo pipefail

# ─── Configuración ─────────────────────────────────────────────────────
readonly MODULE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

readonly REQUIRED_JNILIBS_DIRS=(
    "$MODULE_ROOT/src/main/jniLibs/arm64-v8a"
    "$MODULE_ROOT/src/main/jniLibs/x86_64"
)
readonly REQUIRED_C_HEADER_PATH="$MODULE_ROOT/src/main/cpp-include/caesar.h"

readonly POSSIBLE_ADB_LOCATIONS=(
    "${ANDROID_HOME:-}/platform-tools/adb"
    "${ANDROID_SDK_ROOT:-}/platform-tools/adb"
    "$HOME/Library/Android/sdk/platform-tools/adb"
)

readonly GRADLE_TASK_FOR_INSTRUMENTED_TESTS="connectedAndroidTest"

# ─── Setup automático si faltan los artefactos prebuilt ────────────────
prebuilt_artifacts_are_missing() {
    for required_dir in "${REQUIRED_JNILIBS_DIRS[@]}"; do
        [ -d "$required_dir" ] || return 0
    done
    [ -f "$REQUIRED_C_HEADER_PATH" ] || return 0
    return 1
}

run_setup_to_produce_prebuilt_artifacts() {
    echo "==> Artefactos prebuilt ausentes, ejecutando setup.sh"
    bash "$MODULE_ROOT/setup.sh"
}

# ─── Localización de adb ───────────────────────────────────────────────
find_adb_executable_path() {
    for candidate in "${POSSIBLE_ADB_LOCATIONS[@]}"; do
        if [ -n "$candidate" ] && [ -x "$candidate" ]; then
            echo "$candidate"
            return 0
        fi
    done

    if command -v adb >/dev/null 2>&1; then
        command -v adb
        return 0
    fi

    return 1
}

abort_when_adb_not_installed() {
    {
        echo "ERROR: adb no encontrado."
        echo "       Instala Android SDK Platform Tools y exporta ANDROID_HOME."
    } >&2
    exit 1
}

# ─── Comprobación de dispositivos conectados ───────────────────────────
list_connected_android_devices() {
    local adb_executable_path="$1"
    "$adb_executable_path" devices | awk 'NR>1 && $2=="device" {print $1}'
}

abort_when_no_device_connected() {
    {
        echo "ERROR: no hay emulador ni device conectado."
        echo "       Arranca uno con: emulator -avd <nombre>"
        echo "       (lista con: emulator -list-avds)"
    } >&2
    exit 1
}

print_connected_devices() {
    local connected_devices="$1"
    echo "==> Dispositivos disponibles:"
    echo "$connected_devices" | sed 's/^/    - /'
}

# ─── Resolución del gradle a usar ──────────────────────────────────────
resolve_gradle_command_to_use() {
    if [ -x "$MODULE_ROOT/gradlew" ]; then
        echo "$MODULE_ROOT/gradlew"
    else
        echo "gradle"
    fi
}

# ─── Main ──────────────────────────────────────────────────────────────
main() {
    cd "$MODULE_ROOT"

    if prebuilt_artifacts_are_missing; then
        run_setup_to_produce_prebuilt_artifacts
    fi

    local adb_executable_path
    if ! adb_executable_path=$(find_adb_executable_path); then
        abort_when_adb_not_installed
    fi

    local connected_devices
    connected_devices=$(list_connected_android_devices "$adb_executable_path")
    if [ -z "$connected_devices" ]; then
        abort_when_no_device_connected
    fi
    print_connected_devices "$connected_devices"

    local gradle_command
    gradle_command=$(resolve_gradle_command_to_use)
    echo "==> Ejecutando $GRADLE_TASK_FOR_INSTRUMENTED_TESTS"
    "$gradle_command" "$GRADLE_TASK_FOR_INSTRUMENTED_TESTS"
}

main "$@"
