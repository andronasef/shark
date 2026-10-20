# Releasing Shark

## Choose the distribution route

The [release action](../.github/workflows/release.yml) builds a universal app for Apple silicon and Intel, signs it with Developer ID, notarizes it, staples Apple's ticket, and publishes a ZIP and SHA-256 checksum on GitHub Releases. Tests, signature verification, notarization acceptance, and Gatekeeper assessment must pass before publication.

**This action publishes direct downloads, not Mac App Store submissions.** Developer ID is Apple's certificate for distribution outside the store. The Mac App Store needs a separate distribution identity and a sandbox-compatible app. See [Apple's distribution overview](https://developer.apple.com/macos/distribution/).

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

The action accepts `vMAJOR.MINOR.PATCH` and semver prerelease tags (e.g. `v1.0.0-alpha`). It publishes `Shark-<version>.zip` and `Shark-<version>.zip.sha256` with generated release notes (marked as prerelease when appropriate). A failure leaves the tag in place without publishing a new release. Fix the cause, then rerun the failed action for that tag when the code is unchanged; use a new version tag if you change the code. An existing release is never silently overwritten.

To check the downloaded ZIP, put both release assets in the same directory and run:

```sh
shasum -a 256 -c Shark-1.0.0-alpha.zip.sha256
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

The script stops when credentials are missing, notarization is rejected, stapling fails, or Gatekeeper rejects the app. Never publish the local ad hoc ZIP in place of a signed release.

## Mac App Store preparation

Shark is **not ready for App Store submission yet**. This is application work, not just an upload setting:

- Enable [App Sandbox](https://developer.apple.com/documentation/security/app-sandbox), required for store distribution. This repository currently has no sandbox entitlements or store provisioning setup.
- Add a user-selected folder access flow and [security-scoped bookmarks](https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox). Navigation, favorites, restored tabs, previews, file operations, and file watching must retain valid access across launches. Currently Shark saves paths and opens directories directly.
- Audit the embedded login shell in `TerminalView.swift`, shell directory synchronization, and external compression processes in `FileOperationsService.swift` under sandbox restrictions. Child processes inherit restrictions; an unrestricted shell cannot be assumed to work. Decide the store edition's supported terminal behavior and test it.
- Register the final bundle ID and App Store Connect record. Configure the appropriate Mac App Store application/installer distribution certificates and provisioning profile, with matching entitlements and an increasing build number.
- Package and validate the store build, upload it using Apple's supported tools, then complete screenshots, privacy information, support links, and review notes in App Store Connect.

Once the sandboxed edition is working and tested, add a separate App Store workflow. Do not upload the Developer ID ZIP as a store build or simply switch on sandbox signing for the current app: that would leave its file access and terminal behavior unverified.
