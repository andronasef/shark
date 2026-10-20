#!/bin/bash
# Build, bundle into Shark.app, and relaunch.
set -e
cd "$(dirname "$0")/.."
swift build "$@"
scripts/make-icon.sh
mkdir -p Shark.app/Contents/Resources/Icons
cp -R Assets/Icons/ Shark.app/Contents/Resources/Icons/
cp .build/debug/Shark Shark.app/Contents/MacOS/Shark
codesign --force --deep --sign - Shark.app 2>/dev/null || true
pkill -x Shark 2>/dev/null || true
sleep 0.5
open Shark.app
