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

# scripts/build_local.sh

show_help() {
    echo "Usage: ./scripts/build_local.sh [android|ios|all] <godot_version>"
    echo ""
    echo "Arguments:"
    echo "  [platform]       android, ios, or all (default: all)"
    echo "  <godot_version>  The Godot version (e.g., 4.6.2)"
    echo ""
    echo "Examples:"
    echo "  ./scripts/build_local.sh all 4.6.2"
    echo "  ./scripts/build_local.sh ios 4.6.2"
    echo "  ./scripts/build_local.sh android 4.6.2"
}

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    show_help
    exit 0
fi

PLATFORM=${1:-all}
GODOT_VERSION=${2}

if [ -z "$GODOT_VERSION" ]; then
    show_help
    exit 1
fi

ROOT_DIR=$(pwd)
DEST="$ROOT_DIR/platforms/godot_editor"

build_android() {
    echo ">>> Building Android ($GODOT_VERSION)..."
    cd "$ROOT_DIR/platforms/android" && chmod +x gradlew && \
    ./gradlew build -PgodotVersion="$GODOT_VERSION" && \
    ./gradlew exportFiles -PpluginExportPath="$DEST/addons/adjust/android/bin" || exit 1
}

build_ios() {
    echo ">>> Building iOS ($GODOT_VERSION)..."
    cd "$ROOT_DIR/platforms/ios" || exit 1

    # build.sh compiles against generated Godot headers under include/godot
    # (gitignored). Generate them automatically when missing so a clean
    # checkout builds in a single command.
    if [ ! -d "$ROOT_DIR/platforms/ios/include/godot" ]; then
        echo ">>> Godot headers missing; generating..."
        ./scripts/download_and_generate_headers.sh || exit 1
    fi

    ./scripts/build.sh "$GODOT_VERSION" || exit 1
}

case "$PLATFORM" in
    android) build_android ;;
    ios)     build_ios ;;
    all)     build_android; build_ios ;;
    *)       echo "Invalid platform: $PLATFORM"; exit 1 ;;
esac

echo "Done! Plugin binaries updated in $DEST"
