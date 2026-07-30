import Foundation
import Combine

/// Derives Codex CLI session state from its rollout transcripts at
/// `~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl`.
///
/// Codex has no equivalent of Claude Code's per-PID status file -- its SQLite state carries a
/// `threads` table with `rollout_path` and timestamps, but no pid and no status column. What
/// it does write, in real time, are turn-boundary events: a turn opens with an `event_msg`
/// payload of `task_started` and closes with `task_complete` (or `turn_aborted` when the user
/// interrupts). Reading backwards for the most recent of those is enough to know whether a
/// turn is in flight, and `task_started` lands seconds before the turn ends rather than being
/// flushed at the end.
///
/// This is preferred over Codex's lifecycle hooks for the same reason hooks were dropped for
/// Claude Code: `Stop` is documented not to fire on Ctrl+C (openai/codex#22858), whereas the
/// transcript records `turn_aborted`. It also needs no changes to the user's config.
///
/// Which transcripts are live is answered by asking `lsof` which rollout file each running
/// `codex` process holds open. Scanning the directory by modification time instead would count
/// every session from the past day, including ones whose process exited hours ago -- the
/// transcript itself records nothing that identifies its writer.
final class CodexSessionMonitor: ObservableObject {
    @Published private(set) var sessions: [AgentSession] = []
    @Published private(set) var lastChecked = Date()

    private var timer: Timer?
    private var cache: [String: Parsed] = [:]

    private struct Parsed {
        let modified: Date
        let size: UInt64
        let originator: String?
        let cwd: String?
        let lastBoundary: String?
    }

    func start(interval: TimeInterval = 3) {
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
        defer { lastChecked = Date() }

        let pids = ProcessProbe.pids(forCLINamed: "codex")
        guard !pids.isEmpty else {
            if !sessions.isEmpty { sessions = [] }
            cache.removeAll()
            return
        }

        let open = ProcessProbe.openFiles(pids: pids) { path in
            path.hasSuffix(".jsonl") && (path as NSString).lastPathComponent.hasPrefix("rollout-")
        }

        // Codex is running but its transcript couldn't be located -- lsof unavailable, or a
        // future version that writes differently. Report one session of unknown activity,
        // which counts as working: better to keep the Mac awake than to sleep mid-task.
        guard !open.isEmpty else {
            sessions = [AgentSession(
                id: "codex-unknown",
                tool: .codex,
                displayName: "codex",
                activity: .unknown
            )]
            return
        }

        var found: [AgentSession] = []
        var seenPaths: Set<String> = []

        for entry in open where !seenPaths.contains(entry.path) {
            seenPaths.insert(entry.path)
            let url = URL(fileURLWithPath: entry.path)
            guard let parsed = parse(url) else { continue }
            // `codex-tui` is the interactive TUI; `codex_exec` is a headless `codex exec` run,
            // which is a one-shot script rather than a session someone is sitting at.
            guard parsed.originator == "codex-tui" else { continue }

            let name = URL(fileURLWithPath: parsed.cwd ?? "").lastPathComponent
            found.append(
                AgentSession(
                    id: "codex-\(entry.pid)",
                    tool: .codex,
                    displayName: name.isEmpty ? "codex" : name,
                    activity: parsed.lastBoundary == "task_started" ? .working : .idle
                )
            )
        }

        cache = cache.filter { seenPaths.contains($0.key) }
        found.sort { $0.displayName.localizedCompare($1.displayName) == .orderedAscending }
        sessions = found
    }

    /// Parses a transcript, reusing the previous result while the file is unchanged. Only the
    /// first line (session metadata) and the tail (recent events) are read -- transcripts grow
    /// without bound and re-reading them whole every few seconds would be wasteful.
    private func parse(_ url: URL) -> Parsed? {
        let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
        let modified = values?.contentModificationDate ?? .distantPast
        let size = UInt64(values?.fileSize ?? 0)

        if let cached = cache[url.path], cached.modified == modified, cached.size == size {
            return cached
        }

        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }

        let originator: String?
        let cwd: String?
        if let cached = cache[url.path] {
            // Session metadata is written once at the top and never changes.
            originator = cached.originator
            cwd = cached.cwd
        } else {
            let meta = Self.firstLineJSON(handle)
            let payload = (meta?["payload"] as? [String: Any]) ?? meta
            originator = payload?["originator"] as? String
            cwd = payload?["cwd"] as? String
        }

        let parsed = Parsed(
            modified: modified,
            size: size,
            originator: originator,
            cwd: cwd,
            lastBoundary: Self.lastTurnBoundary(handle, size: size)
        )
        cache[url.path] = parsed
        return parsed
    }

    private static let boundaryEvents: Set<String> = ["task_started", "task_complete", "turn_aborted"]

    /// Reads the tail and returns the most recent turn-boundary event name.
    private static func lastTurnBoundary(_ handle: FileHandle, size: UInt64) -> String? {
        let tailBytes: UInt64 = 256 * 1024
        let offset = size > tailBytes ? size - tailBytes : 0
        try? handle.seek(toOffset: offset)
        guard let data = try? handle.readToEnd(), !data.isEmpty else { return nil }

        var lines = data.split(separator: UInt8(ascii: "\n"), omittingEmptySubsequences: true)
        // A mid-file start can slice a line in half; that fragment isn't valid JSON anyway,
        // but drop it explicitly rather than relying on the parse failing.
        if offset > 0, !lines.isEmpty { lines.removeFirst() }

        for line in lines.reversed() {
            guard
                let object = try? JSONSerialization.jsonObject(with: Data(line)) as? [String: Any],
                object["type"] as? String == "event_msg",
                let payload = object["payload"] as? [String: Any],
                let eventType = payload["type"] as? String,
                boundaryEvents.contains(eventType)
            else { continue }
            return eventType
        }
        return nil
    }

    /// The metadata line carries the full system prompt, so it can be large; read in chunks
    /// until the first newline rather than guessing a size.
    private static func firstLineJSON(_ handle: FileHandle) -> [String: Any]? {
        try? handle.seek(toOffset: 0)
        var buffer = Data()
        let chunkSize = 64 * 1024
        let maxBytes = 4 * 1024 * 1024

        while buffer.count < maxBytes {
            guard let chunk = try? handle.read(upToCount: chunkSize), !chunk.isEmpty else { break }
            buffer.append(chunk)
            if let newline = buffer.firstIndex(of: UInt8(ascii: "\n")) {
                let line = buffer[buffer.startIndex..<newline]
                return try? JSONSerialization.jsonObject(with: Data(line)) as? [String: Any]
            }
        }
        return nil
    }
}
