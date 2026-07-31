import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppState

    @State private var launchAtLoginEnabled = LaunchAtLogin.isEnabled
    @State private var launchAtLoginError: String?
    @State private var showInstalledPaths = false

    private var versionString: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "-"
        let build = info?["CFBundleVersion"] as? String ?? "-"
        return "\(version) (\(build))"
    }

    var body: some View {
        Form {
            if appState.helperInstalled {
                installedHelperSection
            } else {
                setupSection
            }

            Section(L("settings.section.general")) {
                Toggle(L("settings.enable"), isOn: $appState.isEnabled)
                Toggle(L("settings.launchAtLogin"), isOn: launchAtLoginBinding)
                if let launchAtLoginError {
                    Text(launchAtLoginError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .disabled(!appState.helperInstalled)

            Section {
                Toggle(L("settings.sleepDisplay"), isOn: $appState.sleepDisplayOnLidClose)
                Text(L("settings.sleepDisplay.note"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text(L("settings.section.display"))
            }
            .disabled(!appState.helperInstalled)

            Section {
                Toggle(L("settings.treatWaitingAsActive"), isOn: $appState.treatWaitingAsActive)
                Text(L("settings.treatWaitingAsActive.note"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text(L("settings.section.approval"))
            }
            .disabled(!appState.helperInstalled)

            Section {
                if appState.summary.total == 0 && !appState.isUsingClaudeProcessFallback {
                    Text(L("settings.noSessions"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    LabeledContent(L("activity.working")) { Text(L("settings.count", appState.summary.working)) }
                    LabeledContent(L("activity.waiting")) { Text(L("settings.count", appState.summary.waiting)) }
                    LabeledContent(L("activity.idle")) { Text(L("settings.count", appState.summary.idle)) }
                }

                Divider()

                ForEach(toolRows, id: \.tool) { row in
                    LabeledContent(row.tool.displayName) {
                        Text(row.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if appState.isUsingClaudeProcessFallback {
                    Text(L("settings.claudeFallback"))
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !appState.activeSessions.isEmpty {
                    Divider()
                    ForEach(appState.activeSessions.prefix(5)) { session in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(session.activity.color)
                                .frame(width: 7, height: 7)
                            Text(session.displayName)
                                .font(.caption)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer(minLength: 6)
                            Text(session.tool.displayName)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if appState.activeSessions.count > 5 {
                        Text(L("settings.moreSessions", appState.activeSessions.count - 5))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text(L("settings.section.sessions"))
            }

            Section(L("settings.section.about")) {
                LabeledContent("Vibe Awake") {
                    Text(versionString).foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 640)
        .onAppear { launchAtLoginEnabled = LaunchAtLogin.isEnabled }
    }

    private var toolRows: [(tool: AgentTool, detail: String)] {
        [AgentTool.claudeCode, .codex].map { tool in
            let sessions = appState.sessions(for: tool)
            if sessions.isEmpty {
                let fallback = tool == .claudeCode && appState.isUsingClaudeProcessFallback
                return (tool, fallback ? L("settings.tool.unknownState") : L("settings.tool.none"))
            }
            let working = sessions.filter { $0.activity != .idle }.count
            return (tool, L("settings.tool.summary", sessions.count, working))
        }
    }

    // MARK: - Setup

    private var setupSection: some View {
        Section {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 4) {
                    Text(appState.helperNeedsUpdate ? SetupCopy.updateTitle : SetupCopy.title)
                        .fontWeight(.medium)
                    Text(appState.helperNeedsUpdate ? SetupCopy.updateShortReason : SetupCopy.shortReason)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(SetupCopy.assurances, id: \.text) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: item.icon)
                            .foregroundStyle(.secondary)
                            .frame(width: 16)
                        Text(item.text)
                            .font(.caption)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            DisclosureGroup(L("setup.installedItems"), isExpanded: $showInstalledPaths) {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(SetupCopy.installedPaths, id: \.self) { path in
                        Text(path)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.top, 2)
            }
            .font(.caption)

            VStack(alignment: .leading, spacing: 4) {
                Button(setupButtonTitle) { appState.installHelper() }
                    .disabled(appState.isInstalling)
                Text(SetupCopy.passwordNote)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if let error = appState.installError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } header: {
            Text(L("settings.section.lidClose"))
        }
    }

    private var setupButtonTitle: String {
        if appState.isInstalling { return SetupCopy.workingTitle }
        return appState.helperNeedsUpdate ? SetupCopy.updateButtonTitle : SetupCopy.buttonTitle
    }

    private var installedHelperSection: some View {
        Section {
            LabeledContent(L("settings.helper.state")) {
                Label(L("settings.helper.enabled"), systemImage: "checkmark.shield.fill")
                    .foregroundStyle(.green)
            }
            Text(L("settings.helper.note"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button(L("settings.helper.remove")) {
                appState.uninstallHelper()
            }
            .disabled(appState.isInstalling)

            if let error = appState.installError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } header: {
            Text(L("settings.section.lidClose"))
        }
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { launchAtLoginEnabled },
            set: { newValue in
                do {
                    try LaunchAtLogin.setEnabled(newValue)
                    launchAtLoginEnabled = newValue
                    launchAtLoginError = nil
                } catch {
                    launchAtLoginError = error.localizedDescription
                    launchAtLoginEnabled = LaunchAtLogin.isEnabled
                }
            }
        )
    }
}
