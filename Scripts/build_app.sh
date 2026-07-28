#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

APP_DISPLAY_NAME="Vide Sleep Blocker"
BUNDLE_ID="dev.vide.sleepblocker"
BUILD_DIR=".build/release"
DIST_DIR="dist"
APP_DIR="${DIST_DIR}/${APP_DISPLAY_NAME}.app"

echo "Building release binary..."
swift build -c release

rm -rf "$DIST_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$BUILD_DIR/SleepBlocker" "$APP_DIR/Contents/MacOS/SleepBlocker"

cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>SleepBlocker</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>
    <string>${APP_DISPLAY_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHumanReadableCopyright</key>
    <string>Personal use.</string>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$APP_DIR"

echo "Built: $APP_DIR"
echo "Run with: open \"$APP_DIR\""
