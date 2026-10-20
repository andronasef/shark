#!/bin/bash
# Build, bundle into Shark.app, and relaunch.
set -e
cd "$(dirname "$0")/.."
# -interposable + implicit-dynamic let InjectionIII swap code into the running app.
swift build -Xswiftc -Xfrontend -Xswiftc -enable-implicit-dynamic -Xlinker -interposable "$@"
scripts/make-icon.sh
mkdir -p Shark.app/Contents/Resources/Icons
cp -R Assets/Icons/ Shark.app/Contents/Resources/Icons/
cp .build/debug/Shark Shark.app/Contents/MacOS/Shark
# Stable "Shark Dev" cert keeps macOS permission grants across builds; ad hoc if absent.
security find-identity -v -p codesigning | grep -q "Shark Dev" && id="Shark Dev" || id=-
codesign --force --deep --sign "$id" Shark.app 2>/dev/null || true
pkill -x Shark 2>/dev/null || true
sleep 0.5
open Shark.app
