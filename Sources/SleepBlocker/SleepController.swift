import Foundation
import IOKit.pwr_mgt

/// Prevents the Mac from idle-sleeping while active, using an IOPMAssertion.
/// When the privileged helper is installed, it also mirrors the desired state into a
/// shared state file so the LaunchDaemon can toggle `pmset disablesleep`, which is what
/// actually keeps the machine awake with the lid closed and no external display attached.
final class SleepController {
    private var assertionID: IOPMAssertionID = 0
    private(set) var isPreventingIdleSleep = false

    private let stateFileURL = URL(fileURLWithPath: HelperInstaller.stateFilePath)

    func activate() {
        if !isPreventingIdleSleep {
            var id: IOPMAssertionID = 0
            let reason = "Vide Sleep Blocker: AI coding session active" as CFString
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
        writeDesiredState("1")
    }

    func deactivate() {
        if isPreventingIdleSleep {
            IOPMAssertionRelease(assertionID)
            isPreventingIdleSleep = false
        }
        writeDesiredState("0")
    }

    private func writeDesiredState(_ value: String) {
        guard HelperInstaller.isInstalled() else { return }
        try? value.write(to: stateFileURL, atomically: true, encoding: .utf8)
    }
}
