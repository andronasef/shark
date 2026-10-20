#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

VERSION="${1:-1.0.0}"

# Auto-detect Apple Distribution certificate if not explicitly provided
DETECTED_APP_ID=$(security find-identity -v | grep -o 'Apple Distribution: [^"]*' | head -n 1 || true)
APP_IDENTITY="${APP_IDENTITY:-${DETECTED_APP_ID}}"

# Auto-detect Mac Installer certificate if not explicitly provided
DETECTED_INST_ID=$(security find-identity -v | grep -o '\(3rd Party Mac Developer Installer\|Mac Installer Distribution\): [^"]*' | head -n 1 || true)
INSTALLER_IDENTITY="${INSTALLER_IDENTITY:-${DETECTED_INST_ID}}"

if [[ -z "$APP_IDENTITY" ]]; then
    echo "Error: Could not find an 'Apple Distribution' certificate in Keychain." >&2
    exit 1
fi

if [[ -z "$INSTALLER_IDENTITY" ]]; then
    echo "Error: Could not find a 'Mac Installer Distribution' or '3rd Party Mac Developer Installer' certificate in Keychain." >&2
    exit 1
fi

echo "==> Packaging Shark v${VERSION} for Mac App Store..."
echo "==> App Signing Identity: ${APP_IDENTITY}"
echo "==> Installer Identity:   ${INSTALLER_IDENTITY}"

# Step 1: Package sandboxed Shark.app using package.sh
APP_SANDBOX=1 SIGN_IDENTITY="${APP_IDENTITY}" bash scripts/package.sh "${VERSION}"

APP_PATH="dist/Shark.app"
PKG_PATH="dist/Shark-${VERSION}.pkg"

if [[ ! -d "$APP_PATH" ]]; then
    echo "Error: $APP_PATH not found" >&2
    exit 1
fi

echo "==> Creating signed macOS Installer Package (.pkg)..."
# Strip any extended attributes on the app bundle and output package
xattr -cr "$APP_PATH"
productbuild --component "$APP_PATH" /Applications --sign "$INSTALLER_IDENTITY" "$PKG_PATH"
xattr -c "$PKG_PATH" 2>/dev/null || true

echo "==> Verifying package signature..."
pkgutil --check-signature "$PKG_PATH"

echo ""
echo "============================================================"
echo "SUCCESS: Created Mac App Store package:"
echo "  $PKG_PATH"
echo ""
echo "You can now upload this .pkg to App Store Connect using:"
echo "  1. The free 'Transporter' app from the Mac App Store (drag & drop $PKG_PATH)"
echo "  OR"
echo "  2. xcrun altool --upload-app -f \"$PKG_PATH\" -t macos -u \"<your-apple-id>\" -p \"<app-specific-password>\""
echo "============================================================"
