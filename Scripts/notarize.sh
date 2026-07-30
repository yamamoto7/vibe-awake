#!/bin/bash
# Notarizes the built app and packages it as a DMG for distribution.
#
# Requires a Developer ID signed bundle (./Scripts/build_app.sh --release) and notarytool
# credentials stored under a keychain profile:
#   xcrun notarytool store-credentials "AC_PASSWORD" \
#     --apple-id <id> --team-id <team> --password <app-specific-password>
set -euo pipefail
cd "$(dirname "$0")/.."

APP_DISPLAY_NAME="Vibe Awake"
VERSION="${VERSION:-1.0.0}"
KEYCHAIN_PROFILE="${KEYCHAIN_PROFILE:-AC_PASSWORD}"
SIGN_IDENTITY="${SIGN_IDENTITY:-Developer ID Application: kenta yamamoto (LAS46NJ6P7)}"

DIST_DIR="dist"
APP_DIR="${DIST_DIR}/${APP_DISPLAY_NAME}.app"
DMG_PATH="${DIST_DIR}/VibeAwake-${VERSION}.dmg"

if [ ! -d "$APP_DIR" ]; then
  echo "error: $APP_DIR not found. Run ./Scripts/build_app.sh --release first." >&2
  exit 1
fi

# Refuse to notarize an ad-hoc signature; the submission would fail after a long wait.
if ! codesign -dv "$APP_DIR" 2>&1 | grep -q "Authority=Developer ID Application"; then
  echo "error: $APP_DIR is not Developer ID signed. Run ./Scripts/build_app.sh --release." >&2
  exit 1
fi

echo "==> Building DMG"
rm -f "$DMG_PATH"
STAGING=$(mktemp -d)
cp -R "$APP_DIR" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
hdiutil create -volname "$APP_DISPLAY_NAME" -srcfolder "$STAGING" -ov -format UDZO "$DMG_PATH" >/dev/null
rm -rf "$STAGING"

echo "==> Signing DMG"
codesign --force --timestamp --sign "$SIGN_IDENTITY" "$DMG_PATH"

echo "==> Submitting for notarization (this can take a few minutes)"
xcrun notarytool submit "$DMG_PATH" --keychain-profile "$KEYCHAIN_PROFILE" --wait

echo "==> Stapling"
# Staple the DMG and the app inside it, so the app stays notarized once dragged out.
xcrun stapler staple "$DMG_PATH"
xcrun stapler staple "$APP_DIR"

echo "==> Verifying"
xcrun stapler validate "$DMG_PATH"
spctl --assess --type open --context context:primary-signature -vv "$DMG_PATH"

echo
echo "Done: $DMG_PATH"
shasum -a 256 "$DMG_PATH"
