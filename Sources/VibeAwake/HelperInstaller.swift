import Foundation

/// Installs (and removes) a root LaunchDaemon that toggles `pmset -a disablesleep`. That flag
/// is the only thing that keeps macOS awake with the lid closed and no external display --
/// an IOPMAssertion cannot do it, because clamshell sleep doesn't come from the idle timer.
/// Installation needs the admin password once; after that the app just rewrites a small state
/// file that the daemon watches.
///
/// The state file carries the app's PID and a timestamp, not just a flag, so the daemon can
/// tell a live request from a leftover one. Without that, force-quitting the app (SIGKILL,
/// a crash, Activity Monitor) left `disablesleep` stuck on with nothing to turn it back off
/// -- and `RunAtLoad` re-applied it on every boot, so the Mac would never sleep on a closed
/// lid again until the app happened to run. The daemon now also re-checks on a timer, so a
/// stale request heals itself within a minute even though no file change wakes it.
enum HelperInstaller {
    /// Bumped whenever the installed script or state format changes. An installed helper with
    /// a different version is treated as not installed, so the user is prompted to re-run
    /// setup instead of silently running an incompatible script.
    static let helperVersion = "2"

    static let daemonLabel = "com.ychof.vibeawake.helper"
    static let installDir = "/Library/Application Support/VibeAwake"
    static let helperScriptPath = "\(installDir)/helper.sh"
    static let stateFilePath = "\(installDir)/state"
    static let versionFilePath = "\(installDir)/version"
    static let plistPath = "/Library/LaunchDaemons/\(daemonLabel).plist"

    /// Identifiers used before the app was renamed to Vibe Awake. Kept only so setup can
    /// remove the old daemon; nothing else references them.
    private static let legacyDaemonLabel = "dev.vide.sleepblocker.helper"
    private static let legacyInstallDir = "/Library/Application Support/SleepBlocker"
    private static let legacyPlistPath = "/Library/LaunchDaemons/\(legacyDaemonLabel).plist"

    /// How long a state file entry stays trusted without a refresh. The app rewrites it far
    /// more often than this; anything older means the app is gone.
    static let stalenessSeconds = 120
    /// How often the daemon re-validates even with no file change.
    static let recheckSeconds = 60

    enum InstallError: LocalizedError {
        case scriptWriteFailed
        case appleScriptFailed(String)

        var errorDescription: String? {
            switch self {
            case .scriptWriteFailed:
                return "セットアップ用スクリプトの書き込みに失敗しました。"
            case .appleScriptFailed(let message):
                return message
            }
        }
    }

