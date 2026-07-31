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
    /// The executable name the state file's pid must belong to.
    static let executableName = "VibeAwake"

    /// Bumped whenever the installed script or state format changes. An installed helper with
    /// a different version is treated as not installed, so the user is prompted to re-run
    /// setup instead of silently running an incompatible script.
    static let helperVersion = "3"

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
                return L("error.scriptWriteFailed")
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

    static var daemonPresent: Bool {
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
        // The script is passed inline, base64-encoded, rather than written to a temporary
        // file and executed by path. A file would sit on disk for as long as the
        // authentication dialog is up -- seconds, or minutes if the user hesitates -- and any
        // other process running as this user could overwrite it in that window, so whatever
        // it wrote would then be run as root. Nothing is on disk to swap this way.
        //
        // The base64 alphabet also contains no shell or AppleScript metacharacters, so the
        // payload cannot break out of the quoting around it.
        let encoded = Data(shellScript.utf8).base64EncodedString()
        let source = """
            do shell script "echo \(encoded) | /usr/bin/base64 -D | /bin/bash" \
            with administrator privileges
            """

        DispatchQueue.global(qos: .userInitiated).async {
            var errorInfo: NSDictionary?
            let appleScript = NSAppleScript(source: source)
            appleScript?.executeAndReturnError(&errorInfo)

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
        # This runs as root via `do shell script ... with administrator privileges`, which
        # inherits the invoking user's PATH untouched. On a typical developer machine that
        # puts user-writable directories -- /opt/homebrew/bin, ~/.local/bin -- ahead of
        # /usr/bin, so an unqualified `mkdir` or `chown` here would run whatever a local
        # process had planted there, as root. Pin PATH and use absolute paths throughout.
        PATH=/usr/bin:/bin:/usr/sbin:/sbin
        export PATH

        # The app was renamed from "Vide Sleep Blocker"; clear the daemon it used to install so
        # it can't linger and keep toggling disablesleep behind the current one's back.
        /bin/launchctl bootout system/\(legacyDaemonLabel) 2>/dev/null || true
        /bin/rm -f "\(legacyPlistPath)"
        /bin/rm -rf "\(legacyInstallDir)"

        INSTALL_DIR="\(installDir)"
        /bin/mkdir -p "$INSTALL_DIR"

        /bin/cat > "\(helperScriptPath)" <<'HELPER_EOF'
        #!/bin/bash
        PATH=/usr/bin:/bin:/usr/sbin:/sbin
        export PATH
        STATE_FILE="\(stateFilePath)"
        MAX_AGE=\(stalenessSeconds)

        read_field() {
          /usr/bin/awk -F= -v k="$1" '$1==k {print $2}' "$STATE_FILE" 2>/dev/null \\
            | /usr/bin/head -1 | /usr/bin/tr -dc '0-9'
        }

        WANT=0
        if [ -f "$STATE_FILE" ]; then
          desired=$(read_field desired)
          pid=$(read_field pid)
          ts=$(read_field ts)
          # Check what the pid actually is, not just that something is alive under it. This
          # runs as root, so `kill -0` succeeds for every process on the system: without the
          # name check, writing `pid=1` into the state file would pin the flag on. It also
          # rules out a recycled pid after a reboot landing on an unrelated process.
          proc=$(/bin/ps -o comm= -p "$pid" 2>/dev/null)
          proc=${proc##*/}
          if [ "$desired" = "1" ] && [ -n "$ts" ] && [ "$proc" = "\(executableName)" ]; then
            now=$(/bin/date +%s)
            age=$((now - ts))
            if [ "$age" -lt "$MAX_AGE" ] && [ "$age" -gt -"$MAX_AGE" ]; then
              WANT=1
            fi
          fi
        fi

        current=$(/usr/bin/pmset -g | /usr/bin/awk '/SleepDisabled/{print $2}')
        if [ "$current" != "$WANT" ]; then
          /usr/bin/pmset -a disablesleep "$WANT"
        fi
        HELPER_EOF
        /bin/chmod 755 "\(helperScriptPath)"
        /usr/sbin/chown root:wheel "\(helperScriptPath)"

        printf 'desired=0\\npid=0\\nts=0\\n' > "\(stateFilePath)"
        # Numeric uid, not the short name: a name is interpolated into a root shell string
        # and could contain quoting characters. An integer cannot break out.
        /usr/sbin/chown \(getuid()) "\(stateFilePath)"
        /bin/chmod 644 "\(stateFilePath)"

        echo "\(helperVersion)" > "\(versionFilePath)"
        /usr/sbin/chown root:wheel "\(versionFilePath)"
        /bin/chmod 644 "\(versionFilePath)"

        /usr/sbin/chown root:wheel "$INSTALL_DIR"
        /bin/chmod 755 "$INSTALL_DIR"

        /bin/cat > "\(plistPath)" <<'PLIST_EOF'
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
        /bin/chmod 644 "\(plistPath)"
        /usr/sbin/chown root:wheel "\(plistPath)"

        /bin/launchctl bootout system/\(daemonLabel) 2>/dev/null || true
        /bin/launchctl bootstrap system "\(plistPath)"
        """
    }

    private static var uninstallScript: String {
        // Order matters. Clearing the flag first was wrong: the app is still running and
        // still writing `desired=1`, so a heartbeat landing between the reset and the bootout
        // would make the still-loaded daemon set it again -- and then the daemon is deleted,
        // leaving the Mac unable to sleep on a closed lid with nothing left to fix it.
        // Unload the daemon first, then clear the flag, then remove the files.
        """
        #!/bin/bash
        PATH=/usr/bin:/bin:/usr/sbin:/sbin
        export PATH
        /bin/launchctl bootout system/\(daemonLabel) 2>/dev/null || true
        /usr/bin/pmset -a disablesleep 0 || true
        /bin/rm -f "\(plistPath)"
        /bin/rm -rf "\(installDir)"
        /usr/bin/pmset -a disablesleep 0 || true
        """
    }
}
