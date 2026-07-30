import Foundation

enum ProcessProbe {
    /// True when a CLI with this executable name is running. Matches the basename of the
    /// executable rather than the whole command line, so an unrelated process that merely
    /// mentions the name in its arguments (`grep codex ...`) doesn't count, and skips
    /// executables inside .app bundles so a desktop app of the same name -- Claude.app's
    /// `Claude` versus the `claude` CLI -- isn't mistaken for the CLI.
    static func isCLIRunning(named name: String) -> Bool {
        let target = name.lowercased()
        return runningCLIExecutableNames().contains(target)
    }

    static func runningCLIExecutableNames() -> Set<String> {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-Ao", "comm="]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return []
        }

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard let text = String(data: data, encoding: .utf8) else { return [] }

        var names: Set<String> = []
        for line in text.split(separator: "\n") {
            let path = String(line)
            guard !path.localizedCaseInsensitiveContains(".app/Contents/") else { continue }
            names.insert((path as NSString).lastPathComponent.lowercased())
        }
        return names
    }

    /// PIDs of running CLIs with this executable name, matched the same way as `isCLIRunning`.
    static func pids(forCLINamed name: String) -> [pid_t] {
        let target = name.lowercased()

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-Ao", "pid=,comm="]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return []
        }

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard let text = String(data: data, encoding: .utf8) else { return [] }

        var result: [pid_t] = []
        for line in text.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard let space = trimmed.firstIndex(of: " ") else { continue }
            let pidPart = String(trimmed[trimmed.startIndex..<space])
            let path = String(trimmed[trimmed.index(after: space)...]).trimmingCharacters(in: .whitespaces)
            guard let pid = pid_t(pidPart) else { continue }
            guard !path.localizedCaseInsensitiveContains(".app/Contents/") else { continue }
            guard (path as NSString).lastPathComponent.lowercased() == target else { continue }
            result.append(pid)
        }
        return result
    }

    /// Files currently held open by the given processes, keyed by PID. Used to tie a CLI
    /// process to the transcript it is writing, which is the only way to tell a live session
    /// from a finished one when the transcript itself records no process identity.
    static func openFiles(pids: [pid_t], matching predicate: (String) -> Bool) -> [(pid: pid_t, path: String)] {
        guard !pids.isEmpty else { return [] }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        // -Fpn prints one record per line: `p<pid>` starts a process block, `n<name>` names a
        // file within it. Machine-readable and stable, unlike the columnar default output.
        process.arguments = ["-Fpn", "-p", pids.map(String.init).joined(separator: ",")]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return []
        }

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard let text = String(data: data, encoding: .utf8) else { return [] }

        var results: [(pid: pid_t, path: String)] = []
        var currentPID: pid_t?
        for line in text.split(separator: "\n") {
            guard let marker = line.first else { continue }
            let value = String(line.dropFirst())
            switch marker {
            case "p": currentPID = pid_t(value)
            case "n":
                if let pid = currentPID, predicate(value) {
                    results.append((pid, value))
                }
            default: break
            }
        }
        return results
    }

    /// Signal 0 checks for existence without delivering anything. EPERM would mean the process
    /// exists but belongs to another user -- impossible here, but treated as alive.
    static func isAlive(pid: pid_t) -> Bool {
        guard pid > 0 else { return false }
        if kill(pid, 0) == 0 { return true }
        return errno == EPERM
    }
}
