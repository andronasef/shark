#!/usr/bin/env bash
# Build a universal app and ZIP. Public downloads require Developer ID notarization.
# Usage: scripts/package.sh MAJOR.MINOR.PATCH[-PRERELEASE]
set -euo pipefail

cd "$(dirname "$0")/.."

version="${1:-1.0.0}"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]] || { echo "Version must be MAJOR.MINOR.PATCH or semver prerelease (e.g. 1.0.0-alpha)" >&2; exit 1; }
identity="${SIGN_IDENTITY:--}"
notarize=0
if [[ "${REQUIRE_NOTARIZATION:-0}" == 1 || -n "${NOTARY_APPLE_ID:-}${NOTARY_TEAM_ID:-}${NOTARY_PASSWORD:-}" ]]; then
  [[ "$identity" != - && -n "$identity" ]] || { echo "Notarization requires SIGN_IDENTITY." >&2; exit 1; }
  : "${NOTARY_APPLE_ID:?Set NOTARY_APPLE_ID}"
  : "${NOTARY_TEAM_ID:?Set NOTARY_TEAM_ID}"
  : "${NOTARY_PASSWORD:?Set NOTARY_PASSWORD}"
  notarize=1
fi

echo "Packaging Shark v$version..."

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
[ -f Resources/GoogleService-Info.plist ] && cp Resources/GoogleService-Info.plist "$app/Contents/Resources/"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $version" -c "Set :CFBundleVersion $version" "$app/Contents/Info.plist"
cp "$bin/Shark" "$app/Contents/MacOS/"
cp -R Assets/Icons "$app/Contents/Resources/Icons"
scripts/make-icon.sh "$app"

# Extract release dSYM debug symbols for crash reporting
dsymutil "$bin/Shark" -o "$staging/Shark.app.dSYM"

# Embed provisioning profile if provided or if packaging sandboxed app with Entitlements/Shark.provisionprofile
profile_path=""
if [[ -n "${PROVISIONING_PROFILE:-}" && -f "${PROVISIONING_PROFILE}" ]]; then
  profile_path="${PROVISIONING_PROFILE}"
elif [[ "${APP_SANDBOX:-0}" == 1 && -f "Entitlements/Shark.provisionprofile" ]]; then
  profile_path="Entitlements/Shark.provisionprofile"
fi

if [[ -n "$profile_path" ]]; then
  echo "==> Embedding provisioning profile: $profile_path"
  cp "$profile_path" "$app/Contents/embedded.provisionprofile"
fi

# Strip all extended attributes (e.g. com.apple.quarantine) before codesigning.
# App Store and TestFlight validation reject bundles with com.apple.quarantine (ITMS-91109).
xattr -cr "$app"

entitlements_args=()
if [[ "${APP_SANDBOX:-0}" == 1 ]]; then
  entitlements_file="$staging/Shark.entitlements"
  cp Entitlements/Shark.entitlements "$entitlements_file"

  # Ensure application-identifier and developer team-identifier match embedded provisioning profile (ITMS-90886)
  if [[ -f "$app/Contents/embedded.provisionprofile" ]]; then
    profile_entitlements="$staging/profile-entitlements.plist"
    if security cms -D -i "$app/Contents/embedded.provisionprofile" | plutil -extract "Entitlements" xml1 -o "$profile_entitlements" - 2>/dev/null; then
      prof_app_id=$(/usr/libexec/PlistBuddy -c "Print :com.apple.application-identifier" "$profile_entitlements" 2>/dev/null || true)
      prof_team_id=$(/usr/libexec/PlistBuddy -c "Print :com.apple.developer.team-identifier" "$profile_entitlements" 2>/dev/null || true)
      if [[ -n "$prof_app_id" ]]; then
        /usr/libexec/PlistBuddy -c "Delete :com.apple.application-identifier" "$entitlements_file" 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Add :com.apple.application-identifier string $prof_app_id" "$entitlements_file"
      fi
      if [[ -n "$prof_team_id" ]]; then
        /usr/libexec/PlistBuddy -c "Delete :com.apple.developer.team-identifier" "$entitlements_file" 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Add :com.apple.developer.team-identifier string $prof_team_id" "$entitlements_file"
      fi
    fi
  fi
  entitlements_args=(--entitlements "$entitlements_file")
elif [[ -f "Entitlements/Shark-Direct.entitlements" ]]; then
  entitlements_args=(--entitlements Entitlements/Shark-Direct.entitlements)
fi

# Remove any ad-hoc signature applied during compilation so codesign generates a clean signature
codesign --remove-signature "$app/Contents/MacOS/Shark" 2>/dev/null || true

timestamp_args=()
if [[ "$notarize" == 1 || "${REQUIRE_TIMESTAMP:-0}" == 1 ]]; then
  timestamp_args=(--timestamp)
elif curl -s --connect-timeout 2 http://timestamp.apple.com/ts01 >/dev/null 2>&1; then
  timestamp_args=(--timestamp)
fi

if [[ "$identity" == - ]]; then
  codesign --force ${entitlements_args[@]+"${entitlements_args[@]}"} --sign - "$app"
else
  codesign --force --options runtime ${timestamp_args[@]+"${timestamp_args[@]}"} ${entitlements_args[@]+"${entitlements_args[@]}"} --sign "$identity" "$app"
fi
codesign --verify --strict "$app"
ditto -c -k --keepParent "$app" "$archive"

if [[ "$notarize" == 1 ]]; then
  echo "Submitting $archive to Apple Notary Service..."
  xcrun notarytool submit "$archive" --wait \
    --apple-id "$NOTARY_APPLE_ID" --team-id "$NOTARY_TEAM_ID" --password "$NOTARY_PASSWORD"
  echo "Notarization completed successfully. Stapling ticket..."
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
