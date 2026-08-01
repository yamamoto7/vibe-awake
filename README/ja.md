<div align="center">
  <img src="../Resources/logo.png" width="128" alt="Vibe Awake">
  <h1>Vibe Awake</h1>
  <p>AI コーディングセッションが動いている間だけ、Mac を寝かせない。</p>
  <p><a href="../README.md">English</a> · 日本語 · <a href="zh-Hans.md">简体中文</a> · <a href="ko.md">한국어</a> · <a href="es.md">Español</a> · <a href="fr.md">Français</a> · <a href="de.md">Deutsch</a> · <a href="pt-BR.md">Português</a> · <a href="ru.md">Русский</a></p>
</div>

```bash
brew tap yamamoto7/tap
brew trust yamamoto7/tap
brew install --cask vibe-awake
```

> [!NOTE]
> 初回起動時に管理者パスワードを一度だけ求められます。macOS の仕様上、蓋を閉じたときのスリープを止めるのに必要です → [初回セットアップ](#初回セットアップ)

## これは何?

Claude Code や Codex CLI に長い作業を任せて席を離れると、Mac がスリープして作業が止まってしまいます。Vibe Awake はメニューバーに常駐して、**セッションが実際に応答を生成している間だけ**スリープを防ぎます。**MacBook の蓋を閉じても止まりません。**

`caffeinate` のような常時オンの方式とは違い、プロンプト待ちで放置している間は普通にスリープします。バッテリーを無駄に消費しません。

## 対応ツール

| | 対応 |
|---|:---:|
| Claude Code (ターミナル) | ✅ |
| Codex CLI (ターミナル) | ✅ |
| Claude デスクトップアプリ | ― |
| Cursor | ― |

ヘッドレス実行 (`claude -p` / `codex exec`) は対象外です。

## インストール

動作環境は **macOS 13 (Ventura) 以降** です。

### Homebrew

```bash
brew tap yamamoto7/tap
brew trust yamamoto7/tap
brew install --cask vibe-awake
```

Homebrew 6 では、サードパーティのタップを読み込む前に明示的な信頼が必要です。`brew trust` はその同意を記録します。省くと「Refusing to load cask ... from untrusted tap」でインストールが止まります。

アップデートとアンインストールも Homebrew から行えます。

```bash
brew upgrade --cask vibe-awake
brew uninstall --cask vibe-awake   # ヘルパーもまとめて削除されます
```

### 手動

[Releases](https://github.com/yamamoto7/vibe-awake/releases) から `.dmg` をダウンロードし、`Vibe Awake.app` を `アプリケーション` フォルダにドラッグしてください。

## 初回セットアップ

初回起動時に **管理者パスワードを一度だけ** 求められます。

macOS では、蓋を閉じたときのスリープは管理者権限を持つプログラムからしか止められないためです。インストールされるヘルパーは電源設定 (`pmset`) を切り替えるだけのもので、通信も情報収集も行いません。設定画面からいつでも削除できます。

セットアップが完了するまで、スリープ防止は動作しません。

## 使い方

メニューバーのアイコンをクリックすると、現在の状態が表示されます。

- **作業中** — 応答生成中・ツール実行中
- **承認待ち** — 権限の確認などで入力を待っている
- **待機中** — プロンプト待ち

アイコンが塗りつぶされている間はスリープを防止しています。オレンジの警告アイコンはセットアップが未完了のサインです。

## 設定

| | |
|---|---|
| スリープ防止を有効にする | 一時的にオフにできます |
| ログイン時に自動起動 | Mac の起動時に常駐させます |
| 蓋を閉じたらディスプレイをオフにする | スリープを防いでいる間、macOS は蓋を閉じても内蔵ディスプレイをオンのままにします。オフにすることで無駄な電力の消費を防げます。外部ディスプレイ接続時は何もしません |
| 承認待ちもスリープ防止の対象にする | スマホなどから遠隔で承認する場合はオンにしてください。オフにすると承認待ちの間はスリープします |

## 対応言語

English / 日本語 / 简体中文 / 한국어 / Español / Français / Deutsch / Português (Brasil) / Русский。macOS の言語設定に従います。

## 注意事項

各 CLI が公開していない内部の状態ファイルを読んで判定しているため、**ツール側のアップデートで動作しなくなる可能性があります**。動かなくなった場合は [Issues](https://github.com/yamamoto7/vibe-awake/issues) で知らせてください。

本ソフトウェアは Anthropic および OpenAI とは無関係の非公式ツールです。Claude、Claude Code、Codex は各社の商標です。

## ソースからビルドする

Swift 5.9 以降が必要です。

```bash
swift build                          # 開発用ビルド
./Scripts/build_app.sh               # .app を生成 (dist/)
./Scripts/check_localizations.sh     # 翻訳の欠落・不整合を検出
```

配布用ビルドには Developer ID 証明書が必要です。

```bash
./Scripts/build_app.sh --release     # Developer ID 署名 + Hardened Runtime
./Scripts/notarize.sh                # DMG 作成 + notarization
```

### 翻訳

各言語は `Resources/<lang>.lproj/Localizable.strings` です。英語が開発言語なので、他言語でキーが欠けても英語にフォールバックします(キー名がそのまま出ることはありません)。`Scripts/check_localizations.sh` は欠落・未使用・未定義のキーを報告します。文字列を触ったら実行してください。

判定ロジックや設計上の判断の理由は、各ソースファイルのコメントに記載しています。

## ライセンス

[MIT](../LICENSE)
