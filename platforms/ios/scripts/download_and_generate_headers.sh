#!/bin/bash
# platforms/ios/scripts/download_and_generate_headers.sh

set -e

GODOT_VERSION="4.6.2"
GODOT_FOLDER="godot-${GODOT_VERSION}-stable"
DOWNLOAD_FILE="${GODOT_FOLDER}.tar.xz"
DOWNLOAD_URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/${DOWNLOAD_FILE}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMP_DIR="$IOS_DIR/build/temp_godot"

echo ">>> Creating temp directory: $TEMP_DIR"
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

echo ">>> Downloading Godot ${GODOT_VERSION} source..."
curl -LO "$DOWNLOAD_URL"

echo ">>> Extracting..."
tar -xf "$DOWNLOAD_FILE"
rm -f "$DOWNLOAD_FILE"

cd "$GODOT_FOLDER"

echo ">>> Generating headers using scons..."
export PYTHONWARNINGS="ignore::SyntaxWarning"
scons -j$(sysctl -n hw.ncpu) platform=ios target=template_release core/version_generated.gen.h core/disabled_classes.gen.h core/object/gdvirtual.gen.inc modules/modules_enabled.gen.h core/extension/gdextension_interface.gen.h


echo ">>> Replacing platforms/ios/include/godot with new headers..."
rm -rf "$IOS_DIR/include/godot"
mkdir -p "$IOS_DIR/include"
mv "$TEMP_DIR/$GODOT_FOLDER" "$IOS_DIR/include/godot"

echo ">>> Cleaning up..."
rm -rf "$TEMP_DIR"

echo ">>> Done! Godot ${GODOT_VERSION} headers generated successfully."
