import Cocoa
import SwiftUI
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var eventMonitor: Any?
    private var settingsWindow: NSWindow?

    private let claudeMonitor = ClaudeSessionMonitor()
    private let codexMonitor = CodexSessionMonitor()
    private let sleepController = SleepController()
    private lazy var displaySleepController = DisplaySleepController { [weak self] in
        guard let self else { return false }
        return self.appState.sleepDisplayOnLidClose && self.appState.isBlockingSleep
    }
    private lazy var appState = AppState(
        claudeMonitor: claudeMonitor,
        codexMonitor: codexMonitor,
        sleepController: sleepController
    )
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        let hosting = NSHostingController(
            rootView: DashboardView(
                appState: appState,
                onOpenSettings: { [weak self] in self?.openSettings() }
            )
        )
        // Without this the hosting controller reports no size until SwiftUI lays out, so the
        // popover opens at NSPopover's default 320x320, pins its bottom edge, and then leaves
        // its top edge stranded far below the menu bar when the content shrinks to its real
        // height. Tracking preferredContentSize also keeps the anchor correct when the
        // helper warning appears or disappears and the content grows/shrinks.
        hosting.sizingOptions = [.preferredContentSize]

        popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = hosting

        // The lid-close helper is what this app is for, so a missing one tints the menu bar
        // icon rather than hiding behind a popover the user may never open.
        appState.$isBlockingSleep
            .combineLatest(appState.$helperInstalled)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isBlocking, helperInstalled in
                self?.updateIcon(isBlocking: isBlocking, helperInstalled: helperInstalled)
            }
            .store(in: &cancellables)

        claudeMonitor.start()
        codexMonitor.start()
        displaySleepController.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        claudeMonitor.stop()
        codexMonitor.stop()
        displaySleepController.stop()
        appState.shutdown()
    }

    private func updateIcon(isBlocking: Bool, helperInstalled: Bool) {
        guard let button = statusItem.button else { return }
        // Without the helper the app blocks nothing at all, so the icon says so outright
        // rather than showing a moon that suggests it is on duty.
        let symbol = helperInstalled
            ? (isBlocking ? "moon.zzz.fill" : "moon.zzz")
            : "exclamationmark.triangle.fill"
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: "Sleep Blocker")
        button.contentTintColor = helperInstalled ? nil : .systemOrange
    }

    private func openSettings() {
        popover.performClose(nil)
        removeEventMonitor()

        if settingsWindow == nil {
            let hosting = NSHostingController(
                rootView: SettingsView(appState: appState)
            )
            let window = NSWindow(contentViewController: hosting)
            window.title = "設定"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }

        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(sender)
            removeEventMonitor()
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            addEventMonitor()
        }
    }

    private func addEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.popover.performClose(nil)
            self?.removeEventMonitor()
        }
    }

    private func removeEventMonitor() {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
        eventMonitor = nil
    }
}
