TAGLINE|AI コーディングセッションが動いている間だけ、Mac を寝かせない。
NOTE|初回起動時に管理者パスワードを一度だけ求められます。macOS の仕様上、蓋を閉じたときのスリープを止めるのに必要です → [初回セットアップ](#初回セットアップ)
H_WHAT|これは何?
P_WHAT1|Claude Code や Codex CLI に長い作業を任せて席を離れると、Mac がスリープして作業が止まってしまいます。Vibe Awake はメニューバーに常駐して、**セッションが実際に応答を生成している間だけ**スリープを防ぎます。**MacBook の蓋を閉じても止まりません。**
P_WHAT2|`caffeinate` のような常時オンの方式とは違い、プロンプト待ちで放置している間は普通にスリープします。バッテリーを無駄に消費しません。
H_TOOLS|対応ツール
T_SUPPORTED|対応
T_CLAUDE|Claude Code (ターミナル)
T_CODEX|Codex CLI (ターミナル)
T_DESKTOP|Claude デスクトップアプリ
T_CURSOR|Cursor
P_HEADLESS|ヘッドレス実行 (`claude -p` / `codex exec`) は対象外です。
H_INSTALL|インストール
P_REQ|動作環境は **macOS 13 (Ventura) 以降** です。
H_BREW|Homebrew
P_BREW_UPD|アップデートとアンインストールも Homebrew から行えます。
C_UNINSTALL|# ヘルパーもまとめて削除されます
H_MANUAL|手動
P_MANUAL|[Releases](https://github.com/yamamoto7/vibe-awake/releases) から `.dmg` をダウンロードし、`Vibe Awake.app` を `アプリケーション` フォルダにドラッグしてください。
H_SETUP|初回セットアップ
P_SETUP1|初回起動時に **管理者パスワードを一度だけ** 求められます。
P_SETUP2|macOS では、蓋を閉じたときのスリープは管理者権限を持つプログラムからしか止められないためです。インストールされるヘルパーは電源設定 (`pmset`) を切り替えるだけのもので、通信も情報収集も行いません。設定画面からいつでも削除できます。
P_SETUP3|セットアップが完了するまで、スリープ防止は動作しません。
H_USING|使い方
P_USING|メニューバーのアイコンをクリックすると、現在の状態が表示されます。
L_WORKING|**作業中** — 応答生成中・ツール実行中
L_WAITING|**承認待ち** — 権限の確認などで入力を待っている
L_IDLE|**待機中** — プロンプト待ち
P_ICON|アイコンが塗りつぶされている間はスリープを防止しています。オレンジの警告アイコンはセットアップが未完了のサインです。
H_SETTINGS|設定
S_ENABLE|スリープ防止を有効にする
S_ENABLE_D|一時的にオフにできます
S_LOGIN|ログイン時に自動起動
S_LOGIN_D|Mac の起動時に常駐させます
S_DISPLAY|蓋を閉じたら画面を消す
S_DISPLAY_D|スリープを防いでいる間、macOS は蓋を閉じても内蔵ディスプレイを点けたままにします。消灯して電力の無駄を防ぎます。外部ディスプレイ接続時は何もしません
S_APPROVAL|承認待ちもスリープ防止の対象にする
S_APPROVAL_D|スマホなどから遠隔で承認する場合は ON にしてください。OFF にすると承認待ちの間はスリープします
H_LANGS|対応言語
P_LANGS|English / 日本語 / 简体中文 / 한국어 / Español / Français / Deutsch / Português (Brasil) / Русский。macOS の言語設定に従います。
H_CAVEATS|注意事項
P_CAVEAT1|各 CLI が公開していない内部の状態ファイルを読んで判定しているため、**ツール側のアップデートで動作しなくなる可能性があります**。動かなくなった場合は [Issues](https://github.com/yamamoto7/vibe-awake/issues) で知らせてください。
P_CAVEAT2|本ソフトウェアは Anthropic および OpenAI とは無関係の非公式ツールです。Claude、Claude Code、Codex は各社の商標です。
H_BUILD|ソースからビルドする
P_BUILD_REQ|Swift 5.9 以降が必要です。
C_DEV|# 開発用ビルド
C_APP|# .app を生成 (dist/)
C_L10N|# 翻訳の欠落・不整合を検出
P_BUILD_DIST|配布用ビルドには Developer ID 証明書が必要です。
C_SIGN|# Developer ID 署名 + Hardened Runtime
C_NOTARIZE|# DMG 作成 + notarization
H_TRANS|翻訳
P_TRANS|各言語は `Resources/<lang>.lproj/Localizable.strings` です。英語が開発言語なので、他言語でキーが欠けても英語にフォールバックします(キー名がそのまま出ることはありません)。`Scripts/check_localizations.sh` は欠落・未使用・未定義のキーを報告します。文字列を触ったら実行してください。
P_SOURCE|判定ロジックや設計上の判断の理由は、各ソースファイルのコメントに記載しています。
H_LICENSE|ライセンス
