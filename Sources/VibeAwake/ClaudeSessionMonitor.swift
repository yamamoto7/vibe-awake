import Foundation
import Combine

/// Reads the status files Claude Code maintains at `<config dir>/sessions/<pid>.json` -- one
/// per running session, interactive or a detached background agent, updated on every state
/// transition. This is a far more exact signal than watching processes or CPU: it
/// distinguishes "generating a response" from "sitting at the prompt", and it stays correct
/// through Ctrl+C, API errors and slash commands, all of which leave lifecycle hooks with no
/// matching end event.
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

    /// Re-reading the home directory on every tick would be wasteful; a profile appearing or
    /// disappearing is rare enough that noticing it within half a minute is plenty.
    private static let directoryRescanInterval: TimeInterval = 30
    private var cachedDirectories: [URL] = []
    private var directoriesCachedAt: Date?

    /// Every config directory worth watching. `CLAUDE_CONFIG_DIR` points Claude Code at a
    /// profile other than `~/.claude` -- `~/.claude-work`, say -- and each profile keeps its
    /// own `sessions` directory, so watching only one leaves the rest of the machine's
    /// sessions invisible.
    ///
    /// The profiles have to be found by name. Reading `CLAUDE_CONFIG_DIR` out of the running
    /// CLI processes isn't possible: macOS only exposes a process's environment to its own
    /// ancestors, and the CLI holds no file open that would give the directory away. Our own
    /// copy of the variable is no help either -- as a login item the app inherits nothing from
    /// the shell -- though it is still honoured for the case where someone launches the app
    /// from a terminal. So: every `~/.claude*` directory. A profile kept outside the home
    /// directory, or under an unrelated name, stays invisible.
    static func discoverSessionsDirectories() -> [URL] {
        let fileManager = FileManager.default
        let home = fileManager.homeDirectoryForCurrentUser

        var bases: [URL] = []
        if let configDir = ProcessInfo.processInfo.environment["CLAUDE_CONFIG_DIR"], !configDir.isEmpty {
            bases.append(URL(fileURLWithPath: configDir))
        }
        bases.append(home.appendingPathComponent(".claude", isDirectory: true))

        // Not `.skipsHiddenFiles`: every one of these directories starts with a dot.
        let entries = (try? fileManager.contentsOfDirectory(
            at: home,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: []
        )) ?? []
        for entry in entries where entry.lastPathComponent.hasPrefix(".claude") {
            guard (try? entry.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true else { continue }
            bases.append(entry)
        }

        // Symlinks are resolved before deduplicating so an alias pointing at a profile we
        // already watch doesn't have every session counted twice.
        var seen: Set<String> = []
        var directories: [URL] = []
        for base in bases {
            let dir = base.appendingPathComponent("sessions", isDirectory: true)
            guard seen.insert(dir.resolvingSymlinksInPath().path).inserted else { continue }
            directories.append(dir)
        }
        return directories
    }

    private func sessionsDirectories() -> [URL] {
        if let cachedAt = directoriesCachedAt,
           Date().timeIntervalSince(cachedAt) < Self.directoryRescanInterval {
            return cachedDirectories
        }
        cachedDirectories = Self.discoverSessionsDirectories()
        directoriesCachedAt = Date()
        return cachedDirectories
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
        var found: [AgentSession] = []
        var seenIDs: Set<String> = []

        for dir in sessionsDirectories() {
            let files = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
            for file in files where file.pathExtension == "json" {
                guard
                    let data = try? Data(contentsOf: file),
                    let raw = try? JSONDecoder().decode(SessionFile.self, from: data)
                else { continue }

                // Interactive TUI sessions, plus the detached `bg` agents they spawn: those run
                // in their own process with their own status file, and are the only thing
                // reporting `busy` while the session that launched them sits parked at `idle`.
                // Headless `claude -p` runs don't register at all. A `bg` process straight out
                // of the spare pool carries `spare: true` and hasn't picked up any work yet; the
                // flag is cleared the moment it claims a job and goes busy.
                let kind = raw.kind ?? "interactive"
                guard kind == "interactive" || (kind == "bg" && raw.spare != true) else { continue }
                guard ProcessProbe.isAlive(pid: raw.pid) else { continue }

                let id = "claude-\(raw.sessionId ?? String(raw.pid))"
                guard seenIDs.insert(id).inserted else { continue }

                let name = raw.name ?? URL(fileURLWithPath: raw.cwd ?? "").lastPathComponent
                found.append(
                    AgentSession(
                        id: id,
                        tool: .claudeCode,
                        displayName: name.isEmpty ? "claude" : name,
                        activity: Self.activity(for: raw.status)
                    )
                )
            }
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
        let spare: Bool?
        let status: String?
    }
}
