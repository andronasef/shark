#!/bin/bash
# Build a universal app and ZIP. Public downloads require Developer ID notarization.
# Usage: scripts/package.sh MAJOR.MINOR.PATCH[-PRERELEASE]
set -euo pipefail
cd "$(dirname "$0")/.."
version=${1:?usage: scripts/package.sh <version>}
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]] || { echo "Version must be MAJOR.MINOR.PATCH or semver prerelease (e.g. 1.0.0-alpha)" >&2; exit 1; }
identity=${SIGN_IDENTITY:--}
notarize=0
if [[ "${REQUIRE_NOTARIZATION:-0}" == 1 || -n "${NOTARY_APPLE_ID:-}${NOTARY_TEAM_ID:-}${NOTARY_PASSWORD:-}" ]]; then
  [[ "$identity" != - && -n "$identity" ]] || { echo "Notarization requires SIGN_IDENTITY." >&2; exit 1; }
  : "${NOTARY_APPLE_ID:?Set NOTARY_APPLE_ID}"
  : "${NOTARY_TEAM_ID:?Set NOTARY_TEAM_ID}"
  : "${NOTARY_PASSWORD:?Set NOTARY_PASSWORD}"
  notarize=1
fi

# Keep release products separate from the development app and hot reload flags.
build_args=(-c release --arch arm64 --arch x86_64 --scratch-path "${SHARK_BUILD_PATH:-.build/package}")
swift build "${build_args[@]}"
bin=$(swift build "${build_args[@]}" --show-bin-path)
architectures=" $(lipo -archs "$bin/Shark") "
[[ "$architectures" == *" arm64 "* && "$architectures" == *" x86_64 "* ]] || { echo "Expected an arm64 + x86_64 executable" >&2; exit 1; }

mkdir -p dist
staging=$(mktemp -d "$PWD/dist/.package.XXXXXX")
trap 'rm -rf "$staging"' EXIT
app="$staging/Shark.app"
archive="$staging/Shark-$version.zip"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp Resources/Info.plist "$app/Contents/"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $version" -c "Set :CFBundleVersion $version" "$app/Contents/Info.plist"
cp "$bin/Shark" "$app/Contents/MacOS/"
cp -R Assets/Icons "$app/Contents/Resources/Icons"
scripts/make-icon.sh "$app"

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
rm -rf dist/Shark.app
mv "$app" dist/Shark.app
mv "$archive" "dist/Shark-$version.zip"
(cd dist && shasum -a 256 "Shark-$version.zip" > "Shark-$version.zip.sha256")
echo "dist/Shark-$version.zip"
