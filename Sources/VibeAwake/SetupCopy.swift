import SwiftUI

/// Wording for the one-time privileged setup, kept in one place so the popover and the
/// settings window say the same thing. Asking for an admin password is the biggest point of
/// hesitation in this app, so the copy leads with why it is unavoidable, states plainly how
/// small the installed piece is, and makes the exit (uninstall) visible up front.
enum SetupCopy {
    static let title = "セットアップが必要です"
    static let updateTitle = "アップデートが必要です"

    static let shortReason = """
        蓋を閉じたときのスリープ状態を管理するヘルパーが必要です。まだ入っていないため、現在スリープ防止は動作しません。
        """

    static let updateShortReason = """
        ヘルパーが古いバージョンのため、現在スリープ防止は動作しません。
        """

    static let passwordNote = "macOS の管理者パスワードを一度だけ入力します"

    static let buttonTitle = "セットアップを開始"
    static let updateButtonTitle = "アップデート"
    static let workingTitle = "セットアップ中..."

    /// The reassurance list. Each line answers a question someone hesitating would actually
    /// have: how often, what it does, what it touches, and how to undo it.
    static let assurances: [(icon: String, text: String)] = [
        ("lock.open", "パスワードの入力は初回の1回だけです"),
        ("switch.2", "行うのは pmset(macOS 標準の電源設定コマンド)の切り替えだけです"),
        ("wifi.slash", "通信・情報収集は一切ありません"),
        ("trash", "設定画面からいつでも削除できます"),
    ]

    static let installedPaths = [
        "/Library/LaunchDaemons/com.ychof.vibeawake.helper.plist",
        "/Library/Application Support/VibeAwake/helper.sh",
    ]
}
