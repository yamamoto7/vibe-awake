<div align="center">
  <img src="Resources/logo.png" width="128" alt="Vibe Awake">
  <h1>Vibe Awake</h1>
  <p>Hält deinen Mac nur dann wach, solange eine KI-Coding-Sitzung tatsächlich arbeitet.</p>
  <p><a href="README.md">English</a> · <a href="README.ja.md">日本語</a> · <a href="README.zh-Hans.md">简体中文</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.fr.md">Français</a> · Deutsch · <a href="README.pt-BR.md">Português</a> · <a href="README.ru.md">Русский</a></p>
</div>

```bash
brew tap yamamoto7/tap
brew install --cask vibe-awake
```

> [!NOTE]
> Beim ersten Start wirst du einmal nach deinem Administratorkennwort gefragt. macOS lässt nur ein privilegiertes Hilfsprogramm den Ruhezustand bei geschlossenem Deckel verhindern → [Einrichtung](#einrichtung)

## Worum es geht

Du gibst Claude Code oder Codex CLI eine längere Aufgabe, gehst weg, und der Mac schläft ein — die Arbeit halb erledigt. Vibe Awake sitzt in der Menüleiste und blockiert den Ruhezustand **nur solange eine Sitzung eine Antwort erzeugt** — **auch bei geschlossenem Deckel**.

Anders als ein dauerhaft laufendes `caffeinate` lässt eine Sitzung, die an der Eingabeaufforderung wartet, den Mac ganz normal einschlafen. Kein Strom, der verbraucht wird, während du weg bist.

## Unterstützte Werkzeuge

| | Unterstützt |
|---|:---:|
| Claude Code (Terminal) | ✅ |
| Codex CLI (Terminal) | ✅ |
| Claude Desktop-App | ― |
| Cursor | ― |

Headless-Läufe (`claude -p`, `codex exec`) sind nicht abgedeckt.

## Installation

Erfordert **macOS 13 (Ventura) oder neuer**.

### Homebrew

```bash
brew tap yamamoto7/tap
brew install --cask vibe-awake
```

Aktualisieren und Entfernen laufen ebenfalls über Homebrew.

```bash
brew upgrade --cask vibe-awake
brew uninstall --cask vibe-awake   # entfernt auch das Hilfsprogramm
```

### Manuell

Lade das `.dmg` von [Releases](https://github.com/yamamoto7/vibe-awake/releases) und ziehe `Vibe Awake.app` nach `Programme`.

## Einrichtung

Beim ersten Start wirst du **einmal nach deinem Administratorkennwort** gefragt.

macOS lässt nur ein Programm mit Administratorrechten den Ruhezustand bei geschlossenem Deckel verhindern. Das installierte Hilfsprogramm tut nichts weiter, als die eingebaute Energieeinstellung (`pmset`) umzuschalten — kein Netzwerkzugriff, keine Datenerfassung. Du kannst es jederzeit in den Einstellungen entfernen.

Bis die Einrichtung abgeschlossen ist, blockiert die App gar nichts.

## Benutzung

Klicke auf das Menüleistensymbol, um den aktuellen Stand zu sehen.

- **Arbeitet** — erzeugt eine Antwort oder führt ein Werkzeug aus
- **Wartet auf Bestätigung** — wartet darauf, dass du etwas bestätigst
- **Inaktiv** — wartet an der Eingabeaufforderung

Ein ausgefülltes Symbol bedeutet, dass der Ruhezustand blockiert wird. Ein orangefarbenes Warnsymbol bedeutet, dass die Einrichtung noch aussteht.

## Einstellungen

| | |
|---|---|
| Ruhezustand blockieren | Schaltet das Ganze vorübergehend ab |
| Bei der Anmeldung öffnen | Startet zusammen mit deinem Mac |
| Bildschirm ausschalten, wenn der Deckel geschlossen wird | Während der Ruhezustand blockiert ist, lässt macOS den eingebauten Bildschirm hinter dem geschlossenen Deckel an. Ihn auszuschalten spart Strom. Bei angeschlossenem externen Bildschirm passiert nichts |
| Warten auf Bestätigung als Arbeit werten | Aktiviere dies, wenn du aus der Ferne bestätigst, etwa vom Telefon. Ist es aus, schläft der Mac ein, während eine Sitzung auf deine Bestätigung wartet |

## Sprachen

English, 日本語, 简体中文, 한국어, Español, Français, Deutsch, Português (Brasil), Русский. Die App folgt der in macOS eingestellten Sprache.

## Zu beachten

Die Erkennung liest interne Zustandsdateien, die keines der beiden CLIs dokumentiert — **ein Update dieser Werkzeuge kann sie also unbrauchbar machen**. Falls es nicht mehr funktioniert, öffne bitte ein [Issue](https://github.com/yamamoto7/vibe-awake/issues).

Dies ist ein inoffizielles Werkzeug, weder mit Anthropic noch mit OpenAI verbunden. Claude, Claude Code und Codex sind Marken ihrer jeweiligen Inhaber.

## Aus dem Quelltext bauen

Erfordert Swift 5.9 oder neuer.

```bash
swift build                          # Entwicklungs-Build
./Scripts/build_app.sh               # erzeugt die .app in dist/
./Scripts/check_localizations.sh     # prüft, ob die Übersetzungen aktuell sind
```

Für Distributions-Builds wird ein Developer-ID-Zertifikat benötigt.

```bash
./Scripts/build_app.sh --release     # Developer-ID-Signatur + Hardened Runtime
./Scripts/notarize.sh                # erstellt das DMG und lässt es notarisieren
```

### Übersetzungen

Jede Sprache ist eine `Localizable.strings`-Datei unter `Resources/<lang>.lproj/`. Englisch ist die Entwicklungssprache: Ein anderswo fehlender Schlüssel fällt auf Englisch zurück, statt den rohen Schlüssel anzuzeigen. `Scripts/check_localizations.sh` meldet fehlende, ungenutzte und undefinierte Schlüssel — führe es aus, nachdem du einen Text angefasst hast.

Die Begründung hinter der Erkennungslogik und den Entwurfsentscheidungen steht in den Kommentaren im Quelltext.

## Lizenz

[MIT](LICENSE)
