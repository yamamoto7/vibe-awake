TAGLINE|Keeps your Mac awake only while an AI coding session is actually working.
NOTE|You'll be asked for your administrator password once on first launch. macOS only lets a privileged helper stop your Mac from sleeping with the lid closed → [Setup](#setup)
H_WHAT|What it does
P_WHAT1|Hand Claude Code or Codex CLI a long task, step away, and your Mac goes to sleep with the work half done. Vibe Awake sits in the menu bar and blocks sleep **only while a session is generating a response** — **including with the MacBook's lid closed**.
P_WHAT2|Unlike leaving `caffeinate` running, Vibe Awake lets your Mac sleep normally while a session sits at the prompt. No battery burned waiting for you to come back.
H_TOOLS|Supported tools
T_SUPPORTED|Supported
T_CLAUDE|Claude Code (terminal)
T_CODEX|Codex CLI (terminal)
T_DESKTOP|Claude desktop app
T_CURSOR|Cursor
P_HEADLESS|Headless runs (`claude -p`, `codex exec`) are out of scope.
H_INSTALL|Install
P_REQ|Requires **macOS 13 (Ventura) or later**.
H_BREW|Homebrew
P_BREW_UPD|Updating and uninstalling go through Homebrew too.
C_UNINSTALL|# removes the helper as well
H_MANUAL|Manually
P_MANUAL|Download the `.dmg` from [Releases](https://github.com/yamamoto7/vibe-awake/releases) and drag `Vibe Awake.app` into `Applications`.
H_SETUP|Setup
P_SETUP1|On first launch you'll be asked for your **administrator password, once**.
P_SETUP2|macOS only lets a program with administrator privileges stop your Mac from sleeping when the lid is closed. The helper that gets installed does nothing but toggle a built-in macOS power setting with `pmset` — no network access, no data collected. You can remove it at any time in Settings.
P_SETUP3|Sleep blocking does nothing until setup is finished.
H_USING|Using it
P_USING|Click the menu bar icon to see what's happening.
L_WORKING|**Working** — generating a response or running a tool
L_WAITING|**Awaiting approval** — waiting for you to confirm something
L_IDLE|**Idle** — sitting at the prompt
P_ICON|A filled-in icon means sleep is being blocked. An orange warning icon means setup hasn't been done.
H_SETTINGS|Settings
S_ENABLE|Block sleep
S_ENABLE_D|Turn the whole thing off temporarily
S_LOGIN|Open at login
S_LOGIN_D|Start with your Mac
S_DISPLAY|Turn the display off while the lid is closed
S_DISPLAY_D|While sleep is blocked, macOS leaves the built-in display on behind a closed lid. Turning it off saves power. Does nothing when an external display is connected
S_APPROVAL|Count awaiting approval as working
S_APPROVAL_D|Turn this on if you approve remotely, such as from your phone. With it off, the Mac sleeps while a session waits for approval
H_LANGS|Languages
P_LANGS|English, 日本語, 简体中文, 한국어, Español, Français, Deutsch, Português (Brasil), Русский. The app follows your macOS language setting.
H_CAVEATS|Caveats
P_CAVEAT1|Detection reads internal state files that neither CLI documents, so **an update to those tools can break it**. If it stops working, please open an [issue](https://github.com/yamamoto7/vibe-awake/issues).
P_CAVEAT2|This is an unofficial tool, not affiliated with Anthropic or OpenAI. Claude, Claude Code and Codex are trademarks of their respective owners.
H_BUILD|Building from source
P_BUILD_REQ|Requires Swift 5.9 or later.
C_DEV|# development build
C_APP|# produce the .app in dist/
C_L10N|# verify translations are in sync
P_BUILD_DIST|Distribution builds need a Developer ID certificate.
C_SIGN|# Developer ID signature + Hardened Runtime
C_NOTARIZE|# build the DMG and notarize it
H_TRANS|Translations
P_TRANS|Each language is a `Localizable.strings` file under `Resources/<lang>.lproj/`. English is the development language, so a key missing elsewhere falls back to it rather than showing the raw key. `Scripts/check_localizations.sh` reports keys that are missing, unused or undefined — run it after touching any string.
P_SOURCE|The reasoning behind the detection logic and the design decisions lives in the source comments.
H_LICENSE|License
