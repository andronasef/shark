# Releasing Shark

## Choose the distribution route

The [release action](../.github/workflows/release.yml) builds a universal app for Apple silicon and Intel, signs it with Developer ID, notarizes it, staples Apple's ticket, and publishes a DMG installer and its SHA-256 checksum on GitHub Releases. Tests, signature verification, notarization acceptance, and Gatekeeper assessment must pass before publication.

**The DMG job publishes direct downloads only.** Developer ID is Apple's certificate for distribution outside the store. The separate `appstore` job in the same workflow uploads a sandboxed build to App Store Connect (see below); it never submits for review. See [Apple's distribution overview](https://developer.apple.com/macos/distribution/).

## One-time GitHub setup

1. Push this repository to GitHub. No remote is configured in this checkout yet.
2. Review `Resources/Info.plist`. The bundle identifier is set to `com.increasinglabs.shark`; keep it stable afterward.
3. In Keychain Access, export your **Developer ID Application** certificate **with its private key** as a password-protected `.p12`. An Apple Development certificate is not a substitute.
4. Open the GitHub repository's **Settings → Secrets and variables → Actions** and add these repository secrets:

| Secret | Value |
| --- | --- |
| `DEVELOPER_ID_P12_BASE64` | Base64 contents of the exported `.p12` (`base64 -i DeveloperID.p12`, pasted as one value). |
| `DEVELOPER_ID_P12_PASSWORD` | The password you chose when exporting it. |
| `SIGN_IDENTITY` | Full identity name, such as `Developer ID Application: Your Name (TEAMID)`. |
| `NOTARY_APPLE_ID` | Your Apple Account email. |
| `NOTARY_TEAM_ID` | Your Apple Developer team ID. |
| `NOTARY_PASSWORD` | An [app-specific password](https://support.apple.com/102654) for notarization, not your account password. |

Keep certificates, private keys, and passwords out of Git. The action imports the certificate into a temporary keychain and removes it at the end, including on failure. The runner must have Xcode 26 or newer selected; `macos-26` supplies the SDK needed by Shark's Liquid Glass chrome.

## Publish a version

1. Update `CHANGELOG.md` and move the release's entries under a dated version heading.
2. Build and test, then check the app on a clean Mac. Verify file access, split panes, previews, and the terminal. The universal package targets macOS 14+, but testing on supported macOS versions is still needed.
3. Commit the release, then push an unused version tag:

   ```sh
   git tag v1.0.0-alpha
   git push origin v1.0.0-alpha
   ```

The action accepts `vMAJOR.MINOR.PATCH` and semver prerelease tags (e.g. `v1.0.0-alpha`). It publishes `Shark-<version>.dmg` and `Shark-<version>.dmg.sha256` with generated release notes (marked as prerelease when appropriate). A failure leaves the tag in place without publishing a new release. Fix the cause, then rerun the failed action for that tag when the code is unchanged; use a new version tag if you change the code. An existing release is never silently overwritten.

To check a download, put the file and its `.sha256` in the same directory and run:

```sh
shasum -a 256 -c Shark-1.0.0-alpha.dmg.sha256
```

## Package locally

```sh
scripts/package.sh 1.0.0-alpha
```

This creates an **ad hoc signed development package** in `dist/`, without notarization. It is for local validation and is not suitable for public downloads. Run `bash scripts/test-package.sh` to check release validation without compiling. Release build products use `.build/package` so they do not share the live development app's hot reload build. `SHARK_BUILD_PATH` can override this scratch directory.

For a public package, first import your Developer ID certificate into your keychain, set `SIGN_IDENTITY` and the three `NOTARY_*` environment variables listed above, then run:

```sh
REQUIRE_NOTARIZATION=1 scripts/package.sh 1.0.0-alpha
```

The script stops when credentials are missing, notarization is rejected, stapling fails, or Gatekeeper rejects the app. Never publish the local ad hoc build in place of a signed release.

## Mac App Store upload

On every `v*` tag the `appstore` job runs `scripts/package-appstore.sh`, which builds the sandboxed app (`Entitlements/Shark.entitlements`), signs it with Apple Distribution, wraps it in a Mac Installer-signed `.pkg`, and uploads it with `xcrun altool`. It does nothing until `APPSTORE_API_KEY_ID` exists, so DMG-only releases keep working.

Versions: the App Store only accepts `MAJOR.MINOR.PATCH`, so `v1.0.0-alpha.1` uploads as `1.0.0`. The build number (`CFBundleVersion`) is the workflow run number, which always increases.

Repository secrets:

| Secret | Value |
| --- | --- |
| `APPSTORE_P12_BASE64`, `APPSTORE_P12_PASSWORD` | One `.p12` exported from Keychain Access holding both the **Apple Distribution** and **3rd Party Mac Developer Installer** certificates (select both, export), base64 encoded |
| `APPSTORE_PROFILE_BASE64` | The Mac App Store provisioning profile for `com.increasinglabs.shark` (the file kept at `Entitlements/Shark.provisionprofile`, which is git-ignored), base64 encoded |
| `APPSTORE_API_KEY_ID`, `APPSTORE_API_ISSUER_ID`, `APPSTORE_API_KEY_P8_BASE64` | An App Store Connect API key (Users and Access › Integrations) with the App Manager role, and its `.p8` file base64 encoded |

Encode with `base64 -i file | pbcopy`. After the upload processes in App Store Connect, pick the build on the app version, finish screenshots, privacy and review notes, and submit it yourself.

Before the first submission, verify the sandboxed build by running it: folder access and bookmarks across launches, the embedded terminal, and compression behave differently under App Sandbox. Run `bash scripts/package-appstore.sh 1.0.0` locally to produce the same package.
