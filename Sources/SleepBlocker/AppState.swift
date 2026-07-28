import Foundation
import Combine
import SwiftUI

/// Bridges Claude Code session state to the sleep controller, and exposes the privileged
/// helper actions plus the summary the dashboard and settings windows render.
final class AppState: ObservableObject {
    private static let enabledDefaultsKey = "isSleepBlockingEnabled"
    private static let waitingDefaultsKey = "treatWaitingAsActive"

    @Published private(set) var isBlockingSleep = false
    @Published private(set) var helperInstalled = HelperInstaller.isInstalled()
    @Published var installError: String?
    @Published private(set) var isInstalling = false

    @Published private(set) var summary = SessionSummary()
    /// The sessions currently holding sleep open, for naming them in the UI.
    @Published private(set) var activeSessions: [ClaudeSession] = []
    @Published private(set) var isUsingProcessFallback = false

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
    private var sessions: [ClaudeSession] = []
    private var cancellables = Set<AnyCancellable>()

    init(claudeMonitor: ClaudeSessionMonitor, sleepController: SleepController) {
        self.sleepController = sleepController

        let defaults = UserDefaults.standard
        self.isEnabled = (defaults.object(forKey: Self.enabledDefaultsKey) as? Bool) ?? true
        self.treatWaitingAsActive = (defaults.object(forKey: Self.waitingDefaultsKey) as? Bool) ?? true

        claudeMonitor.$sessions
            .sink { [weak self] sessions in
                guard let self else { return }
                self.sessions = sessions
                self.refreshBlockingState()
            }
            .store(in: &cancellables)

        claudeMonitor.$isUsingProcessFallback
            .sink { [weak self] fallback in
                guard let self else { return }
                self.isUsingProcessFallback = fallback
                self.refreshBlockingState()
            }
            .store(in: &cancellables)
    }

    func countsAsActive(_ status: ClaudeSession.Status) -> Bool {
        switch status {
        case .busy, .shell:
            return true
        case .waiting:
            return treatWaitingAsActive
        case .idle:
            return false
        case .unknown:
            // An older Claude Code that doesn't report status. Assume the worst and keep the
            // machine awake rather than risk sleeping mid-task.
            return true
        }
    }

    private func refreshBlockingState() {
        var counts = SessionSummary()
        for session in sessions {
            switch session.status {
            case .busy, .shell, .unknown: counts.working += 1
            case .waiting: counts.waiting += 1
            case .idle: counts.idle += 1
            }
        }
        summary = counts
        activeSessions = sessions.filter { countsAsActive($0.status) }

        let anyActive = sessions.isEmpty ? isUsingProcessFallback : !activeSessions.isEmpty
        let shouldBlock = isEnabled && anyActive

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
                self.helperInstalled = HelperInstaller.isInstalled()
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
                self.helperInstalled = HelperInstaller.isInstalled()
            case .failure(let error):
                self.installError = error.localizedDescription
            }
        }
    }

    func shutdown() {
        sleepController.deactivate()
    }
}
