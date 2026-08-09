#!/usr/bin/env bash
set -euo pipefail

APP="${1:-}"
REQUESTED_IDENTITY="${2:-}"

if [[ -z "$APP" || ! -d "$APP" || "${APP##*.}" != "app" ]]; then
    echo "Usage: $0 /path/to/Daydream.app [identity|-]" >&2
    exit 64
fi

if [[ -n "$REQUESTED_IDENTITY" ]]; then
    SIGNING_IDENTITY="$REQUESTED_IDENTITY"
elif [[ -n "${DEVELOPER_ID_APPLICATION:-}" ]]; then
    SIGNING_IDENTITY="$DEVELOPER_ID_APPLICATION"
else
    SIGNING_IDENTITY="-"
fi

if [[ "$SIGNING_IDENTITY" == "-" ]]; then
    codesign --force --sign - "$APP"
else
    codesign --force --sign "$SIGNING_IDENTITY" --timestamp --options runtime "$APP"
fi

codesign --verify --deep --strict --verbose=2 "$APP"
echo "Signed and verified $APP with $SIGNING_IDENTITY"
