#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

DSYM_PATH="${1:-dist/Shark.app.dSYM}"
PLIST_PATH="${2:-Resources/GoogleService-Info.plist}"
UPLOAD_TOOL=".build/checkouts/firebase-ios-sdk/Crashlytics/upload-symbols"

if [[ ! -f "$UPLOAD_TOOL" ]]; then
    echo "Error: Crashlytics upload-symbols tool not found at $UPLOAD_TOOL. Run 'swift build' first." >&2
    exit 1
fi

if [[ ! -f "$PLIST_PATH" ]]; then
    echo "Error: GoogleService-Info.plist not found at $PLIST_PATH" >&2
    exit 1
fi

if [[ ! -d "$DSYM_PATH" ]]; then
    echo "Error: dSYM bundle not found at $DSYM_PATH" >&2
    exit 1
fi

echo "==> Uploading dSYM symbols to Firebase Crashlytics..."
"$UPLOAD_TOOL" -gsp "$PLIST_PATH" -p mac "$DSYM_PATH"
echo "==> Upload complete."
