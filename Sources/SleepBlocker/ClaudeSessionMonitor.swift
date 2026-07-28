import Foundation
import Combine
import SwiftUI

/// One live Claude Code session, as reported by its own status file.
struct ClaudeSession: Identifiable {
    let id: String
    let pid: pid_t
    let cwd: String
    let name: String?
    let status: Status

    /// Mirrors the status enum Claude Code writes: it marks itself `busy` while the
    /// assistant is generating, a tool is running, or a subagent is active; `waiting` while
    /// blocked on a permission/input dialog; `shell` when idle at the prompt but a
    /// background shell is still live; `idle` at the prompt with nothing in flight.
    enum Status: String {
        case busy
        case waiting
        case shell
        case idle
        /// Status field absent -- an older Claude Code that predates this file format.
        case unknown
    }

    var displayName: String {
        name ?? URL(fileURLWithPath: cwd).lastPathComponent
    }
}

/// Counts bucketed the way the dashboard presents them, so a dozen sessions read as three
/// numbers instead of a dozen rows.
struct SessionSummary {
    var working = 0
    var waiting = 0
    var idle = 0

    var total: Int { working + waiting + idle }
}

/// Reads the status files Claude Code maintains at `~/.claude/sessions/<pid>.json` -- one per
/// running interactive session, updated on every state transition. This is a far more exact
/// signal than watching processes or CPU: it distinguishes "generating a response" from
/// "sitting at the prompt", and it stays correct through Ctrl+C, API errors and slash
/// commands, all of which leave lifecycle hooks with no matching end event.
///
/// Being an undocumented implementation detail, every read is defensive: files that fail to
/// parse are skipped, a missing status degrades to `.unknown` (treated as working), and a PID
/// that is no longer alive is ignored so a `busy` file left behind by `kill -9` can't pin the
/// machine awake forever. If no status files exist at all but `claude` is running, that's a
/// build too old to write them, and `isUsingProcessFallback` says so.
final class ClaudeSessionMonitor: ObservableObject {
    @Published private(set) var sessions: [ClaudeSession] = []
    @Published private(set) var isUsingProcessFallback = false
    @Published private(set) var lastChecked = Date()

    private var timer: Timer?

    static var sessionsDirectory: URL {
        let base: URL
        if let configDir = ProcessInfo.processInfo.environment["CLAUDE_CONFIG_DIR"], !configDir.isEmpty {
            base = URL(fileURLWithPath: configDir)
        } else {
            base = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".claude")
        }
        return base.appendingPathComponent("sessions", isDirectory: true)
    }

    func start(interval: TimeInterval = 2) {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func refresh() {
        let dir = Self.sessionsDirectory
        let files = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []

        var found: [ClaudeSession] = []
        for file in files where file.pathExtension == "json" {
            guard
                let data = try? Data(contentsOf: file),
                let raw = try? JSONDecoder().decode(SessionFile.self, from: data)
            else { continue }

            // Only interactive TUI sessions register here; headless `claude -p` runs don't.
            guard raw.kind == nil || raw.kind == "interactive" else { continue }
            guard Self.isProcessAlive(raw.pid) else { continue }

            found.append(
                ClaudeSession(
                    id: raw.sessionId ?? "\(raw.pid)",
                    pid: raw.pid,
                    cwd: raw.cwd ?? "",
                    name: raw.name,
                    status: raw.status.flatMap(ClaudeSession.Status.init(rawValue:)) ?? .unknown
                )
            )
        }

        found.sort { $0.displayName.localizedCompare($1.displayName) == .orderedAscending }

        sessions = found
        // Only worth shelling out to `ps` when the status files told us nothing.
        isUsingProcessFallback = found.isEmpty && Self.isClaudeCLIRunning()
        lastChecked = Date()
    }

    /// Signal 0 checks for existence without delivering anything. EPERM would mean the
    /// process exists but belongs to another user -- impossible here, but treated as alive.
    private static func isProcessAlive(_ pid: pid_t) -> Bool {
        guard pid > 0 else { return false }
        if kill(pid, 0) == 0 { return true }
        return errno == EPERM
    }

    /// Fallback probe for Claude Code builds that predate the status files. Matches the
    /// executable name rather than the full command line, so an unrelated process that merely
    /// mentions "claude" in its arguments doesn't count, and skips executables inside .app
    /// bundles so the Claude desktop app isn't mistaken for the CLI.
    private static func isClaudeCLIRunning() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-Ao", "comm="]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return false
        }

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard let text = String(data: data, encoding: .utf8) else { return false }
        return text.split(separator: "\n").contains { line in
            let path = String(line)
            guard !path.localizedCaseInsensitiveContains(".app/Contents/") else { return false }
            return (path as NSString).lastPathComponent.lowercased() == "claude"
        }
    }

    private struct SessionFile: Decodable {
        let pid: pid_t
        let sessionId: String?
        let cwd: String?
        let name: String?
        let kind: String?
        let status: String?
    }
}
