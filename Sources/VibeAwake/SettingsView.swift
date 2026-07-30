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

            Section("一般") {
                Toggle("スリープ防止を有効にする", isOn: $appState.isEnabled)
                Toggle("ログイン時に自動起動", isOn: launchAtLoginBinding)
                if let launchAtLoginError {
                    Text(launchAtLoginError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .disabled(!appState.helperInstalled)

            Section {
                Toggle("承認待ちもスリープ防止の対象にする", isOn: $appState.treatWaitingAsActive)
                Text("Claude Code が権限の確認などで入力を待っている状態を、作業中とみなすかどうか。スマホなどから遠隔で承認する場合は ON にしてください。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text("承認待ちの扱い")
            }
            .disabled(!appState.helperInstalled)

            Section {
                if appState.summary.total == 0 && !appState.isUsingClaudeProcessFallback {
                    Text("稼働中のセッションはありません。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    LabeledContent("作業中") { Text("\(appState.summary.working) 件") }
                    LabeledContent("承認待ち") { Text("\(appState.summary.waiting) 件") }
                    LabeledContent("待機中") { Text("\(appState.summary.idle) 件") }
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
                    Text("Claude Code の状態を取得できません。バージョンが古い可能性があります。プロセスが動いている間はスリープを防止します。")
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
                        Text("他 \(appState.activeSessions.count - 5) 件")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("セッション")
            }

            Section("バージョン情報") {
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
                return (tool, fallback ? "起動中(状態不明)" : "セッションなし")
            }
            let working = sessions.filter { $0.activity != .idle }.count
            return (tool, "\(sessions.count) 件中 \(working) 件が作業中")
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

            DisclosureGroup("インストールされるもの", isExpanded: $showInstalledPaths) {
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
            Text("蓋クローズ時のスリープ防止")
        }
    }

    private var setupButtonTitle: String {
        if appState.isInstalling { return SetupCopy.workingTitle }
        return appState.helperNeedsUpdate ? SetupCopy.updateButtonTitle : SetupCopy.buttonTitle
    }

    private var installedHelperSection: some View {
        Section {
            LabeledContent("状態") {
                Label("有効", systemImage: "checkmark.shield.fill")
                    .foregroundStyle(.green)
            }
            Text("蓋を閉じてもスリープしません。アプリが動いていない間は自動的に無効になります。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button("ヘルパーを削除") {
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
            Text("蓋クローズ時のスリープ防止")
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