    private static var installedVersion: String? {
        guard let text = try? String(contentsOfFile: versionFilePath, encoding: .utf8) else {
            return nil
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static var daemonPresent: Bool {
        FileManager.default.fileExists(atPath: plistPath)
    }

    static func isInstalled() -> Bool {
        daemonPresent && installedVersion == helperVersion
    }

    /// An older helper is present. It can't read the current state format, so it's as good as
    /// missing -- but the UI should say "update" rather than "install".
    static func needsUpdate() -> Bool {
        daemonPresent && installedVersion != helperVersion
    }

    static func install(completion: @escaping (Result<Void, Error>) -> Void) {
        runPrivileged(shellScript: installScript, completion: completion)
    }

    static func uninstall(completion: @escaping (Result<Void, Error>) -> Void) {
        runPrivileged(shellScript: uninstallScript, completion: completion)
    }

    private static func runPrivileged(
        shellScript: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("vibeawake-setup-\(UUID().uuidString).sh")

        do {
            try shellScript.write(to: tempURL, atomically: true, encoding: .utf8)
        } catch {
            completion(.failure(InstallError.scriptWriteFailed))
            return
        }

        let escapedPath = tempURL.path.replacingOccurrences(of: "\"", with: "\\\"")
        let source = "do shell script \"/bin/bash \\\"\(escapedPath)\\\"\" with administrator privileges"

        DispatchQueue.global(qos: .userInitiated).async {
            var errorInfo: NSDictionary?
            let appleScript = NSAppleScript(source: source)
            appleScript?.executeAndReturnError(&errorInfo)
            try? FileManager.default.removeItem(at: tempURL)

            DispatchQueue.main.async {
                if let errorInfo {
                    let message = errorInfo[NSAppleScript.errorMessage] as? String ?? "\(errorInfo)"
                    completion(.failure(InstallError.appleScriptFailed(message)))
                } else {
                    completion(.success(()))
                }
            }
        }
    }

    private static var installScript: String {
        // The state file is owned by this user rather than left world-writable: it is parsed
        // by a script running as root, so anything able to write it can influence root's
        // behaviour. Values are also read field by field and stripped to digits rather than
        // sourced, so a tampered file can't inject commands.
        """
        #!/bin/bash
        set -e

        # The app was renamed from "Vide Sleep Blocker"; clear the daemon it used to install so
        # it can't linger and keep toggling disablesleep behind the current one's back.
        launchctl bootout system/\(legacyDaemonLabel) 2>/dev/null || true
        rm -f "\(legacyPlistPath)"
        rm -rf "\(legacyInstallDir)"

        INSTALL_DIR="\(installDir)"
        mkdir -p "$INSTALL_DIR"

        cat > "\(helperScriptPath)" <<'HELPER_EOF'
        #!/bin/bash
        STATE_FILE="\(stateFilePath)"
        MAX_AGE=\(stalenessSeconds)

        read_field() {
          awk -F= -v k="$1" '$1==k {print $2}' "$STATE_FILE" 2>/dev/null | head -1 | tr -dc '0-9'
        }

        WANT=0
        if [ -f "$STATE_FILE" ]; then
          desired=$(read_field desired)
          pid=$(read_field pid)
          ts=$(read_field ts)
          if [ "$desired" = "1" ] && [ -n "$pid" ] && [ -n "$ts" ] && kill -0 "$pid" 2>/dev/null; then
            now=$(date +%s)
            age=$((now - ts))
            if [ "$age" -lt "$MAX_AGE" ] && [ "$age" -gt -"$MAX_AGE" ]; then
              WANT=1
            fi
          fi
        fi

        current=$(/usr/bin/pmset -g | awk '/SleepDisabled/{print $2}')
        if [ "$current" != "$WANT" ]; then
          /usr/bin/pmset -a disablesleep "$WANT"
        fi
        HELPER_EOF
        chmod 755 "\(helperScriptPath)"
        chown root:wheel "\(helperScriptPath)"

        printf 'desired=0\\npid=0\\nts=0\\n' > "\(stateFilePath)"
        chown "\(NSUserName())" "\(stateFilePath)"
        chmod 644 "\(stateFilePath)"

        echo "\(helperVersion)" > "\(versionFilePath)"
        chown root:wheel "\(versionFilePath)"
        chmod 644 "\(versionFilePath)"

        chown root:wheel "$INSTALL_DIR"
        chmod 755 "$INSTALL_DIR"

        cat > "\(plistPath)" <<'PLIST_EOF'
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>\(daemonLabel)</string>
            <key>ProgramArguments</key>
            <array>
                <string>/bin/bash</string>
                <string>\(helperScriptPath)</string>
            </array>
            <key>WatchPaths</key>
            <array>
                <string>\(stateFilePath)</string>
            </array>
            <key>StartInterval</key>
            <integer>\(recheckSeconds)</integer>
            <key>RunAtLoad</key>
            <true/>
        </dict>
        </plist>
        PLIST_EOF
        chmod 644 "\(plistPath)"
        chown root:wheel "\(plistPath)"

        launchctl bootout system/\(daemonLabel) 2>/dev/null || true
        launchctl bootstrap system "\(plistPath)"
        """
    }

    private static var uninstallScript: String {
        """
        #!/bin/bash
        /usr/bin/pmset -a disablesleep 0 || true
        launchctl bootout system/\(daemonLabel) 2>/dev/null || true
        rm -f "\(plistPath)"
        rm -rf "\(installDir)"
        """
    }
}
