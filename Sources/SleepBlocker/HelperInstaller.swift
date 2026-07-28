import Foundation

/// Installs (and removes) a root LaunchDaemon that watches a small state file and toggles
/// `pmset -a disablesleep`. That flag is what actually keeps macOS from sleeping when the
/// lid is closed and no external display is attached -- an IOPMAssertion alone isn't enough
/// for that case. Installation needs the admin password once (via `do shell script ... with
/// administrator privileges`); after that the app just writes "0"/"1" to the state file.
enum HelperInstaller {
    static let daemonLabel = "dev.vide.sleepblocker.helper"
    static let installDir = "/Library/Application Support/SleepBlocker"
    static let helperScriptPath = "\(installDir)/helper.sh"
    static let stateFilePath = "\(installDir)/state"
    static let plistPath = "/Library/LaunchDaemons/\(daemonLabel).plist"

    enum InstallError: LocalizedError {
        case scriptWriteFailed
        case appleScriptFailed(String)

        var errorDescription: String? {
            switch self {
            case .scriptWriteFailed:
                return "インストールスクリプトの書き込みに失敗しました。"
            case .appleScriptFailed(let message):
                return message
            }
        }
    }

    static func isInstalled() -> Bool {
        FileManager.default.fileExists(atPath: plistPath)
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
            .appendingPathComponent("vide-sleepblocker-\(UUID().uuidString).sh")

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
        """
        #!/bin/bash
        set -e
        INSTALL_DIR="\(installDir)"
        mkdir -p "$INSTALL_DIR"

        cat > "$INSTALL_DIR/helper.sh" <<'HELPER_EOF'
        #!/bin/bash
        STATE_FILE="\(stateFilePath)"
        VALUE="0"
        if [ -f "$STATE_FILE" ]; then
          VALUE=$(cat "$STATE_FILE" | tr -d '[:space:]')
        fi
        if [ "$VALUE" = "1" ]; then
          /usr/bin/pmset -a disablesleep 1
        else
          /usr/bin/pmset -a disablesleep 0
        fi
        HELPER_EOF
        chmod 755 "$INSTALL_DIR/helper.sh"
        chown root:wheel "$INSTALL_DIR/helper.sh"

        echo "0" > "$INSTALL_DIR/state"
        chmod 666 "$INSTALL_DIR/state"
        chmod 777 "$INSTALL_DIR"

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
