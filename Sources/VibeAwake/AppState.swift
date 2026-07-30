import Foundation
import Combine
import SwiftUI

/// Bridges agent session state to the sleep controller, and exposes the privileged helper
/// actions plus the summary the dashboard and settings windows render.
final class AppState: ObservableObject {
    private static let enabledDefaultsKey = "isSleepBlockingEnabled"
    private static let waitingDefaultsKey = "treatWaitingAsActive"

    @Published private(set) var isBlockingSleep = false
    @Published private(set) var helperInstalled = HelperInstaller.isInstalled()
    /// An older helper is installed and can't understand the current state format.
    @Published private(set) var helperNeedsUpdate = HelperInstaller.needsUpdate()
    @Published var installError: String?
    @Published private(set) var isInstalling = false

    @Published private(set) var summary = SessionSummary()
    /// The sessions currently holding sleep open, for naming them in the UI.
    @Published private(set) var activeSessions: [AgentSession] = []
    @Published private(set) var isUsingClaudeProcessFallback = false

    /// Master on/off switch, persisted across launches and editable from Settings.
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Self.enabledDefaultsKey)
            refreshBlockingState()
        }
    }

    /// Whether a session blocked on a permission prompt counts as working. On is right when
    /// approving remotely (from a phone, say) -- the Mac has to stay reachable. Off lets it
    /// sleep while it waits for someone sitting at the keyboard.
    @Published var treatWaitingAsActive: Bool {
        didSet {
            UserDefaults.standard.set(treatWaitingAsActive, forKey: Self.waitingDefaultsKey)
            refreshBlockingState()
        }
    }

    private let sleepController: SleepController
    private var claudeSessions: [AgentSession] = []
    private var codexSessions: [AgentSession] = []
    private var cancellables = Set<AnyCancellable>()

    init(
        claudeMonitor: ClaudeSessionMonitor,
        codexMonitor: CodexSessionMonitor,
        sleepController: SleepController
    ) {
        self.sleepController = sleepController

        let defaults = UserDefaults.standard
        self.isEnabled = (defaults.object(forKey: Self.enabledDefaultsKey) as? Bool) ?? true
        self.treatWaitingAsActive = (defaults.object(forKey: Self.waitingDefaultsKey) as? Bool) ?? true

        claudeMonitor.$sessions
            .sink { [weak self] sessions in
                guard let self else { return }
                self.claudeSessions = sessions
                self.refreshBlockingState()
            }
            .store(in: &cancellables)

        codexMonitor.$sessions
            .sink { [weak self] sessions in
                guard let self else { return }
                self.codexSessions = sessions
                self.refreshBlockingState()
            }
            .store(in: &cancellables)

        claudeMonitor.$isUsingProcessFallback
            .sink { [weak self] fallback in
                guard let self else { return }
                self.isUsingClaudeProcessFallback = fallback
                self.refreshBlockingState()
            }
            .store(in: &cancellables)
    }

    func countsAsActive(_ activity: SessionActivity) -> Bool {
        switch activity {
        case .working, .unknown:
            return true
        case .waitingForApproval:
            return treatWaitingAsActive
        case .idle:
            return false
        }
    }

    func sessions(for tool: AgentTool) -> [AgentSession] {
        switch tool {
        case .claudeCode: return claudeSessions
        case .codex: return codexSessions
        }
    }

    private func refreshBlockingState() {
        let all = claudeSessions + codexSessions

        var counts = SessionSummary()
        for session in all {
            switch session.activity {
            case .working, .unknown: counts.working += 1
            case .waitingForApproval: counts.waiting += 1
            case .idle: counts.idle += 1
            }
        }
        summary = counts
        activeSessions = all.filter { countsAsActive($0.activity) }

        // The Claude fallback stands in for sessions we couldn't read at all, so it only
        // applies when that tool reported nothing.
        let claudeFallbackActive = claudeSessions.isEmpty && isUsingClaudeProcessFallback
        let anyActive = !activeSessions.isEmpty || claudeFallbackActive

        // Without the helper only idle sleep could be blocked -- closing the lid would still
        // sleep the Mac, which is the entire point of this app. Rather than half-work in a way
        // that looks like it works, do nothing at all until setup is done.
        let shouldBlock = isEnabled && helperInstalled && anyActive

        if shouldBlock {
            sleepController.activate()
        } else {
            sleepController.deactivate()
        }
        isBlockingSleep = shouldBlock
    }

    func installHelper() {
        isInstalling = true
        installError = nil
        HelperInstaller.install { [weak self] result in
            guard let self else { return }
            self.isInstalling = false
            switch result {
            case .success:
                self.refreshHelperState()
            case .failure(let error):
                self.installError = error.localizedDescription
            }
        }
    }

    func uninstallHelper() {
        isInstalling = true
        installError = nil
        HelperInstaller.uninstall { [weak self] result in
            guard let self else { return }
            self.isInstalling = false
            switch result {
            case .success:
                self.refreshHelperState()
            case .failure(let error):
                self.installError = error.localizedDescription
            }
        }
    }

    private func refreshHelperState() {
        helperInstalled = HelperInstaller.isInstalled()
        helperNeedsUpdate = HelperInstaller.needsUpdate()
        refreshBlockingState()
    }

    func shutdown() {
        sleepController.deactivate()
    }
}
