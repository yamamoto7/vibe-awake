#!/bin/bash
# Notarizes the built app and packages it as a DMG for distribution.
#
# Requires a Developer ID signed bundle (./Scripts/build_app.sh --release) and notarytool
# credentials stored under a keychain profile:
#   xcrun notarytool store-credentials "AC_PASSWORD" \
#     --apple-id <id> --team-id <team> --password <app-specific-password>
#
# The app is notarized and stapled *before* the DMG is built, then the DMG is notarized and
# stapled in turn. Notarizing only the DMG would leave the app inside it without a ticket of
# its own, so once a user drags it out Gatekeeper has to ask Apple over the network -- and
# refuses to launch it offline.
set -euo pipefail
cd "$(dirname "$0")/.."

APP_DISPLAY_NAME="Vibe Awake"
VERSION="${VERSION:-2.0.0}"
KEYCHAIN_PROFILE="${KEYCHAIN_PROFILE:-AC_PASSWORD}"
SIGN_IDENTITY="${SIGN_IDENTITY:-Developer ID Application: kenta yamamoto (LAS46NJ6P7)}"

DIST_DIR="dist"
APP_DIR="${DIST_DIR}/${APP_DISPLAY_NAME}.app"
DMG_PATH="${DIST_DIR}/VibeAwake-${VERSION}.dmg"
ZIP_PATH="${DIST_DIR}/VibeAwake-${VERSION}.zip"

if [ ! -d "$APP_DIR" ]; then
  echo "error: $APP_DIR not found. Run ./Scripts/build_app.sh --release first." >&2
  exit 1
fi

# Refuse to submit an ad-hoc signature; it would only fail after a long wait.
#
# The output is captured rather than piped into grep. Under `set -o pipefail` a `grep -q`
# closes the pipe as soon as it matches, codesign dies of SIGPIPE (141), and pipefail
# reports the whole pipeline as failed -- so the check rejected every bundle, including
# correctly signed ones. --verbose=2 is also required: plain -dv omits the Authority chain.
SIGNING_INFO=$(codesign -d --verbose=2 "$APP_DIR" 2>&1 || true)
case "$SIGNING_INFO" in
  *"Authority=Developer ID Application"*) ;;
  *)
    echo "error: $APP_DIR is not Developer ID signed. Run ./Scripts/build_app.sh --release." >&2
    exit 1
    ;;
esac

echo "==> [1/5] Submitting the app for notarization (this can take a few minutes)"
rm -f "$ZIP_PATH"
# ditto, not zip: it preserves the bundle structure and extended attributes the signature
# depends on.
ditto -c -k --keepParent "$APP_DIR" "$ZIP_PATH"
xcrun notarytool submit "$ZIP_PATH" --keychain-profile "$KEYCHAIN_PROFILE" --wait
rm -f "$ZIP_PATH"

echo "==> [2/5] Stapling the app"
xcrun stapler staple "$APP_DIR"

echo "==> [3/5] Building the DMG from the stapled app"
rm -f "$DMG_PATH"
STAGING=$(mktemp -d)
ditto "$APP_DIR" "$STAGING/${APP_DISPLAY_NAME}.app"
ln -s /Applications "$STAGING/Applications"
hdiutil create -volname "$APP_DISPLAY_NAME" -srcfolder "$STAGING" -ov -format UDZO "$DMG_PATH" >/dev/null
rm -rf "$STAGING"
codesign --force --timestamp --sign "$SIGN_IDENTITY" "$DMG_PATH"

echo "==> [4/5] Submitting the DMG for notarization"
xcrun notarytool submit "$DMG_PATH" --keychain-profile "$KEYCHAIN_PROFILE" --wait
xcrun stapler staple "$DMG_PATH"

echo "==> [5/5] Verifying"
xcrun stapler validate "$APP_DIR"
xcrun stapler validate "$DMG_PATH"
spctl --assess --type execute -vv "$APP_DIR"

echo
echo "Done: $DMG_PATH"
shasum -a 256 "$DMG_PATH"
