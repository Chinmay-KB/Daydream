#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

swift build -c release

APP="$ROOT/Daydream.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$ROOT/.build/release/Daydream" "$APP/Contents/MacOS/Daydream"
cp "$ROOT/Info.plist" "$APP/Contents/Info.plist"

echo "Built $APP"
open "$APP"
