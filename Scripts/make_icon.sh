#!/bin/bash
# Generates Resources/AppIcon.icns from Resources/logo.svg (falling back to logo.png).
#
# The artwork is square and full-bleed, but macOS app icons are drawn as a rounded
# superellipse inset from the canvas edge -- a full-bleed square reads as foreign next to
# every other icon in the Dock. So the logo is masked to the standard Big Sur shape:
# an 824x824 rounded rect centred in a 1024x1024 canvas.
set -euo pipefail
cd "$(dirname "$0")/.."

SRC="Resources/logo.svg"
[ -f "$SRC" ] || SRC="Resources/logo.png"
if [ ! -f "$SRC" ]; then
  echo "error: no Resources/logo.svg or Resources/logo.png" >&2
  exit 1
fi

if ! command -v rsvg-convert >/dev/null 2>&1; then
  echo "error: rsvg-convert is required (brew install librsvg)" >&2
  exit 1
fi

OUT_DIR="Resources"
WORK=$(mktemp -d)
ICONSET="$WORK/AppIcon.iconset"
mkdir -p "$ICONSET" "$OUT_DIR"

# Flatten the source to a raster once, so the same pixels feed every size and an SVG
# source with filters/gradients doesn't get re-rasterised inconsistently per scale.
rsvg-convert -w 2048 -h 2048 "$SRC" -o "$WORK/logo.png" 2>/dev/null \
  || cp "Resources/logo.png" "$WORK/logo.png"

# Big Sur icon grid: 824/1024 content box, corner radius 185.4.
cat > "$WORK/icon.svg" <<EOF
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
     width="1024" height="1024" viewBox="0 0 1024 1024">
  <defs>
    <clipPath id="squircle">
      <rect x="100" y="100" width="824" height="824" rx="185.4" ry="185.4"/>
    </clipPath>
  </defs>
  <g clip-path="url(#squircle)">
    <image x="100" y="100" width="824" height="824"
           xlink:href="file://$WORK/logo.png"
           preserveAspectRatio="xMidYMid slice"/>
  </g>
</svg>
EOF

for spec in "16 icon_16x16" "32 icon_16x16@2x" "32 icon_32x32" "64 icon_32x32@2x" \
            "128 icon_128x128" "256 icon_128x128@2x" "256 icon_256x256" \
            "512 icon_256x256@2x" "512 icon_512x512" "1024 icon_512x512@2x"; do
  set -- $spec
  rsvg-convert -w "$1" -h "$1" "$WORK/icon.svg" -o "$ICONSET/$2.png"
done

iconutil -c icns "$ICONSET" -o "$OUT_DIR/AppIcon.icns"
rm -rf "$WORK"
echo "Wrote $OUT_DIR/AppIcon.icns (from $SRC)"
