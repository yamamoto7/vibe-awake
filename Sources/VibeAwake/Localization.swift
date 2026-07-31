import Foundation

/// Looks up a UI string for the user's language.
///
/// The `.lproj` bundles are copied into the app's Resources by Scripts/build_app.sh, so
/// `Bundle.main` finds them. SwiftUI's `Text("key")` would do its own lookup against the main
/// bundle too, but going through one function keeps every call site explicit about which
/// strings are user-facing -- and makes the extraction script that checks for missing
/// translations a simple grep.
///
/// English is the development language: a key with no translation falls back to en.lproj
/// rather than showing the key itself.
func L(_ key: String) -> String {
    NSLocalizedString(key, bundle: .main, comment: "")
}

/// Same, with positional arguments. Translations may reorder them with `%1$@`, `%2$@`.
func L(_ key: String, _ args: CVarArg...) -> String {
    String(format: NSLocalizedString(key, bundle: .main, comment: ""), arguments: args)
}
