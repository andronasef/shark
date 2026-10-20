#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

version="${1:-1.0.0}"
notarize="${NOTARIZE:-0}"
identity="${SIGN_IDENTITY:--}"

echo "Packaging Shark v$version..."
scripts/build-release.sh

bin=".build/apple/Products/Release"
staging="$(mktemp -d)"
trap 'rm -rf "$staging"' EXIT

app="$staging/Shark.app"
archive="$staging/Shark-$version.zip"

mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp Resources/Info.plist "$app/Contents/"
[ -f Resources/GoogleService-Info.plist ] && cp Resources/GoogleService-Info.plist "$app/Contents/Resources/"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $version" -c "Set :CFBundleVersion $version" "$app/Contents/Info.plist"
cp "$bin/Shark" "$app/Contents/MacOS/"
cp -R Assets/Icons "$app/Contents/Resources/Icons"
scripts/make-icon.sh "$app"

# Extract release dSYM debug symbols for crash reporting
dsymutil "$bin/Shark" -o "$staging/Shark.app.dSYM"

# Embed provisioning profile if provided (required for TestFlight on macOS)
if [[ -n "${PROVISIONING_PROFILE:-}" && -f "${PROVISIONING_PROFILE}" ]]; then
  echo "==> Embedding provisioning profile: $PROVISIONING_PROFILE"
  cp "$PROVISIONING_PROFILE" "$app/Contents/embedded.provisionprofile"
elif [[ -f "Entitlements/Shark.provisionprofile" ]]; then
  echo "==> Embedding provisioning profile: Entitlements/Shark.provisionprofile"
  cp "Entitlements/Shark.provisionprofile" "$app/Contents/embedded.provisionprofile"
fi

entitlements_args=()
if [[ "${APP_SANDBOX:-0}" == 1 ]]; then
  entitlements_args=(--entitlements Entitlements/Shark.entitlements)
elif [[ -f "Entitlements/Shark-Direct.entitlements" ]]; then
  entitlements_args=(--entitlements Entitlements/Shark-Direct.entitlements)
fi

if [[ "$identity" == - ]]; then
  codesign --force "${entitlements_args[@]}" --sign - "$app"
else
  codesign --force --options runtime --timestamp "${entitlements_args[@]}" --sign "$identity" "$app"
fi
codesign --verify --strict "$app"
ditto -c -k --keepParent "$app" "$archive"

if [[ "$notarize" == 1 ]]; then
  xcrun notarytool submit "$archive" --wait --output-format json \
    --apple-id "$NOTARY_APPLE_ID" --team-id "$NOTARY_TEAM_ID" --password "$NOTARY_PASSWORD" > "$staging/notary.json"
  cat "$staging/notary.json"
  status=$(plutil -extract status raw -o - "$staging/notary.json")
  [[ "$status" == Accepted ]] || { echo "Notarization was not accepted: $status" >&2; exit 1; }
  xcrun stapler staple "$app"
  xcrun stapler validate "$app"
  spctl --assess --type execute --verbose=2 "$app"
  rm "$archive"
  ditto -c -k --keepParent "$app" "$archive"
fi
# Replace only this package, leaving other release artifacts intact.
rm -rf dist/Shark.app dist/Shark.app.dSYM
mv "$app" dist/Shark.app
mv "$staging/Shark.app.dSYM" dist/Shark.app.dSYM
mv "$archive" "dist/Shark-$version.zip"
(cd dist && shasum -a 256 "Shark-$version.zip" > "Shark-$version.zip.sha256")

if [[ "${UPLOAD_CRASHLYTICS_SYMBOLS:-0}" == 1 ]]; then
  scripts/upload-symbols.sh "dist/Shark.app.dSYM"
fi

echo "dist/Shark-$version.zip"
