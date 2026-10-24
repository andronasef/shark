#!/bin/bash
# Build, bundle into Shark.app, and relaunch.
set -e
cd "$(dirname "$0")/.."
# -interposable + implicit-dynamic let InjectionIII swap code into the running app.
swift build -Xswiftc -Xfrontend -Xswiftc -enable-implicit-dynamic -Xlinker -interposable "$@"
mkdir -p Shark.app/Contents/MacOS
cp Resources/Info.plist Shark.app/Contents/
scripts/make-icon.sh
mkdir -p Shark.app/Contents/Resources/Icons
cp -R Assets/Icons/ Shark.app/Contents/Resources/Icons/
[ -f Resources/GoogleService-Info.plist ] && cp Resources/GoogleService-Info.plist Shark.app/Contents/Resources/
cp .build/debug/Shark Shark.app/Contents/MacOS/Shark
# Bundle.module resolves localized SwiftPM resources from the app resource directory.
for bundle in .build/debug/Shark_*.bundle; do
    [ -d "$bundle" ] || continue
    rm -rf "Shark.app/Contents/Resources/$(basename "$bundle")"
    cp -R "$bundle" Shark.app/Contents/Resources/
done
# Stable "Shark Dev" cert keeps macOS permission grants across builds; ad hoc if absent.
security find-identity -v -p codesigning | grep -q "Shark Dev" && id="Shark Dev" || id=-
codesign --force --deep --sign "$id" Shark.app 2>/dev/null || true
pkill -x Shark 2>/dev/null || true
sleep 0.5
open Shark.app
