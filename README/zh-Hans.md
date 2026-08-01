<div align="center">
  <img src="../Resources/logo.png" width="128" alt="Vibe Awake">
  <h1>Vibe Awake</h1>
  <p>仅在 AI 编程会话真正工作时阻止 Mac 进入睡眠。</p>
  <p><a href="../README.md">English</a> · <a href="ja.md">日本語</a> · 简体中文 · <a href="ko.md">한국어</a> · <a href="es.md">Español</a> · <a href="fr.md">Français</a> · <a href="de.md">Deutsch</a> · <a href="pt-BR.md">Português</a> · <a href="ru.md">Русский</a></p>
</div>

```bash
brew tap yamamoto7/tap
brew trust yamamoto7/tap
brew install --cask vibe-awake
```

> [!NOTE]
> 首次启动时会要求输入一次管理员密码。macOS 只允许具有管理员权限的程序阻止合盖时进入睡眠 → [初始设置](#初始设置)

## 这是什么

把长时间的任务交给 Claude Code 或 Codex CLI，转身离开一会儿，Mac 就进入了睡眠，任务才做到一半。Vibe Awake 常驻菜单栏，**仅在会话正在生成回复时**阻止睡眠——**合上 MacBook 盖子时同样有效**。

与一直开着 `caffeinate` 不同，停在提示符前等待输入时，Mac 会照常进入睡眠，不会白白耗电。

## 支持的工具

| | 支持 |
|---|:---:|
| Claude Code（终端） | ✅ |
| Codex CLI（终端） | ✅ |
| Claude 桌面应用 | ― |
| Cursor | ― |

无界面运行（`claude -p`、`codex exec`）不在支持范围内。

## 安装

需要 **macOS 13 (Ventura) 或更高版本**。

### Homebrew

```bash
brew tap yamamoto7/tap
brew trust yamamoto7/tap
brew install --cask vibe-awake
```

Homebrew 6 要求第三方 tap 必须先被显式信任才会加载，`brew trust` 就是记录这一授权。省略这一步会导致安装中断并提示「Refusing to load cask ... from untrusted tap」。

更新和卸载同样通过 Homebrew 完成。

```bash
brew upgrade --cask vibe-awake
brew uninstall --cask vibe-awake   # 同时移除辅助程序
```

### 手动安装

从 [Releases](https://github.com/yamamoto7/vibe-awake/releases) 下载 `.dmg`，将 `Vibe Awake.app` 拖入`应用程序`文件夹。

## 初始设置

首次启动时会要求输入**一次管理员密码**。

这是因为 macOS 只允许具有管理员权限的程序阻止合盖时进入睡眠。安装的辅助程序只会切换系统内置的电源设置（`pmset`）——不联网，不收集任何数据。你可以随时在设置中移除它。

在完成设置之前，阻止睡眠不会生效。

## 使用方法

点击菜单栏图标即可查看当前状态。

- **工作中** — 正在生成回复或执行工具
- **等待批准** — 正在等待你的确认
- **空闲** — 停在提示符前

图标为实心时表示正在阻止睡眠。橙色警告图标表示尚未完成设置。

## 设置

| | |
|---|---|
| 阻止睡眠 | 临时关闭整个功能 |
| 登录时打开 | 随 Mac 一同启动 |
| 合盖时关闭显示器 | 在阻止睡眠期间，即使合上盖子，macOS 仍会保持内建显示器点亮。将其关闭可以省电。连接外接显示器时不执行任何操作 |
| 将等待批准视为工作中 | 如果你通过手机等设备远程批准，请开启此项。关闭时，会话等待批准期间 Mac 会正常进入睡眠 |

## 语言

English、日本語、简体中文、한국어、Español、Français、Deutsch、Português (Brasil)、Русский。应用会跟随 macOS 的语言设置。

## 注意事项

状态检测读取的是两个 CLI 均未公开的内部状态文件，因此**这些工具更新后可能导致本应用失效**。若发现失效，请提交 [issue](https://github.com/yamamoto7/vibe-awake/issues)。

本软件为非官方工具，与 Anthropic 及 OpenAI 无关。Claude、Claude Code、Codex 为各自所有者的商标。

## 从源码构建

需要 Swift 5.9 或更高版本。

```bash
swift build                          # 开发构建
./Scripts/build_app.sh               # 在 dist/ 中生成 .app
./Scripts/check_localizations.sh     # 检查翻译是否同步
```

分发构建需要 Developer ID 证书。

```bash
./Scripts/build_app.sh --release     # Developer ID 签名 + Hardened Runtime
./Scripts/notarize.sh                # 构建 DMG 并公证
```

### 翻译

每种语言对应 `Resources/<lang>.lproj/` 下的一个 `Localizable.strings` 文件。英语是开发语言，因此其他语言缺失的键会回退到英语，而不会显示原始键名。`Scripts/check_localizations.sh` 会报告缺失、未使用和未定义的键——修改任何字符串后请运行它。

状态判定逻辑与设计决策的理由记录在各源文件的注释中。

## 许可证

[MIT](../LICENSE)
