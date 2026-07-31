#!/usr/bin/env python3
"""Generates the per-language READMEs from a shared skeleton plus a key=value file per
language, so structure (headings, code blocks, links) can never drift between them."""
import pathlib, sys

LANGS = [("README.md", "English"), ("README.ja.md", "日本語"),
         ("README.zh-Hans.md", "简体中文"), ("README.ko.md", "한국어"),
         ("README.es.md", "Español"), ("README.fr.md", "Français"),
         ("README.de.md", "Deutsch"), ("README.pt-BR.md", "Português"),
         ("README.ru.md", "Русский")]

def switcher(current):
    return " · ".join(n if f == current else f'<a href="{f}">{n}</a>' for f, n in LANGS)

TEMPLATE = """<div align="center">
  <img src="Resources/logo.png" width="128" alt="Vibe Awake">
  <h1>Vibe Awake</h1>
  <p>{TAGLINE}</p>
  <p>{SWITCHER}</p>
</div>

```bash
brew tap yamamoto7/tap
brew install --cask vibe-awake
```

> [!NOTE]
> {NOTE}

## {H_WHAT}

{P_WHAT1}

{P_WHAT2}

## {H_TOOLS}

| | {T_SUPPORTED} |
|---|:---:|
| {T_CLAUDE} | ✅ |
| {T_CODEX} | ✅ |
| {T_DESKTOP} | ― |
| {T_CURSOR} | ― |

{P_HEADLESS}

## {H_INSTALL}

{P_REQ}

### {H_BREW}

```bash
brew tap yamamoto7/tap
brew install --cask vibe-awake
```

{P_BREW_UPD}

```bash
brew upgrade --cask vibe-awake
brew uninstall --cask vibe-awake   {C_UNINSTALL}
```

### {H_MANUAL}

{P_MANUAL}

## {H_SETUP}

{P_SETUP1}

{P_SETUP2}

{P_SETUP3}

## {H_USING}

{P_USING}

- {L_WORKING}
- {L_WAITING}
- {L_IDLE}

{P_ICON}

## {H_SETTINGS}

| | |
|---|---|
| {S_ENABLE} | {S_ENABLE_D} |
| {S_LOGIN} | {S_LOGIN_D} |
| {S_DISPLAY} | {S_DISPLAY_D} |
| {S_APPROVAL} | {S_APPROVAL_D} |

## {H_LANGS}

{P_LANGS}

## {H_CAVEATS}

{P_CAVEAT1}

{P_CAVEAT2}

## {H_BUILD}

{P_BUILD_REQ}

```bash
swift build                          {C_DEV}
./Scripts/build_app.sh               {C_APP}
./Scripts/check_localizations.sh     {C_L10N}
```

{P_BUILD_DIST}

```bash
./Scripts/build_app.sh --release     {C_SIGN}
./Scripts/notarize.sh                {C_NOTARIZE}
```

### {H_TRANS}

{P_TRANS}

{P_SOURCE}

## {H_LICENSE}

[MIT](LICENSE)
"""

src_dir = pathlib.Path(sys.argv[1])
out_dir = pathlib.Path(sys.argv[2])

for src in sorted(src_dir.glob("*.md")):
    lang = src.stem
    values = {}
    for raw in src.read_text().splitlines():
        if not raw.strip() or "|" not in raw:
            continue
        k, v = raw.split("|", 1)
        values[k.strip()] = v
    filename = f"README.{lang}.md"
    values["SWITCHER"] = switcher(filename)
    try:
        (out_dir / filename).write_text(TEMPLATE.format(**values))
    except KeyError as e:
        print(f"{lang}: missing key {e}")
        continue
    print(f"wrote {filename}")
