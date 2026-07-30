# Vibe Awake

Claude Code / Codex CLI のセッションが実際に作業している間だけ、Mac がスリープしないようにするメニューバー常駐アプリ。

「起動しているか」ではなく「**今まさに応答を生成しているか**」で判定するので、プロンプト待ちで放置している間はスリープする。CPU 使用率のような推測は一切使っていない。

## 仕組み

### Claude Code: 作業中かどうかの判定

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

### Codex CLI: 作業中かどうかの判定

Codex には Claude Code のようなステータスファイルが**存在しない**。SQLite (`~/.codex/state_5.sqlite`) の `threads` テーブルには `rollout_path` や更新時刻はあるが、`pid` も `status` も無い。

代わりに使うのが **rollout トランスクリプト** (`~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl`)。ターンの開始と終了が `event_msg` として記録される:

| payload.type | 意味 |
|---|---|
| `task_started` | ターン開始 |
| `task_complete` | ターン正常終了 |
| `turn_aborted` | ユーザーによる中断 |

末尾から最後の境界イベントを探し、`task_started` なら作業中と判定する。`task_started` はターン終了の数秒前(実測で約 9 秒前)には書かれているので、進行中にリアルタイムで判定できる。

**hooks を使わない理由**: Codex にも `~/.codex/hooks.json` によるフックはあるが、`Stop` は Ctrl+C 中断で発火しない ([openai/codex#22858](https://github.com/openai/codex/issues/22858)、未修正) のに対し、トランスクリプトには `turn_aborted` が残る。ユーザーの設定ファイルを書き換えなくて済む点も Claude Code と同じ方針。

**対話セッションの絞り込み**: `session_meta` の `originator` が `codex-tui` のものだけを対象にする。`codex exec` によるヘッドレス実行は `codex_exec` になるので除外される。

**どれが生きているセッションかの判定**: トランスクリプト自体には書き手を示す情報が無い。そこで `lsof -Fpn -p <codex の PID 群>` で各プロセスが開いている rollout ファイルを取得し、**実際に開かれているものだけ**を対象にする。ディレクトリを更新時刻で走査する方式だと、数時間前に終了したセッションの記録まで「セッション」として数えてしまう (実際にそのバグが出た)。

`lsof` が使えず rollout を特定できなかった場合は、状態不明のセッション 1 件として扱う (= 作業中扱い)。スリープしてしまうより余計に起きている方が安全なため。

**承認待ちは区別できない**: 承認要求は app-server のプロトコル層のやり取りで、トランスクリプトには記録されない。承認待ちの間もターンは開いたまま (`task_started` のまま) なので「作業中」として扱われる。トランスクリプト末尾の「`function_call` に対応する `function_call_output` が無い」状態は検出できるが、これは承認待ちとツールの実行中を区別できないため使っていない。

### スリープの止め方

- 通常のスリープは `IOPMAssertion` (`kIOPMAssertionTypeNoIdleSleep`) で防止する
- 蓋を閉じた状態でのスリープはクラムシェル由来なのでアサーションでは止められず、`pmset -a disablesleep 1` が必要。これは root 権限が要るため、一度だけ管理者パスワードを入力して LaunchDaemon をインストールし、以降はアプリが状態ファイルを書き換えるだけでヘルパーが `pmset` を切り替える
- **ヘルパーが入っていない間は、アプリは一切スリープを防止しない**。アサーションだけを張ると「蓋を閉じなければ動く」という中途半端な状態になり、動作しているように見えて肝心の蓋クローズで寝てしまうため

### 取り残しの防止 (重要)

状態ファイルはフラグだけでなく **アプリの PID と更新時刻** を持つ:

```
desired=1
pid=40781
ts=1785240000
```

ヘルパーは `desired=1` かつ **PID が生存** かつ **タイムスタンプが 120 秒以内** のときだけ `disablesleep 1` を適用する。アプリ側は防止中だけ 30 秒ごとにタイムスタンプを更新する。

これは実際に起きた不具合への対処である。以前はフラグだけを書いていたため、アプリを強制終了 (SIGKILL・クラッシュ・アクティビティモニタから終了) すると `1` が書かれたまま残り、`pmset disablesleep` が有効なまま取り残されていた。さらに plist の `RunAtLoad` により再起動のたびに再適用されるので、アプリを起動し直すまで Mac は蓋を閉じても二度とスリープしない状態になっていた。現在は plist に `StartInterval` (60 秒) も設定してあるので、ファイル変更が起きなくても最大 1 分で自動復旧する。

状態ファイルは root で動くスクリプトに読まれるため、以前の world-writable (666) をやめてユーザー所有の 644 にし、値は `source` せず awk で 1 フィールドずつ読んで数字以外を除去してから使っている (コマンドインジェクション対策)。

インストール内容を変更したときは `HelperInstaller.helperVersion` を上げる。バージョンが一致しないヘルパーは「未インストール」と同じ扱いになり、UI が再セットアップを促す。

### 対象範囲

対象は **ターミナルで対話的に起動した CLI のみ**:

| | 対象 | 備考 |
|---|---|---|
| `claude` (CLI, 対話) | ○ | |
| `codex` (CLI, 対話) | ○ | |
| `claude -p` / `codex exec` (ヘッドレス) | × | 前者はステータスファイルを作らず、後者は `originator` で除外 |
| Claude デスクトップアプリ | × | セッションファイルを書かないため検知対象外 |
| Cursor | × | セッション状態を公開する仕組みが無く、「起動中は常に作業中」にしかできないため |

プロセス検知は `ps -Ao comm=` の実行ファイル名で完全一致させている (コマンドライン全体の部分一致だと `grep claude ...` のような無関係なコマンドに反応してしまう)。`.app` バンドル内の実行ファイルも除外しているので、Claude デスクトップアプリ (`/Applications/Claude.app/Contents/MacOS/Claude`) が `claude` CLI と誤認されることもない。

## セットアップ

```bash
swift --version   # Swift 5.9+ / macOS 13+ が必要
```

追加の依存パッケージなし(標準の Swift Package Manager のみ)。

## ビルド & 実行

```bash
# デバッグビルド + 実行(開発中の動作確認用、メニューバーに常駐する)
swift build
.build/debug/VibeAwake

# リリースビルド + .app バンドル化(配布・常用はこちら)
./Scripts/build_app.sh
open "dist/Vibe Awake.app"
```

`Scripts/build_app.sh` は `swift build -c release` を実行し、`dist/Vibe Awake.app` を組み立てて ad-hoc 署名するところまで行う。

常用する場合は `dist/Vibe Awake.app` を `/Applications` に移動してから使うと、ログイン項目登録(設定 > 一般 > ログイン時に自動起動)が安定する。

## コード変更後の反映手順

```bash
swift build                      # まずコンパイルを通す
pkill -f "Vibe Awake.app/Contents/MacOS/VibeAwake"
./Scripts/build_app.sh
open "dist/Vibe Awake.app"
```

## 動作確認の仕方

`ClaudeSessionMonitor` は `CLAUDE_CONFIG_DIR` を尊重するので、本物の `~/.claude` に触れずにテスト用のセッションファイルで挙動を確認できる。

```bash
FIX=/tmp/sb-fixture; mkdir -p "$FIX/sessions"
cat > "$FIX/sessions/1.json" <<EOF
{"pid":$$,"sessionId":"s1","cwd":"/tmp/demo","name":"demo","kind":"interactive","status":"busy","peerProtocol":1}
EOF
CLAUDE_CONFIG_DIR="$FIX" .build/debug/VibeAwake &

# アサーションが取られているか確認(status を idle に書き換えると数秒で解除される)
pmset -g assertions | grep -i vide
```

## ディレクトリ構成

```
Sources/VibeAwake/
  main.swift                  # エントリーポイント(メニューバーアプリとして起動)
  AppDelegate.swift           # ステータスバーアイコン、ポップオーバー/設定ウィンドウの制御
  AgentSession.swift          # ツール共通のセッションモデル(作業中/承認待ち/待機中)
  ClaudeSessionMonitor.swift  # ~/.claude/sessions/*.json を読む
  CodexSessionMonitor.swift   # ~/.codex/sessions/**/rollout-*.jsonl の末尾を読む
  ProcessProbe.swift          # 実行ファイル名によるプロセス検知 + PID 生存確認
  SleepController.swift       # IOPMAssertion によるスリープ防止 + ヘルパーへの状態通知
  HelperInstaller.swift       # 特権ヘルパー(LaunchDaemon)のインストール/アンインストール
  SetupCopy.swift             # 初回セットアップの文言(ポップオーバーと設定画面で共有)
  LaunchAtLogin.swift         # SMAppService によるログイン項目登録
  AppState.swift              # 上記を束ねる ObservableObject(判定ロジックと各種設定)
  DashboardView.swift         # メニューバークリックで出るポップオーバー(集計表示)
  SettingsView.swift          # 設定ウィンドウ
Scripts/build_app.sh          # リリースビルド + .app バンドル生成
```

## 動作確認 (Codex)

`lsof` で実プロセスが開いているファイルを見るため、`CODEX_HOME` を差し替えたフィクスチャでは検証できない。実際に `codex` を起動して確認する。

```bash
# アプリが認識しているセッションを確認
PIDS=$(ps -Ao pid,comm= | awk '{n=$2;sub(/.*\//,"",n)} n=="codex"{printf "%s%s",(c++?",":""),$1}')
lsof -Fpn -p "$PIDS" | awk '/^p/{p=substr($0,2)} /^n.*rollout-.*jsonl/{print p, substr($0,2)}'

# そのファイルの末尾のターン境界を見る (task_started なら作業中)
```

## ヘルパーの手動削除

アンインストールボタンを使わずに手動で消したい場合:

```bash
sudo launchctl bootout system/com.ychof.vibeawake.helper
sudo rm /Library/LaunchDaemons/com.ychof.vibeawake.helper.plist
sudo rm -rf "/Library/Application Support/VibeAwake"
sudo pmset -a disablesleep 0
```

## ライセンス

[MIT License](LICENSE)
