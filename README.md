# Vide Sleep Blocker

Claude Code のセッションが実際に作業している間だけ、Mac がスリープしないようにするメニューバー常駐アプリ。

## 仕組み

### 作業中かどうかの判定

Claude Code は稼働中のセッションごとに `~/.claude/sessions/<PID>.json` を書き出しており、その中の `status` フィールドが状態遷移のたびに更新される。

| status | 意味 | スリープ防止 |
|---|---|---|
| `busy` | 応答生成中 / ツール実行中 / サブエージェント稼働中 | する |
| `shell` | プロンプト待ちだがバックグラウンドシェルが稼働中 | する |
| `waiting` | 権限確認などでユーザーの入力待ち | 設定で切り替え |
| `idle` | プロンプト待ちで何も動いていない | しない |

`ClaudeSessionMonitor` がこのディレクトリを 2 秒ごとに読み、上記の判定を行う。CPU 使用率のような推測を一切使わないので、応答待ちで CPU が 0% に落ちても誤判定しない。

**この方式を選んだ理由**: 当初は Claude Code の hooks (`UserPromptSubmit` / `Stop`) を使う実装だったが、hooks には終了イベントが発火しない穴が複数ある — Ctrl+C による中断、API エラー時 (`Stop` ではなく排他的な `StopFailure` が発火する)、スラッシュコマンド、権限拒否。ステータスファイルは Claude Code 自身が状態遷移として管理しているため、これらすべてで正しく `idle` に戻る。ユーザーの `~/.claude/settings.json` を書き換える必要もない。

**注意点**: このファイル形式は公式にドキュメント化されていない実装詳細なので、読み取りは全面的に防御的に行っている。パースできないファイルはスキップし、`status` が無ければ (古いバージョン) 安全側に倒して「作業中」とみなし、`kill(pid, 0)` で生存を確認して `kill -9` などで残った `busy` のファイルが永久にスリープを止め続けないようにしている。ステータスファイルが 1 つも無いのに `claude` プロセスが動いている場合は、プロセスの生存だけで判定するフォールバックに切り替わる (設定画面に警告が出る)。

### スリープの止め方

- 通常のスリープは `IOPMAssertion` (`kIOPMAssertionTypeNoIdleSleep`) で防止する
- 蓋を閉じた状態でのスリープはクラムシェル由来なのでアサーションでは止められず、`pmset -a disablesleep 1` が必要。これは root 権限が要るため、一度だけ管理者パスワードを入力して LaunchDaemon をインストールし、以降はアプリが状態ファイルを書き換えるだけでヘルパーが `pmset` を切り替える

### 対象は Claude Code のみ

Cursor / Codex CLI にはセッション状態を公開する仕組みが無く、「起動している間ずっと作業中扱い」にしかできないため対象外にしている。旧版 Claude Code 用のフォールバックでのみプロセス検知を使っており、その際は `ps -Ao comm=` の実行ファイル名で完全一致させている (コマンドライン全体の部分一致だと `grep claude ...` のような無関係なコマンドに反応してしまう)。`.app` バンドル内の実行ファイルも除外しているので、Claude デスクトップアプリ (`/Applications/Claude.app/Contents/MacOS/Claude`) が `claude` CLI と誤認されることもない。

## セットアップ

```bash
swift --version   # Swift 5.9+ / macOS 13+ が必要
```

追加の依存パッケージなし(標準の Swift Package Manager のみ)。

## ビルド & 実行

```bash
# デバッグビルド + 実行(開発中の動作確認用、メニューバーに常駐する)
swift build
.build/debug/SleepBlocker

# リリースビルド + .app バンドル化(配布・常用はこちら)
./Scripts/build_app.sh
open "dist/Vide Sleep Blocker.app"
```

`Scripts/build_app.sh` は `swift build -c release` を実行し、`dist/Vide Sleep Blocker.app` を組み立てて ad-hoc 署名するところまで行う。

常用する場合は `dist/Vide Sleep Blocker.app` を `/Applications` に移動してから使うと、ログイン項目登録(設定 > 一般 > ログイン時に自動起動)が安定する。

## コード変更後の反映手順

```bash
swift build                      # まずコンパイルを通す
pkill -f "Vide Sleep Blocker.app/Contents/MacOS/SleepBlocker"
./Scripts/build_app.sh
open "dist/Vide Sleep Blocker.app"
```

## 動作確認の仕方

`ClaudeSessionMonitor` は `CLAUDE_CONFIG_DIR` を尊重するので、本物の `~/.claude` に触れずにテスト用のセッションファイルで挙動を確認できる。

```bash
FIX=/tmp/sb-fixture; mkdir -p "$FIX/sessions"
cat > "$FIX/sessions/1.json" <<EOF
{"pid":$$,"sessionId":"s1","cwd":"/tmp/demo","name":"demo","kind":"interactive","status":"busy","peerProtocol":1}
EOF
CLAUDE_CONFIG_DIR="$FIX" .build/debug/SleepBlocker &

# アサーションが取られているか確認(status を idle に書き換えると数秒で解除される)
pmset -g assertions | grep -i vide
```

## ディレクトリ構成

```
Sources/SleepBlocker/
  main.swift                  # エントリーポイント(メニューバーアプリとして起動)
  AppDelegate.swift           # ステータスバーアイコン、ポップオーバー/設定ウィンドウの制御
  ClaudeSessionMonitor.swift  # ~/.claude/sessions/*.json を読んでセッション状態を取得(中核)
  SleepController.swift       # IOPMAssertion によるスリープ防止 + ヘルパーへの状態通知
  HelperInstaller.swift       # 特権ヘルパー(LaunchDaemon)のインストール/アンインストール
  LaunchAtLogin.swift         # SMAppService によるログイン項目登録
  AppState.swift              # 上記を束ねる ObservableObject(判定ロジックと各種設定)
  DashboardView.swift         # メニューバークリックで出るポップオーバー(集計表示)
  SettingsView.swift          # 設定ウィンドウ
Scripts/build_app.sh          # リリースビルド + .app バンドル生成
```

## 検知パターンの調整

`ProcessMonitor.swift` の `tools` 配列の `cliNames` を編集する。実行ファイル名の完全一致(大文字小文字は無視)。

## ヘルパーの手動削除

アンインストールボタンを使わずに手動で消したい場合:

```bash
sudo launchctl bootout system/dev.vide.sleepblocker.helper
sudo rm /Library/LaunchDaemons/dev.vide.sleepblocker.helper.plist
sudo rm -rf "/Library/Application Support/SleepBlocker"
sudo pmset -a disablesleep 0
```
