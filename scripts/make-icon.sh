#!/bin/bash
# Generate <app>/Contents/Resources/AppIcon.icns from Resources/AppIcon.png (app defaults to Shark.app).
set -e
cd "$(dirname "$0")/.."
app=${1:-Shark.app}
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT
set_dir="$temp_dir/AppIcon.iconset"
mkdir -p "$set_dir" "$app"/Contents/Resources
for s in 16 32 128 256 512; do
  sips -z $s $s Resources/AppIcon.png --out "$set_dir/icon_${s}x${s}.png" >/dev/null
  sips -z $((s*2)) $((s*2)) Resources/AppIcon.png --out "$set_dir/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$set_dir" -o "$app"/Contents/Resources/AppIcon.icns
/usr/libexec/PlistBuddy -c "Delete :CFBundleIconFile" "$app"/Contents/Info.plist 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$app"/Contents/Info.plist
