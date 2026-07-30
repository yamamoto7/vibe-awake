import Foundation
import IOKit.pwr_mgt

/// Prevents the Mac from idle-sleeping via an IOPMAssertion, and publishes the desired
/// lid-close state to the privileged helper through a shared file.
///
/// The file carries this process's PID and a refreshed timestamp alongside the flag, so the
/// helper can distinguish a live request from one left behind by a force-quit. That means the
/// flag has to keep being refreshed while active -- hence the heartbeat below -- but writes
/// are skipped when nothing changed and the last one is recent, so the helper isn't woken
/// every couple of seconds for no reason.
final class SleepController {
    private var assertionID: IOPMAssertionID = 0
    private(set) var isPreventingIdleSleep = false

    private var lastWrittenDesired: Int?
    private var lastWriteTime: Date?
    /// Comfortably inside the helper's staleness window, so a missed write or two is fine.
    private let heartbeatInterval: TimeInterval = 30

    private let stateFileURL = URL(fileURLWithPath: HelperInstaller.stateFilePath)

    func activate() {
        if !isPreventingIdleSleep {
            var id: IOPMAssertionID = 0
            let reason = "Vibe Awake: AI coding session active" as CFString
            let result = IOPMAssertionCreateWithName(
                kIOPMAssertionTypeNoIdleSleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                reason,
                &id
            )
            if result == kIOReturnSuccess {
                assertionID = id
                isPreventingIdleSleep = true
            }
        }
        writeDesiredState(1)
    }

    func deactivate() {
        if isPreventingIdleSleep {
            IOPMAssertionRelease(assertionID)
            isPreventingIdleSleep = false
        }
        writeDesiredState(0)
    }

    private func writeDesiredState(_ desired: Int) {
        let now = Date()
        if lastWrittenDesired == desired {
            // Nothing to say. Keep refreshing only while holding sleep open, so the helper
            // can tell this process is still alive.
            if desired == 0 { return }
            if let last = lastWriteTime, now.timeIntervalSince(last) < heartbeatInterval { return }
        }

        guard HelperInstaller.isInstalled() else { return }

        let pid = ProcessInfo.processInfo.processIdentifier
        let text = "desired=\(desired)\npid=\(pid)\nts=\(Int(now.timeIntervalSince1970))\n"
        // Deliberately not atomic: an atomic write replaces the file, which needs write access
        // to the root-owned directory and would drop the ownership the installer set up.
        guard (try? Data(text.utf8).write(to: stateFileURL)) != nil else { return }

        lastWrittenDesired = desired
        lastWriteTime = now
    }
}
