#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

"$ROOT/scripts/build-app.sh" v0.1.0

APP="$ROOT/.build/Daydream-app/Daydream.app"

echo "Built $APP"
open "$APP"
