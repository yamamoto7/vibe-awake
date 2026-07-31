<div align="center">
  <img src="Resources/logo.png" width="128" alt="Vibe Awake">
  <h1>Vibe Awake</h1>
  <p>Keeps your Mac awake only while an AI coding session is actually working.</p>
  <p>English · <a href="README.ja.md">日本語</a> · <a href="README.zh-Hans.md">简体中文</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.fr.md">Français</a> · <a href="README.de.md">Deutsch</a> · <a href="README.pt-BR.md">Português</a> · <a href="README.ru.md">Русский</a></p>
</div>

```bash
brew tap yamamoto7/tap
brew install --cask vibe-awake
```

> [!NOTE]
> You'll be asked for your administrator password once on first launch. macOS only lets a privileged helper stop the Mac sleeping with the lid closed → [Setup](#setup)

## What it does

Hand Claude Code or Codex CLI a long task, step away, and your Mac goes to sleep with the work half done. Vibe Awake sits in the menu bar and blocks sleep **only while a session is generating a response** — **including with the MacBook's lid closed**.

Unlike leaving `caffeinate` running, a session parked at the prompt lets the Mac sleep normally. No battery burned waiting for you to come back.

## Supported tools

| | Supported |
|---|:---:|
| Claude Code (terminal) | ✅ |
| Codex CLI (terminal) | ✅ |
| Claude desktop app | ― |
| Cursor | ― |

Headless runs (`claude -p`, `codex exec`) are out of scope.

## Install

Requires **macOS 13 (Ventura) or later**.

### Homebrew

```bash
brew tap yamamoto7/tap
brew install --cask vibe-awake
```

Updating and uninstalling go through Homebrew too.

```bash
brew upgrade --cask vibe-awake
brew uninstall --cask vibe-awake   # removes the helper as well
```

### Manually

Download the `.dmg` from [Releases](https://github.com/yamamoto7/vibe-awake/releases) and drag `Vibe Awake.app` into `Applications`.

## Setup

On first launch you'll be asked for your **administrator password, once**.

macOS only lets a program with administrator rights stop the Mac from sleeping when the lid is closed. The helper that gets installed does nothing but toggle the built-in power setting (`pmset`) — no network access, no data collected. You can remove it at any time from Settings.

Sleep blocking does nothing until setup is finished.

## Using it

Click the menu bar icon to see what's happening.

- **Working** — generating a response or running a tool
- **Awaiting approval** — waiting for you to confirm something
- **Idle** — sitting at the prompt

A filled-in icon means sleep is being blocked. An orange warning icon means setup hasn't been done.

## Settings

| | |
|---|---|
| Block sleep | Turn the whole thing off temporarily |
| Open at login | Start with your Mac |
| Turn the display off when the lid closes | While sleep is blocked, macOS leaves the built-in display on behind a closed lid. Turning it off saves power. Does nothing when an external display is connected |
| Count awaiting approval as working | Turn this on if you approve remotely, such as from your phone. With it off, the Mac sleeps while a session waits for approval |

## Languages

English, 日本語, 简体中文, 한국어, Español, Français, Deutsch, Português (Brasil), Русский. The app follows your macOS language setting.

## Caveats

Detection reads internal state files that neither CLI documents, so **an update to those tools can break it**. If it stops working, please open an [issue](https://github.com/yamamoto7/vibe-awake/issues).

This is an unofficial tool, not affiliated with Anthropic or OpenAI. Claude, Claude Code and Codex are trademarks of their respective owners.

## Building from source

Requires Swift 5.9 or later.

```bash
swift build                          # development build
./Scripts/build_app.sh               # produce the .app in dist/
./Scripts/check_localizations.sh     # verify translations are in sync
```

Distribution builds need a Developer ID certificate.

```bash
./Scripts/build_app.sh --release     # Developer ID signature + Hardened Runtime
./Scripts/notarize.sh                # build the DMG and notarize it
```

### Translations

Each language is a `Localizable.strings` file under `Resources/<lang>.lproj/`. English is the development language, so a key missing elsewhere falls back to it rather than showing the raw key. `Scripts/check_localizations.sh` reports keys that are missing, unused or undefined — run it after touching any string.

The reasoning behind the detection logic and the design decisions lives in the source comments.

## License

[MIT](LICENSE)
