#!/bin/bash
# Builds Vibe Awake.app.
#
# By default this produces an ad-hoc signed bundle, which runs on this machine only --
# fine for development. Pass --release to sign with the Developer ID certificate so the
# app can be distributed; notarization is a separate step (Scripts/notarize.sh).
set -euo pipefail
cd "$(dirname "$0")/.."

APP_DISPLAY_NAME="Vibe Awake"
BUNDLE_ID="com.ychof.vibeawake"
VERSION="${VERSION:-1.0.1}"
BUILD_NUMBER="${BUILD_NUMBER:-2}"
# Override with e.g. SIGN_IDENTITY="Developer ID Application: Someone (TEAMID)"
SIGN_IDENTITY="${SIGN_IDENTITY:-Developer ID Application: kenta yamamoto (LAS46NJ6P7)}"

BUILD_DIR=".build/release"
DIST_DIR="dist"
APP_DIR="${DIST_DIR}/${APP_DISPLAY_NAME}.app"

RELEASE=0
[ "${1:-}" = "--release" ] && RELEASE=1

echo "Building release binary..."
swift build -c release

rm -rf "$DIST_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

cp "$BUILD_DIR/VibeAwake" "$APP_DIR/Contents/MacOS/VibeAwake"

# Localizations live as .lproj bundles in Resources/ and are copied verbatim, so
# NSLocalizedString finds them in Bundle.main.
LOCALIZATIONS=""
for lproj in Resources/*.lproj; do
  [ -d "$lproj" ] || continue
  cp -R "$lproj" "$APP_DIR/Contents/Resources/"
  LOCALIZATIONS="${LOCALIZATIONS}        <string>$(basename "$lproj" .lproj)</string>
"
done

ICON_KEYS=""
if [ -f "Resources/AppIcon.icns" ]; then
  cp "Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
  ICON_KEYS="    <key>CFBundleIconFile</key>
    <string>AppIcon</string>"
fi

cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>VibeAwake</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>
    <string>${APP_DISPLAY_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${BUILD_NUMBER}</string>
${ICON_KEYS}
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleLocalizations</key>
    <array>
${LOCALIZATIONS}    </array>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 kenta.yamamoto. MIT License.</string>
</dict>
</plist>
PLIST

if [ "$RELEASE" = "1" ]; then
  echo "Signing with: $SIGN_IDENTITY"
  # --options runtime enables the Hardened Runtime, which notarization requires.
  # --timestamp embeds a trusted timestamp so the signature stays valid after the
  # certificate expires.
  codesign --force --options runtime --timestamp \
    --sign "$SIGN_IDENTITY" \
    "$APP_DIR"
  codesign --verify --strict --verbose=2 "$APP_DIR"
  echo
  echo "Signed. Next: ./Scripts/notarize.sh"
else
  codesign --force --sign - "$APP_DIR"
  echo
  echo "Ad-hoc signed (development only). Use --release to sign for distribution."
fi

echo "Built: $APP_DIR"
