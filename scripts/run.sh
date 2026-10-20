#!/bin/bash
# Build, bundle into Shark.app, and relaunch.
set -e
cd "$(dirname "$0")/.."
swift build "$@"
scripts/make-icon.sh
cp .build/debug/Shark Shark.app/Contents/MacOS/Shark
pkill -x Shark 2>/dev/null || true
sleep 0.5
open Shark.app
