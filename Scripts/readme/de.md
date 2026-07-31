TAGLINE|Hält deinen Mac nur dann wach, solange eine KI-Coding-Sitzung tatsächlich arbeitet.
NOTE|Beim ersten Start wirst du einmal nach deinem Administratorkennwort gefragt. macOS lässt nur ein privilegiertes Hilfsprogramm den Ruhezustand bei geschlossenem Deckel verhindern → [Einrichtung](#einrichtung)
H_WHAT|Worum es geht
P_WHAT1|Du gibst Claude Code oder Codex CLI eine längere Aufgabe, gehst weg, und der Mac schläft ein — die Arbeit halb erledigt. Vibe Awake sitzt in der Menüleiste und blockiert den Ruhezustand **nur solange eine Sitzung eine Antwort erzeugt** — **auch bei geschlossenem Deckel**.
P_WHAT2|Anders als ein dauerhaft laufendes `caffeinate` lässt eine Sitzung, die an der Eingabeaufforderung wartet, den Mac ganz normal einschlafen. Kein Strom, der verbraucht wird, während du weg bist.
H_TOOLS|Unterstützte Werkzeuge
T_SUPPORTED|Unterstützt
T_CLAUDE|Claude Code (Terminal)
T_CODEX|Codex CLI (Terminal)
T_DESKTOP|Claude Desktop-App
T_CURSOR|Cursor
P_HEADLESS|Headless-Läufe (`claude -p`, `codex exec`) sind nicht abgedeckt.
H_INSTALL|Installation
P_REQ|Erfordert **macOS 13 (Ventura) oder neuer**.
H_BREW|Homebrew
P_BREW_UPD|Aktualisieren und Entfernen laufen ebenfalls über Homebrew.
C_UNINSTALL|# entfernt auch das Hilfsprogramm
H_MANUAL|Manuell
P_MANUAL|Lade das `.dmg` von [Releases](https://github.com/yamamoto7/vibe-awake/releases) und ziehe `Vibe Awake.app` nach `Programme`.
H_SETUP|Einrichtung
P_SETUP1|Beim ersten Start wirst du **einmal nach deinem Administratorkennwort** gefragt.
P_SETUP2|macOS lässt nur ein Programm mit Administratorrechten den Ruhezustand bei geschlossenem Deckel verhindern. Das installierte Hilfsprogramm tut nichts weiter, als die eingebaute Energieeinstellung (`pmset`) umzuschalten — kein Netzwerkzugriff, keine Datenerfassung. Du kannst es jederzeit in den Einstellungen entfernen.
P_SETUP3|Bis die Einrichtung abgeschlossen ist, blockiert die App gar nichts.
H_USING|Benutzung
P_USING|Klicke auf das Menüleistensymbol, um den aktuellen Stand zu sehen.
L_WORKING|**Arbeitet** — erzeugt eine Antwort oder führt ein Werkzeug aus
L_WAITING|**Wartet auf Bestätigung** — wartet darauf, dass du etwas bestätigst
L_IDLE|**Inaktiv** — wartet an der Eingabeaufforderung
P_ICON|Ein ausgefülltes Symbol bedeutet, dass der Ruhezustand blockiert wird. Ein orangefarbenes Warnsymbol bedeutet, dass die Einrichtung noch aussteht.
H_SETTINGS|Einstellungen
S_ENABLE|Ruhezustand blockieren
S_ENABLE_D|Schaltet das Ganze vorübergehend ab
S_LOGIN|Bei der Anmeldung öffnen
S_LOGIN_D|Startet zusammen mit deinem Mac
S_DISPLAY|Bildschirm ausschalten, wenn der Deckel geschlossen wird
S_DISPLAY_D|Während der Ruhezustand blockiert ist, lässt macOS den eingebauten Bildschirm hinter dem geschlossenen Deckel an. Ihn auszuschalten spart Strom. Bei angeschlossenem externen Bildschirm passiert nichts
S_APPROVAL|Warten auf Bestätigung als Arbeit werten
S_APPROVAL_D|Aktiviere dies, wenn du aus der Ferne bestätigst, etwa vom Telefon. Ist es aus, schläft der Mac ein, während eine Sitzung auf deine Bestätigung wartet
H_LANGS|Sprachen
P_LANGS|English, 日本語, 简体中文, 한국어, Español, Français, Deutsch, Português (Brasil), Русский. Die App folgt der in macOS eingestellten Sprache.
H_CAVEATS|Zu beachten
P_CAVEAT1|Die Erkennung liest interne Zustandsdateien, die keines der beiden CLIs dokumentiert — **ein Update dieser Werkzeuge kann sie also unbrauchbar machen**. Falls es nicht mehr funktioniert, öffne bitte ein [Issue](https://github.com/yamamoto7/vibe-awake/issues).
P_CAVEAT2|Dies ist ein inoffizielles Werkzeug, weder mit Anthropic noch mit OpenAI verbunden. Claude, Claude Code und Codex sind Marken ihrer jeweiligen Inhaber.
H_BUILD|Aus dem Quelltext bauen
P_BUILD_REQ|Erfordert Swift 5.9 oder neuer.
C_DEV|# Entwicklungs-Build
C_APP|# erzeugt die .app in dist/
C_L10N|# prüft, ob die Übersetzungen aktuell sind
P_BUILD_DIST|Für Distributions-Builds wird ein Developer-ID-Zertifikat benötigt.
C_SIGN|# Developer-ID-Signatur + Hardened Runtime
C_NOTARIZE|# erstellt das DMG und lässt es notarisieren
H_TRANS|Übersetzungen
P_TRANS|Jede Sprache ist eine `Localizable.strings`-Datei unter `Resources/<lang>.lproj/`. Englisch ist die Entwicklungssprache: Ein anderswo fehlender Schlüssel fällt auf Englisch zurück, statt den rohen Schlüssel anzuzeigen. `Scripts/check_localizations.sh` meldet fehlende, ungenutzte und undefinierte Schlüssel — führe es aus, nachdem du einen Text angefasst hast.
P_SOURCE|Die Begründung hinter der Erkennungslogik und den Entwurfsentscheidungen steht in den Kommentaren im Quelltext.
H_LICENSE|Lizenz
