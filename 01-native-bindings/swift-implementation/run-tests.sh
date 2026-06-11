#!/usr/bin/env bash
#
# run-tests.sh — ejecuta los XCTest del paquete Caesar sobre un iOS Simulator
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ ! -d "vendor/Caesar.xcframework" ]; then
    echo "==> vendor/Caesar.xcframework no existe, ejecutando setup.sh"
    bash setup.sh
fi

# Selecciona el primer simulador iPhone disponible.
DEVICE=$(xcrun simctl list devices available 2>/dev/null \
    | awk -F '[()]' '/iPhone/ && /Shutdown|Booted/ {gsub(/^ +| +$/, "", $1); print $1; exit}')

if [ -z "${DEVICE:-}" ]; then
    echo "ERROR: no se encontró ningún simulador iPhone disponible." >&2
    echo "       Lista de simuladores:" >&2
    xcrun simctl list devices available >&2
    exit 1
fi

echo "==> Ejecutando tests en simulador: $DEVICE"
xcodebuild test \
    -scheme Caesar \
    -destination "platform=iOS Simulator,name=$DEVICE" \
    -derivedDataPath build \
    -skipMacroValidation
