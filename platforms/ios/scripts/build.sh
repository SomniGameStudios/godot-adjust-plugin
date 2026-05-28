#!/bin/bash
# MIT License
#
# Copyright (c) 2026-present Somni Game Studios
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$IOS_DIR/../.." && pwd)"
DEST_PLUGINS="$PROJECT_ROOT/platforms/godot_editor/ios/plugins/adjust"

PRODUCT_NAME="AdjustGodotPlugin"

echo ">>> Compiling iOS Plugin..."

for CONFIG in Release Debug; do
    CONFIG_LOWER=$(echo "$CONFIG" | tr '[:upper:]' '[:lower:]')
    BUILD_DIR="$IOS_DIR/build/$CONFIG_LOWER"
    BIN_DIR="$IOS_DIR/bin/$CONFIG_LOWER"

    rm -rf "$BUILD_DIR" "$BIN_DIR"
    mkdir -p "$BUILD_DIR" "$BIN_DIR" "$DEST_PLUGINS"

    cd "$IOS_DIR"

    # DEBUG_ENABLED must always be defined because Godot export templates
    # (both debug and release) are compiled with it. This controls which
    # ClassDB::bind_methodfi overload is used (MethodDefinition vs char*).
    XCODE_FLAGS=(GCC_PREPROCESSOR_DEFINITIONS='$(inherited) DEBUG_ENABLED=1')

    # --- Build for Device (arm64) ---
    echo ">>> Building for iOS Device (arm64) [$CONFIG]..."
    xcodebuild build \
        -scheme "$PRODUCT_NAME" \
        -destination 'generic/platform=iOS' \
        -configuration "$CONFIG" \
        -derivedDataPath "$BUILD_DIR/device" \
        "${XCODE_FLAGS[@]}" \
        SKIP_INSTALL=NO \
        2>&1 | tail -5

    # --- Build for Simulator (arm64 + x86_64) ---
    echo ">>> Building for iOS Simulator [$CONFIG]..."
    xcodebuild build \
        -scheme "$PRODUCT_NAME" \
        -destination 'generic/platform=iOS Simulator' \
        -configuration "$CONFIG" \
        -derivedDataPath "$BUILD_DIR/simulator" \
        "${XCODE_FLAGS[@]}" \
        SKIP_INSTALL=NO \
        2>&1 | tail -5

    # --- Archive .o files into .a static libraries ---
    echo ">>> Archiving object files into static libraries [$CONFIG]..."

    DEVICE_PRODUCTS="$BUILD_DIR/device/Build/Products/$CONFIG-iphoneos"
    SIMULATOR_PRODUCTS="$BUILD_DIR/simulator/Build/Products/$CONFIG-iphonesimulator"

    DEVICE_LIB="$BIN_DIR/lib${PRODUCT_NAME}-iphoneos.a"
    SIMULATOR_LIB="$BIN_DIR/lib${PRODUCT_NAME}-iphonesimulator.a"

    # Collect only our plugin's .o files, exclude AdjustSdk.o
    DEVICE_OBJECTS=$(find "$DEVICE_PRODUCTS" -name "AdjustGodotPlugin.o" -o -name "AdjustGodotBridge.o" -type f)
    if [ -z "$DEVICE_OBJECTS" ]; then
        echo "ERROR: No .o files found in device build [$CONFIG]!"
        exit 1
    fi
    ar rcs "$DEVICE_LIB" $DEVICE_OBJECTS

    # Collect all .o files from simulator build
    SIMULATOR_OBJECTS=$(find "$SIMULATOR_PRODUCTS" -name "AdjustGodotPlugin.o" -o -name "AdjustGodotBridge.o" -type f)
    if [ -n "$SIMULATOR_OBJECTS" ]; then
        ar rcs "$SIMULATOR_LIB" $SIMULATOR_OBJECTS
    fi

    echo ">>> Device lib: $DEVICE_LIB ($(du -h "$DEVICE_LIB" | cut -f1))"
    if [ -f "$SIMULATOR_LIB" ]; then
        echo ">>> Simulator lib: $SIMULATOR_LIB ($(du -h "$SIMULATOR_LIB" | cut -f1))"
    fi

    # --- Create xcframework ---
    echo ">>> Creating xcframework [$CONFIG]..."
    XCFW_ARGS=(-create-xcframework -library "$DEVICE_LIB")

    if [ -f "$SIMULATOR_LIB" ]; then
        XCFW_ARGS+=(-library "$SIMULATOR_LIB")
    fi

    XCFW_NAME="${PRODUCT_NAME}.${CONFIG_LOWER}.xcframework"
    XCFW_PATH="$BIN_DIR/$XCFW_NAME"
    XCFW_ARGS+=(-output "$XCFW_PATH")

    xcodebuild "${XCFW_ARGS[@]}" 2>&1 | tail -3

    # --- Copy to Godot editor ---
    echo ">>> Copying $XCFW_NAME to Godot editor..."
    rm -rf "$DEST_PLUGINS/$XCFW_NAME"
    cp -R "$XCFW_PATH" "$DEST_PLUGINS/"
    cp "$IOS_DIR/AdjustGodotPlugin.gdip" "$DEST_PLUGINS/"

    # Also copy the release framework as the default/non-suffix name
    if [ "$CONFIG" = "Release" ]; then
        echo ">>> Copying default ${PRODUCT_NAME}.xcframework..."
        rm -rf "$DEST_PLUGINS/${PRODUCT_NAME}.xcframework"
        cp -R "$XCFW_PATH" "$DEST_PLUGINS/${PRODUCT_NAME}.xcframework"
    fi
done

echo ">>> iOS Build Complete"


