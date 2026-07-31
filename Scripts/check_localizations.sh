#!/bin/bash
# Checks that every language defines the same keys as English, and that every key used in
# the source exists. Translations drift silently otherwise: a missing key falls back to
# English at runtime, so nothing looks broken until a user in that language notices.
set -euo pipefail
cd "$(dirname "$0")/.."

BASE="Resources/en.lproj/Localizable.strings"
status=0

keys_of() { /usr/bin/awk -F'"' '/^"/ {print $2}' "$1" | sort; }

base_keys=$(keys_of "$BASE")

echo "== key parity =="
for f in Resources/*.lproj/Localizable.strings; do
  lang=$(basename "$(dirname "$f")" .lproj)
  [ "$lang" = "en" ] && continue

  missing=$(comm -23 <(echo "$base_keys") <(keys_of "$f"))
  extra=$(comm -13 <(echo "$base_keys") <(keys_of "$f"))

  if [ -n "$missing" ] || [ -n "$extra" ]; then
    status=1
    echo "  $lang"
    [ -n "$missing" ] && echo "$missing" | sed 's/^/      missing: /'
    [ -n "$extra" ] && echo "$extra" | sed 's/^/      extra:   /'
  else
    printf "  %-10s ok\n" "$lang"
  fi
done

echo
echo "== keys used in source but not defined =="
# Pull the whole L(...) call, then the literals inside it. Keys also appear in ternaries
# such as L(flag ? "a.b" : "c.d"), which a match anchored to L(" would miss -- and matching
# key-shaped strings anywhere would pick up SF Symbol names and bundle identifiers. The
# leading boundary matters too: without it, L( also matches inside URL(...).
used=$(grep -hoE '(^|[^A-Za-z0-9_])L\([^)]*\)' Sources/VibeAwake/*.swift \
  | grep -o '"[^"]*"' | tr -d '"' | sort -u)
undefined=$(comm -23 <(echo "$used") <(echo "$base_keys"))
if [ -n "$undefined" ]; then
  status=1
  echo "$undefined" | sed 's/^/  /'
else
  echo "  none"
fi

echo
echo "== defined but unused =="
unused=$(comm -13 <(echo "$used") <(echo "$base_keys"))
[ -n "$unused" ] && echo "$unused" | sed 's/^/  /' || echo "  none"

echo
echo "== syntax =="
for f in Resources/*.lproj/Localizable.strings; do
  plutil -lint "$f" >/dev/null || { echo "  INVALID: $f"; status=1; }
done
[ "$status" = 0 ] && echo "  all valid"

exit $status
