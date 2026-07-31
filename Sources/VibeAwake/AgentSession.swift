import Foundation
import SwiftUI

enum AgentTool: String {
    case claudeCode
    case codex

    var displayName: String {
        switch self {
        case .claudeCode: return "Claude Code"
        case .codex: return "Codex CLI"
        }
    }
}

/// What a session is doing, normalised across tools. Each tool reports state in its own way
/// -- Claude Code publishes a status field, Codex has to be read from turn-boundary events --
/// so everything above the monitors works in these terms instead.
enum SessionActivity {
    /// Generating, running a tool, or driving a subagent.
    case working
    /// Blocked on a permission/input prompt. Claude Code only; Codex doesn't expose it.
    case waitingForApproval
    /// Sitting at the prompt with nothing in flight.
    case idle
    /// State couldn't be determined. Counted as working, on the principle that keeping the
    /// Mac awake unnecessarily beats sleeping in the middle of a task.
    case unknown

    var label: String {
        switch self {
        case .working: return L("activity.working")
        case .waitingForApproval: return L("activity.waiting")
        case .idle: return L("activity.idle")
        case .unknown: return L("activity.unknown")
        }
    }

    var color: Color {
        switch self {
        case .working: return .green
        case .waitingForApproval: return .orange
        case .idle: return .secondary.opacity(0.3)
        case .unknown: return .secondary.opacity(0.5)
        }
    }
}

struct AgentSession: Identifiable {
    let id: String
    let tool: AgentTool
    let displayName: String
    let activity: SessionActivity
}

/// Counts bucketed the way the dashboard presents them, so a dozen sessions read as three
/// numbers instead of a dozen rows.
struct SessionSummary {
    var working = 0
    var waiting = 0
    var idle = 0

    var total: Int { working + waiting + idle }
}
