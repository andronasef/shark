#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

VERSION="${1:-1.0.0}"
APP_IDENTITY="${APP_IDENTITY:-Apple Distribution: Andrew Nasef (B9P7Y6B9F5)}"
INSTALLER_IDENTITY="${INSTALLER_IDENTITY:-Mac Installer Distribution: Andrew Nasef (B9P7Y6B9F5)}"

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
productbuild --component "$APP_PATH" /Applications --sign "$INSTALLER_IDENTITY" "$PKG_PATH"

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
