import Foundation
import Combine

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
    @Published private(set) var sessions: [AgentSession] = []
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

        var found: [AgentSession] = []
        for file in files where file.pathExtension == "json" {
            guard
                let data = try? Data(contentsOf: file),
                let raw = try? JSONDecoder().decode(SessionFile.self, from: data)
            else { continue }

            // Only interactive TUI sessions register here; headless `claude -p` runs don't.
            guard raw.kind == nil || raw.kind == "interactive" else { continue }
            guard ProcessProbe.isAlive(pid: raw.pid) else { continue }

            let name = raw.name ?? URL(fileURLWithPath: raw.cwd ?? "").lastPathComponent
            found.append(
                AgentSession(
                    id: "claude-\(raw.sessionId ?? String(raw.pid))",
                    tool: .claudeCode,
                    displayName: name.isEmpty ? "claude" : name,
                    activity: Self.activity(for: raw.status)
                )
            )
        }

        found.sort { $0.displayName.localizedCompare($1.displayName) == .orderedAscending }

        sessions = found
        // Only worth shelling out to `ps` when the status files told us nothing.
        isUsingProcessFallback = found.isEmpty && ProcessProbe.isCLIRunning(named: "claude")
        lastChecked = Date()
    }

    /// Claude Code marks itself `busy` while generating, running a tool or driving a subagent;
    /// `waiting` while blocked on a permission/input dialog; `shell` when idle at the prompt
    /// but a background shell is still live; `idle` with nothing in flight.
    private static func activity(for status: String?) -> SessionActivity {
        switch status {
        case "busy", "shell": return .working
        case "waiting": return .waitingForApproval
        case "idle": return .idle
        default: return .unknown
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
