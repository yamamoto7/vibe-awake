import SwiftUI

/// Wording for the one-time privileged setup, kept in one place so the popover and the
/// settings window say the same thing. Asking for an admin password is the biggest point of
/// hesitation in this app, so the copy leads with why it is unavoidable, states plainly how
/// small the installed piece is, and makes the exit (uninstall) visible up front.
enum SetupCopy {
    static var title: String { L("setup.title") }
    static var updateTitle: String { L("setup.updateTitle") }
    static var shortReason: String { L("setup.reason") }
    static var updateShortReason: String { L("setup.updateReason") }
    static var passwordNote: String { L("setup.passwordNote") }
    static var buttonTitle: String { L("setup.button") }
    static var updateButtonTitle: String { L("setup.updateButton") }
    static var workingTitle: String { L("setup.working") }

    /// The reassurance list. Each line answers a question someone hesitating would actually
    /// have: how often, what it does, what it touches, and how to undo it.
    static var assurances: [(icon: String, text: String)] {
        [
            ("lock.open", L("setup.assurance.once")),
            ("switch.2", L("setup.assurance.scope")),
            ("wifi.slash", L("setup.assurance.privacy")),
            ("trash", L("setup.assurance.removable")),
        ]
    }

    static let installedPaths = [
        "/Library/LaunchDaemons/com.ychof.vibeawake.helper.plist",
        "/Library/Application Support/VibeAwake/helper.sh",
    ]
}
