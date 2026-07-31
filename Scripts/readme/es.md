TAGLINE|Mantiene tu Mac despierto solo mientras una sesión de programación con IA está trabajando de verdad.
NOTE|Se te pedirá la contraseña de administrador una sola vez al abrirlo por primera vez. macOS solo permite que un asistente con privilegios impida el reposo con la tapa cerrada → [Configuración](#configuración)
H_WHAT|Qué hace
P_WHAT1|Le encargas una tarea larga a Claude Code o Codex CLI, te levantas, y el Mac se duerme dejando el trabajo a medias. Vibe Awake vive en la barra de menús y bloquea el reposo **solo mientras una sesión está generando una respuesta** — **incluso con la tapa del MacBook cerrada**.
P_WHAT2|A diferencia de dejar `caffeinate` en marcha, una sesión parada en el prompt deja que el Mac se duerma con normalidad. Sin gastar batería esperando a que vuelvas.
H_TOOLS|Herramientas compatibles
T_SUPPORTED|Compatible
T_CLAUDE|Claude Code (terminal)
T_CODEX|Codex CLI (terminal)
T_DESKTOP|App de escritorio de Claude
T_CURSOR|Cursor
P_HEADLESS|Las ejecuciones sin interfaz (`claude -p`, `codex exec`) quedan fuera del alcance.
H_INSTALL|Instalación
P_REQ|Requiere **macOS 13 (Ventura) o posterior**.
H_BREW|Homebrew
P_BREW_UPD|Actualizar y desinstalar también se hacen con Homebrew.
C_UNINSTALL|# elimina también el asistente
H_MANUAL|Manualmente
P_MANUAL|Descarga el `.dmg` desde [Releases](https://github.com/yamamoto7/vibe-awake/releases) y arrastra `Vibe Awake.app` a `Aplicaciones`.
H_SETUP|Configuración
P_SETUP1|Al abrirlo por primera vez se te pedirá la **contraseña de administrador, una sola vez**.
P_SETUP2|macOS solo permite que un programa con permisos de administrador impida que el Mac entre en reposo con la tapa cerrada. El asistente que se instala no hace más que cambiar el ajuste de energía integrado (`pmset`): sin acceso a la red y sin recopilar datos. Puedes eliminarlo cuando quieras desde los ajustes.
P_SETUP3|El bloqueo de reposo no hace nada hasta que termines la configuración.
H_USING|Cómo se usa
P_USING|Haz clic en el icono de la barra de menús para ver qué está pasando.
L_WORKING|**Trabajando** — generando una respuesta o ejecutando una herramienta
L_WAITING|**Esperando aprobación** — esperando a que confirmes algo
L_IDLE|**Inactiva** — parada en el prompt
P_ICON|Un icono relleno significa que se está bloqueando el reposo. Un icono naranja de advertencia significa que falta la configuración.
H_SETTINGS|Ajustes
S_ENABLE|Bloquear el reposo
S_ENABLE_D|Desactiva todo temporalmente
S_LOGIN|Abrir al iniciar sesión
S_LOGIN_D|Se inicia junto con el Mac
S_DISPLAY|Apagar la pantalla al cerrar la tapa
S_DISPLAY_D|Mientras se bloquea el reposo, macOS deja encendida la pantalla integrada tras la tapa cerrada. Apagarla ahorra batería. No hace nada si hay una pantalla externa conectada
S_APPROVAL|Contar la espera de aprobación como trabajo
S_APPROVAL_D|Actívalo si apruebas de forma remota, por ejemplo desde el móvil. Con esto desactivado, el Mac se duerme mientras una sesión espera tu aprobación
H_LANGS|Idiomas
P_LANGS|English, 日本語, 简体中文, 한국어, Español, Français, Deutsch, Português (Brasil), Русский. La app sigue el idioma configurado en macOS.
H_CAVEATS|Advertencias
P_CAVEAT1|La detección lee archivos de estado internos que ninguna de las dos CLI documenta, así que **una actualización de esas herramientas puede romperla**. Si deja de funcionar, abre una [incidencia](https://github.com/yamamoto7/vibe-awake/issues).
P_CAVEAT2|Esta es una herramienta no oficial, sin relación con Anthropic ni OpenAI. Claude, Claude Code y Codex son marcas de sus respectivos propietarios.
H_BUILD|Compilar desde el código
P_BUILD_REQ|Requiere Swift 5.9 o posterior.
C_DEV|# compilación de desarrollo
C_APP|# genera el .app en dist/
C_L10N|# comprueba que las traducciones estén al día
P_BUILD_DIST|Las compilaciones de distribución necesitan un certificado Developer ID.
C_SIGN|# firma Developer ID + Hardened Runtime
C_NOTARIZE|# crea el DMG y lo notariza
H_TRANS|Traducciones
P_TRANS|Cada idioma es un archivo `Localizable.strings` dentro de `Resources/<lang>.lproj/`. El inglés es el idioma de desarrollo, así que una clave que falte en otro idioma recurre al inglés en lugar de mostrar la clave en bruto. `Scripts/check_localizations.sh` informa de claves ausentes, sin usar o sin definir: ejecútalo después de tocar cualquier texto.
P_SOURCE|El razonamiento detrás de la lógica de detección y de las decisiones de diseño está en los comentarios del código.
H_LICENSE|Licencia
