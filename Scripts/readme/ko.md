TAGLINE|AI 코딩 세션이 실제로 작업하는 동안에만 Mac을 깨어 있게 유지합니다.
NOTE|첫 실행 시 관리자 암호를 한 번 입력하게 됩니다. macOS에서는 관리자 권한을 가진 프로그램만 덮개를 닫은 상태에서 잠자기를 막을 수 있습니다 → [설정](#설정)
H_WHAT|무엇을 하는 앱인가요
P_WHAT1|Claude Code나 Codex CLI에 오래 걸리는 작업을 맡기고 자리를 비우면, Mac이 잠자기에 들어가 작업이 도중에 멈춥니다. Vibe Awake는 메뉴 막대에 상주하며 **세션이 실제로 응답을 생성하는 동안에만** 잠자기를 막습니다 — **MacBook 덮개를 닫아도 멈추지 않습니다**.
P_WHAT2|`caffeinate`를 계속 켜 두는 방식과 달리, 프롬프트에서 대기 중인 세션은 Mac이 정상적으로 잠자기에 들어가게 둡니다. 돌아올 때까지 배터리를 낭비하지 않습니다.
H_TOOLS|지원 도구
T_SUPPORTED|지원
T_CLAUDE|Claude Code (터미널)
T_CODEX|Codex CLI (터미널)
T_DESKTOP|Claude 데스크탑 앱
T_CURSOR|Cursor
P_HEADLESS|헤드리스 실행(`claude -p`, `codex exec`)은 대상이 아닙니다.
H_INSTALL|설치
P_REQ|**macOS 13 (Ventura) 이상**이 필요합니다.
H_BREW|Homebrew
P_BREW_UPD|업데이트와 제거도 Homebrew로 할 수 있습니다.
C_UNINSTALL|# 헬퍼도 함께 제거됩니다
P_TRUST|Homebrew 6는 서드파티 탭을 불러오기 전에 명시적인 신뢰를 요구하며, `brew trust`가 그 동의를 기록합니다. 건너뛰면 "Refusing to load cask ... from untrusted tap"으로 설치가 중단됩니다.
H_MANUAL|수동 설치
P_MANUAL|[Releases](https://github.com/yamamoto7/vibe-awake/releases)에서 `.dmg`를 내려받아 `Vibe Awake.app`을 `응용 프로그램` 폴더로 끌어다 놓으세요.
H_SETUP|설정
P_SETUP1|첫 실행 시 **관리자 암호를 한 번만** 입력하게 됩니다.
P_SETUP2|macOS에서는 관리자 권한을 가진 프로그램만 덮개를 닫은 상태에서 잠자기를 막을 수 있기 때문입니다. 설치되는 헬퍼는 macOS 기본 전원 설정(`pmset`)을 전환하는 일만 합니다 — 네트워크 통신도, 데이터 수집도 없습니다. 설정에서 언제든지 제거할 수 있습니다.
P_SETUP3|설정을 마치기 전까지 잠자기 방지는 동작하지 않습니다.
H_USING|사용법
P_USING|메뉴 막대 아이콘을 클릭하면 현재 상태를 볼 수 있습니다.
L_WORKING|**작업 중** — 응답을 생성하거나 도구를 실행 중
L_WAITING|**승인 대기 중** — 확인을 기다리는 중
L_IDLE|**대기 중** — 프롬프트에서 입력 대기
P_ICON|아이콘이 채워져 있으면 잠자기를 막고 있다는 뜻입니다. 주황색 경고 아이콘은 설정이 끝나지 않았다는 표시입니다.
H_SETTINGS|설정 항목
S_ENABLE|잠자기 방지
S_ENABLE_D|일시적으로 전체 기능을 끕니다
S_LOGIN|로그인 시 열기
S_LOGIN_D|Mac 시작과 함께 실행합니다
S_DISPLAY|덮개를 닫으면 디스플레이 끄기
S_DISPLAY_D|잠자기를 막는 동안 macOS는 덮개를 닫아도 내장 디스플레이를 켜 둡니다. 디스플레이를 끄면 불필요한 전력 소모를 줄일 수 있습니다. 외장 디스플레이가 연결되어 있으면 적용되지 않습니다
S_APPROVAL|승인 대기도 작업 중으로 간주
S_APPROVAL_D|휴대폰 등에서 원격으로 승인한다면 켜 두세요. 끄면 승인을 기다리는 동안 Mac이 잠자기에 들어갑니다
H_LANGS|지원 언어
P_LANGS|English, 日本語, 简体中文, 한국어, Español, Français, Deutsch, Português (Brasil), Русский. macOS의 언어 설정을 따릅니다.
H_CAVEATS|알아두실 점
P_CAVEAT1|상태 판별은 두 CLI가 문서화하지 않은 내부 상태 파일을 읽는 방식이므로, **해당 도구가 업데이트되면 동작하지 않을 수 있습니다**. 동작하지 않으면 [이슈](https://github.com/yamamoto7/vibe-awake/issues)로 알려 주세요.
P_CAVEAT2|본 소프트웨어는 Anthropic 및 OpenAI와 무관한 비공식 도구입니다. Claude, Claude Code, Codex는 각 소유자의 상표입니다.
H_BUILD|소스에서 빌드하기
P_BUILD_REQ|Swift 5.9 이상이 필요합니다.
C_DEV|# 개발용 빌드
C_APP|# dist/ 에 .app 생성
C_L10N|# 번역 동기화 확인
P_BUILD_DIST|배포용 빌드에는 Developer ID 인증서가 필요합니다.
C_SIGN|# Developer ID 서명 + Hardened Runtime
C_NOTARIZE|# DMG 생성 및 공증
H_TRANS|번역
P_TRANS|각 언어는 `Resources/<lang>.lproj/` 아래의 `Localizable.strings` 파일입니다. 영어가 개발 언어이므로, 다른 언어에서 키가 빠지면 키 이름 대신 영어로 대체됩니다. `Scripts/check_localizations.sh`는 누락·미사용·미정의 키를 보고합니다 — 문자열을 수정한 뒤 실행하세요.
P_SOURCE|판별 로직과 설계 결정의 이유는 각 소스 파일 주석에 적혀 있습니다.
H_LICENSE|라이선스
