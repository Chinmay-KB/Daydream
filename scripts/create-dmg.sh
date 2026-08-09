#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="${1:-}"
DMG="${2:-}"
STAGE=""
MOUNT_POINT=""

cleanup() {
    if [[ -n "$MOUNT_POINT" && "$MOUNT_POINT" == /Volumes/* ]]; then
        hdiutil detach "$MOUNT_POINT" -quiet || true
    fi
    if [[ -n "$STAGE" && "$STAGE" == "$ROOT/.build/dmg-stage."* ]]; then
        rm -rf "$STAGE"
    fi
}
trap cleanup EXIT

if [[ -z "$APP" || ! -d "$APP" || "${APP##*.}" != "app" || -z "$DMG" || "${DMG##*.}" != "dmg" ]]; then
    echo "Usage: $0 /path/to/Daydream.app /path/to/Daydream.dmg" >&2
    exit 64
fi

if [[ -e "$DMG" ]]; then
    echo "Refuse to replace an existing DMG: $DMG" >&2
    exit 73
fi

mkdir -p "$ROOT/.build"
STAGE="$(mktemp -d "$ROOT/.build/dmg-stage.XXXXXX")"
cp -R "$APP" "$STAGE/Daydream.app"
ln -s /Applications "$STAGE/Applications"

hdiutil create -volname "Daydream" -srcfolder "$STAGE" -format UDZO "$DMG"
MOUNT_POINT="$(hdiutil attach -readonly -nobrowse "$DMG" | awk '/\/Volumes\// { print $NF; exit }')"

if [[ -z "$MOUNT_POINT" || ! -d "$MOUNT_POINT/Daydream.app" || ! -L "$MOUNT_POINT/Applications" ]]; then
    echo "DMG content verification failed." >&2
    exit 1
fi

echo "Created and verified $DMG"
