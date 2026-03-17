#!/usr/bin/env sh
set -e

INSTALL_DIR="$HOME/.local/bin"
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Building flutter_doctor..."
cd "$SCRIPT_DIR"
dart pub get --no-example 2>/dev/null
dart compile exe bin/flutter_doctor.dart -o "$INSTALL_DIR/flutter_doctor"

echo "✓ Installed to $INSTALL_DIR/flutter_doctor"
echo ""
echo "Make sure $INSTALL_DIR is in your PATH:"
echo "  export PATH=\"\$PATH:$HOME/.local/bin\""

