import SwiftUI

struct DashboardView: View {
    @ObservedObject var appState: AppState
    var onOpenSettings: () -> Void

    private var statusColor: Color {
        guard appState.isEnabled else { return .secondary.opacity(0.4) }
        return appState.isBlockingSleep ? .green : .secondary.opacity(0.4)
    }

    private var statusTitle: String {
        guard appState.isEnabled else { return L("status.disabled") }
        return L(appState.isBlockingSleep ? "status.active" : "status.standby")
    }

    private var statusDetail: String {
        if !appState.isEnabled { return L("detail.disabledInSettings") }
        if appState.isUsingClaudeProcessFallback { return L("detail.claudeStateUnavailable") }

        let active = appState.activeSessions
        if active.isEmpty {
            return appState.summary.total == 0
                ? L("detail.noSessions")
                : L("detail.allIdle")
        }
        if active.count == 1 {
            return L("detail.oneWorking", active[0].displayName, active[0].tool.displayName)
        }
        return L("detail.manyWorking", active.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if appState.helperInstalled {
                normalContent
            } else {
                setupRequiredContent
            }

            Divider()

            HStack {
                Button(L("button.settings")) { onOpenSettings() }
                Spacer()
                Button(L("button.quit")) { NSApp.terminate(nil) }
            }
        }
        .padding(14)
        .frame(width: 288)
    }

    @ViewBuilder
    private var normalContent: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 9, height: 9)
                .padding(.top, 4)
            VStack(alignment: .leading, spacing: 2) {
                Text(statusTitle)
                    .font(.headline)
                Text(statusDetail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }

        if appState.summary.total > 0 {
            Divider()
            HStack(spacing: 0) {
                countCell(L("activity.working"), appState.summary.working, .green)
                countCell(L("activity.waiting"), appState.summary.waiting, .orange)
                countCell(L("activity.idle"), appState.summary.idle, .secondary)
            }
        }
    }

    /// Until the helper is in place the app genuinely does nothing, so the popover shows the
    /// setup prompt instead of a status readout that would imply it is working.
    @ViewBuilder
    private var setupRequiredContent: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .padding(.top, 1)
            Text(appState.helperNeedsUpdate ? SetupCopy.updateTitle : SetupCopy.title)
                .font(.headline)
        }

        Text(appState.helperNeedsUpdate ? SetupCopy.updateShortReason : SetupCopy.shortReason)
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)

        VStack(alignment: .leading, spacing: 3) {
            Button(setupButtonTitle) { appState.installHelper() }
                .disabled(appState.isInstalling)
            Text(SetupCopy.passwordNote)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }

        if let error = appState.installError {
            Text(error)
                .font(.caption2)
                .foregroundStyle(.red)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var setupButtonTitle: String {
        if appState.isInstalling { return SetupCopy.workingTitle }
        return appState.helperNeedsUpdate ? SetupCopy.updateButtonTitle : SetupCopy.buttonTitle
    }

    private func countCell(_ label: String, _ value: Int, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(value > 0 ? color : .secondary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
