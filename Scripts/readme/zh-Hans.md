TAGLINE|仅在 AI 编程会话真正工作时，让 Mac 保持不休眠。
NOTE|首次启动时会要求输入一次管理员密码。macOS 只允许具有管理员权限的程序阻止合盖时的休眠 → [初始设置](#初始设置)
H_WHAT|这是什么
P_WHAT1|把长时间的任务交给 Claude Code 或 Codex CLI，一转身 Mac 就休眠了，活儿只干了一半。Vibe Awake 常驻菜单栏，**仅在会话正在生成回复时**阻止休眠——**合上 MacBook 盖子也不会停**。
P_WHAT2|与一直开着 `caffeinate` 不同，停在提示符前等待输入的会话会让 Mac 正常休眠，不会白白耗电。
H_TOOLS|支持的工具
T_SUPPORTED|支持
T_CLAUDE|Claude Code（终端）
T_CODEX|Codex CLI（终端）
T_DESKTOP|Claude 桌面应用
T_CURSOR|Cursor
P_HEADLESS|无界面运行（`claude -p`、`codex exec`）不在支持范围内。
H_INSTALL|安装
P_REQ|需要 **macOS 13 (Ventura) 或更高版本**。
H_BREW|Homebrew
P_BREW_UPD|更新和卸载同样通过 Homebrew 完成。
C_UNINSTALL|# 同时移除辅助程序
H_MANUAL|手动安装
P_MANUAL|从 [Releases](https://github.com/yamamoto7/vibe-awake/releases) 下载 `.dmg`，将 `Vibe Awake.app` 拖入`应用程序`文件夹。
H_SETUP|初始设置
P_SETUP1|首次启动时会要求输入**一次管理员密码**。
P_SETUP2|因为 macOS 只允许具有管理员权限的程序阻止合盖时的休眠。安装的辅助程序只会切换系统内置的电源设置（`pmset`）——不联网，不收集任何数据。你可以随时在设置中移除它。
P_SETUP3|在完成设置之前，阻止休眠不会生效。
H_USING|使用方法
P_USING|点击菜单栏图标即可查看当前状态。
L_WORKING|**工作中** — 正在生成回复或执行工具
L_WAITING|**等待批准** — 正在等待你的确认
L_IDLE|**空闲** — 停在提示符前
P_ICON|图标为实心时表示正在阻止休眠。橙色警告图标表示尚未完成设置。
H_SETTINGS|设置
S_ENABLE|阻止休眠
S_ENABLE_D|临时关闭整个功能
S_LOGIN|登录时启动
S_LOGIN_D|随 Mac 一同启动
S_DISPLAY|合盖时关闭屏幕
S_DISPLAY_D|在阻止休眠期间，即使合上盖子 macOS 仍会保持内置屏幕点亮。关闭它可以省电。连接外接显示器时不执行任何操作
S_APPROVAL|将等待批准视为工作中
S_APPROVAL_D|如果你通过手机等设备远程批准，请开启此项。关闭时，会话等待批准期间 Mac 会正常休眠
H_LANGS|语言
P_LANGS|English、日本語、简体中文、한국어、Español、Français、Deutsch、Português (Brasil)、Русский。应用会跟随 macOS 的语言设置。
H_CAVEATS|注意事项
P_CAVEAT1|状态检测读取的是两个 CLI 均未公开的内部状态文件，因此**这些工具更新后可能导致本应用失效**。若不再工作，请提交 [issue](https://github.com/yamamoto7/vibe-awake/issues)。
P_CAVEAT2|本软件为非官方工具，与 Anthropic 及 OpenAI 无关。Claude、Claude Code、Codex 为各自所有者的商标。
H_BUILD|从源码构建
P_BUILD_REQ|需要 Swift 5.9 或更高版本。
C_DEV|# 开发构建
C_APP|# 在 dist/ 中生成 .app
C_L10N|# 检查翻译是否同步
P_BUILD_DIST|分发构建需要 Developer ID 证书。
C_SIGN|# Developer ID 签名 + Hardened Runtime
C_NOTARIZE|# 构建 DMG 并公证
H_TRANS|翻译
P_TRANS|每种语言对应 `Resources/<lang>.lproj/` 下的一个 `Localizable.strings` 文件。英语是开发语言，因此其他语言缺失的键会回退到英语，而不会显示原始键名。`Scripts/check_localizations.sh` 会报告缺失、未使用和未定义的键——修改任何字符串后请运行它。
P_SOURCE|状态判定逻辑与设计决策的理由记录在各源文件的注释中。
H_LICENSE|许可证
