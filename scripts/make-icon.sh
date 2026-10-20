#!/bin/bash
# Generate Shark.app/Contents/Resources/AppIcon.icns from Resources/AppIcon.png.
set -e
cd "$(dirname "$0")/.."
set_dir=$(mktemp -d)/AppIcon.iconset
mkdir -p "$set_dir" Shark.app/Contents/Resources
for s in 16 32 128 256 512; do
  sips -z $s $s Resources/AppIcon.png --out "$set_dir/icon_${s}x${s}.png" >/dev/null
  sips -z $((s*2)) $((s*2)) Resources/AppIcon.png --out "$set_dir/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$set_dir" -o Shark.app/Contents/Resources/AppIcon.icns
/usr/libexec/PlistBuddy -c "Delete :CFBundleIconFile" Shark.app/Contents/Info.plist 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" Shark.app/Contents/Info.plist
