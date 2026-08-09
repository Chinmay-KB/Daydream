#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TAG="${1:-}"

if [[ ! "$TAG" =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    echo "Usage: $0 vMAJOR.MINOR.PATCH" >&2
    exit 64
fi

VERSION="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.${BASH_REMATCH[3]}"
OUTPUT_DIR="$ROOT/.build/Daydream-app"
APP="$OUTPUT_DIR/Daydream.app"
ICONSET="$OUTPUT_DIR/AppIcon.iconset"

case "$APP" in
    "$ROOT/.build/Daydream-app/Daydream.app") ;;
    *)
        echo "Refuse to replace an unexpected app path: $APP" >&2
        exit 1
        ;;
esac

case "$ICONSET" in
    "$ROOT/.build/Daydream-app/AppIcon.iconset") ;;
    *)
        echo "Refuse to replace an unexpected icon path: $ICONSET" >&2
        exit 1
        ;;
esac

mkdir -p "$OUTPUT_DIR"
rm -rf "$APP" "$ICONSET"

for ARCH in arm64 x86_64; do
    swift build -c release --arch "$ARCH"
done

ARM64_BIN="$(swift build -c release --arch arm64 --show-bin-path)/Daydream"
X86_64_BIN="$(swift build -c release --arch x86_64 --show-bin-path)/Daydream"

if [[ ! -x "$ARM64_BIN" || ! -x "$X86_64_BIN" ]]; then
    echo "Swift did not produce both executable architectures." >&2
    exit 1
fi

mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
lipo -create "$ARM64_BIN" "$X86_64_BIN" -output "$APP/Contents/MacOS/Daydream"
cp "$ROOT/Info.plist" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$APP/Contents/Info.plist"

swift "$ROOT/scripts/render-app-icon.swift" "$ICONSET"
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

ARCHITECTURES="$(lipo -archs "$APP/Contents/MacOS/Daydream")"
if [[ " $ARCHITECTURES " != *" arm64 "* || " $ARCHITECTURES " != *" x86_64 "* ]]; then
    echo "Universal binary verification failed: $ARCHITECTURES" >&2
    exit 1
fi

echo "Built $APP"
echo "Version $VERSION"
echo "Architectures $ARCHITECTURES"
