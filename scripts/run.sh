#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TAG="${1:-v0.1.0}"
cd "$ROOT"

"$ROOT/scripts/build-app.sh" "$TAG"

APP="$ROOT/.build/Daydream-app/Daydream.app"

echo "Built $APP"
open "$APP"
