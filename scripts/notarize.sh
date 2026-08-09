#!/usr/bin/env bash
set -euo pipefail

ARTIFACT="${1:-}"
STAPLE_TARGET="${2:-$ARTIFACT}"

if [[ -z "${APPLE_ID:-}" || -z "${APPLE_TEAM_ID:-}" || -z "${APPLE_APP_PASSWORD:-}" ]]; then
    echo "Set APPLE_ID, APPLE_TEAM_ID, and APPLE_APP_PASSWORD before notarization." >&2
    exit 64
fi

if [[ ! -f "$ARTIFACT" ]]; then
    echo "The submission artifact does not exist: $ARTIFACT" >&2
    exit 66
fi

case "$ARTIFACT" in
    *.dmg|*.zip) ;;
    *)
        echo "Submit a .dmg or .zip artifact to notarytool." >&2
        exit 64
        ;;
esac

if [[ ! -e "$STAPLE_TARGET" ]]; then
    echo "The staple target does not exist: $STAPLE_TARGET" >&2
    exit 66
fi

case "$STAPLE_TARGET" in
    *.app|*.dmg) ;;
    *)
        echo "Staple target must be a .app or .dmg artifact." >&2
        exit 64
        ;;
esac

xcrun notarytool submit "$ARTIFACT" \
    --apple-id "$APPLE_ID" \
    --team-id "$APPLE_TEAM_ID" \
    --password "$APPLE_APP_PASSWORD" \
    --wait
xcrun stapler staple "$STAPLE_TARGET"
xcrun stapler validate "$STAPLE_TARGET"
echo "Notarized and stapled $STAPLE_TARGET"
