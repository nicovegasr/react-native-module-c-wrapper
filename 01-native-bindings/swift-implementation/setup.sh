#!/usr/bin/env bash
#
# setup.sh — prepara el xcframework para ser consumido por SPM
#
# Copia Caesar.xcframework desde ../build/ a vendor/ y le inyecta un
# module.modulemap en cada slice (device y simulator) para que Swift pueda
# hacer `import CCaesar`. El xcframework original que genera compile-ios.sh
# no incluye modulemap — ese es el paso que conecta C ↔ Swift.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_XCFW="$SCRIPT_DIR/../build/ios/Caesar.xcframework"
VENDOR_DIR="$SCRIPT_DIR/vendor"
DEST_XCFW="$VENDOR_DIR/Caesar.xcframework"

if [ ! -d "$SOURCE_XCFW" ]; then
    echo "ERROR: $SOURCE_XCFW no existe." >&2
    echo "       Ejecuta primero: bash ../scripts/compile-ios.sh" >&2
    exit 1
fi

echo "==> Copiando Caesar.xcframework a vendor/"
rm -rf "$DEST_XCFW"
mkdir -p "$VENDOR_DIR"
cp -R "$SOURCE_XCFW" "$DEST_XCFW"

# Strip extended attributes (Finder info, quarantine) que harían fallar a codesign
# con: "resource fork, Finder information, or similar detritus not allowed".
xattr -cr "$DEST_XCFW"

echo "==> Inyectando module.modulemap en cada slice"
for headers_dir in "$DEST_XCFW"/*/Headers; do
    [ -d "$headers_dir" ] || continue
    cat > "$headers_dir/module.modulemap" <<'EOF'
module CCaesar {
    header "caesar.h"
    export *
}
EOF
    echo "    + $headers_dir/module.modulemap"
done

echo ""
echo "✓ vendor/Caesar.xcframework listo. Ahora:"
echo "    bash run-tests.sh"
