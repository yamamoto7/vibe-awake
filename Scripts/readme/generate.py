#!/usr/bin/env python3
"""Generates the per-language READMEs from a shared skeleton plus a key=value file per
language, so structure (headings, code blocks, links) can never drift between them."""
import pathlib, sys

# English stays at the repository root so GitHub renders it; the rest live in README/.
# That means the two groups need different relative paths back to the repo root, which is
# what ROOT below is for -- get it wrong and the logo and licence links break silently in
# eight files at once.
LANGS = [("en", "English"), ("ja", "日本語"), ("zh-Hans", "简体中文"), ("ko", "한국어"),
         ("es", "Español"), ("fr", "Français"), ("de", "Deutsch"),
         ("pt-BR", "Português"), ("ru", "Русский")]

def path_of(code):
    return "README.md" if code == "en" else f"README/{code}.md"

def link_between(from_code, to_code):
    """Href from one README to another, both of which may sit at different depths."""
    if from_code == "en":
        return path_of(to_code)
    return "../README.md" if to_code == "en" else f"{to_code}.md"

def switcher(current):
    return " · ".join(
        name if code == current else f'<a href="{link_between(current, code)}">{name}</a>'
        for code, name in LANGS)

TEMPLATE = """<div align="center">
  <img src="{ROOT}Resources/logo.png" width="128" alt="Vibe Awake">
  <h1>Vibe Awake</h1>
  <p>{TAGLINE}</p>
  <p>{SWITCHER}</p>
</div>

```bash
brew tap yamamoto7/tap
brew trust yamamoto7/tap
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
brew trust yamamoto7/tap
brew install --cask vibe-awake
```

{P_TRUST}

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

[MIT]({ROOT}LICENSE)
"""

src_dir = pathlib.Path(sys.argv[1])
out_dir = pathlib.Path(sys.argv[2])
(out_dir / "README").mkdir(exist_ok=True)

for code, _ in LANGS:
    src = src_dir / f"{code}.md"
    values = {}
    for raw in src.read_text().splitlines():
        if not raw.strip() or "|" not in raw:
            continue
        k, v = raw.split("|", 1)
        values[k.strip()] = v
    values["SWITCHER"] = switcher(code)
    values["ROOT"] = "" if code == "en" else "../"
    target = out_dir / path_of(code)
    try:
        target.write_text(TEMPLATE.format(**values))
    except KeyError as e:
        print(f"{code}: missing key {e}")
        continue
    print(f"wrote {path_of(code)}")
