import Foundation
import CoreGraphics
import IOKit

/// Turns the built-in display off while the lid is closed.
///
/// Blocking sleep keeps the whole machine running, and macOS does not power the internal
/// panel down on its own in that state -- it stays lit behind a closed lid, drawing power and
/// making heat for nobody. `pmset displaysleepnow` puts it to sleep, and with the lid shut
/// there is no user activity to wake it again. It needs no privileges, so this runs straight
/// from the app rather than through the helper.
final class DisplaySleepController {
    /// Re-issued at this interval while the lid stays closed, in case something woke the
    /// display in the meantime.
    private let retryInterval: TimeInterval = 10
    private var lastRequest: Date?

    private var timer: Timer?
    private var shouldRun: () -> Bool

    /// - Parameter shouldRun: whether the feature is enabled and sleep is currently being
    ///   blocked. Checked on every tick so the caller's state stays authoritative.
    init(shouldRun: @escaping () -> Bool) {
        self.shouldRun = shouldRun
    }

    func start(interval: TimeInterval = 2) {
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.evaluate()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func evaluate() {
        guard shouldRun() else {
            lastRequest = nil
            return
        }
        guard Self.isLidClosed() == true else {
            lastRequest = nil
            return
        }
        // Only when there is nothing else to look at. Someone running clamshell with an
        // external monitor is using that screen, and blanking it would be actively hostile.
        // An unreadable display list is treated as "there might be one" and left alone.
        guard Self.isExternalDisplayConnected() == false else { return }
        // Nothing to do if it is already off; this also keeps the retry from firing pointlessly.
        guard CGDisplayIsAsleep(CGMainDisplayID()) == 0 else { return }

        if let last = lastRequest, Date().timeIntervalSince(last) < retryInterval { return }
        lastRequest = Date()
        Self.requestDisplaySleep()
    }

    // MARK: - Readers

    /// `AppleClamshellState` on IOPMrootDomain: true while the lid is shut. Absent on
    /// machines with no lid, where nil correctly means "not applicable".
    static func isLidClosed() -> Bool? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPMrootDomain"))
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }

        guard let value = IORegistryEntryCreateCFProperty(
            service,
            "AppleClamshellState" as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() else { return nil }

        if let boolValue = value as? Bool { return boolValue }
        return (value as? NSNumber)?.boolValue
    }

    static func isExternalDisplayConnected() -> Bool? {
        var count: UInt32 = 0
        guard CGGetOnlineDisplayList(0, nil, &count) == .success else { return nil }
        guard count > 0 else { return false }

        var displays = [CGDirectDisplayID](repeating: 0, count: Int(count))
        guard CGGetOnlineDisplayList(count, &displays, &count) == .success else { return nil }
        return displays.prefix(Int(count)).contains { CGDisplayIsBuiltin($0) == 0 }
    }

    private static func requestDisplaySleep() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["displaysleepnow"]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        try? process.run()
    }
}
