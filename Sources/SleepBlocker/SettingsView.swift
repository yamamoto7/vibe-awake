import SwiftUI

struct SettingsView: View {
    @ObservedObject var claudeMonitor: ClaudeSessionMonitor
    @ObservedObject var appState: AppState

    @State private var launchAtLoginEnabled = LaunchAtLogin.isEnabled
    @State private var launchAtLoginError: String?

    private var versionString: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "-"
        let build = info?["CFBundleVersion"] as? String ?? "-"
        return "\(version) (\(build))"
    }

    var body: some View {
        Form {
            Section {
                if appState.helperInstalled {
                    LabeledContent("状態") {
                        Label("有効", systemImage: "checkmark.shield.fill")
                            .foregroundStyle(.green)
                    }
                    Button("ヘルパーをアンインストール") {
                        appState.uninstallHelper()
                    }
                    .disabled(appState.isInstalling)
                } else {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("ヘルパーが未インストールです")
                                .fontWeight(.medium)
                            Text("このままでは蓋を閉じたときにスリープしてしまいます。macOS では蓋を閉じたときのスリープを止めるのに root 権限が必要なため、一度だけ管理者パスワードの入力を求めます。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Button(appState.isInstalling ? "インストール中..." : "ヘルパーをインストール...") {
                        appState.installHelper()
                    }
                    .disabled(appState.isInstalling)
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

            Section("一般") {
                Toggle("スリープ防止を有効にする", isOn: $appState.isEnabled)
                Toggle("ログイン時に自動起動", isOn: launchAtLoginBinding)
                if let launchAtLoginError {
                    Text(launchAtLoginError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Toggle("承認待ちもスリープ防止の対象にする", isOn: $appState.treatWaitingAsActive)
                Text("Claude Code が権限の確認などで入力を待っている状態を、作業中とみなすかどうか。スマホなどから遠隔で承認する場合は ON にしてください。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text("承認待ちの扱い")
            }

            Section {
                if appState.isUsingProcessFallback {
                    Text("Claude Code は起動していますが、セッションの状態を取得できません。バージョンが古い可能性があります。プロセスが動いている間はスリープを防止します。")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                } else if appState.summary.total == 0 {
                    Text("稼働中のセッションはありません。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    LabeledContent("作業中") { Text("\(appState.summary.working) 件") }
                    LabeledContent("承認待ち") { Text("\(appState.summary.waiting) 件") }
                    LabeledContent("待機中") { Text("\(appState.summary.idle) 件") }

                    if !appState.activeSessions.isEmpty {
                        Divider()
                        ForEach(appState.activeSessions.prefix(5)) { session in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(session.status == .waiting ? Color.orange : Color.green)
                                    .frame(width: 7, height: 7)
                                Text(session.displayName)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                        if appState.activeSessions.count > 5 {
                            Text("他 \(appState.activeSessions.count - 5) 件")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Claude Code セッション")
            }

            Section("バージョン情報") {
                LabeledContent("Vide Sleep Blocker") {
                    Text(versionString).foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 560)
        .onAppear { launchAtLoginEnabled = LaunchAtLogin.isEnabled }
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
