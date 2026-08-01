<div align="center">
  <img src="../Resources/logo.png" width="128" alt="Vibe Awake">
  <h1>Vibe Awake</h1>
  <p>Mantiene tu Mac despierto solo mientras una sesión de programación con IA está trabajando de verdad.</p>
  <p><a href="../README.md">English</a> · <a href="ja.md">日本語</a> · <a href="zh-Hans.md">简体中文</a> · <a href="ko.md">한국어</a> · Español · <a href="fr.md">Français</a> · <a href="de.md">Deutsch</a> · <a href="pt-BR.md">Português</a> · <a href="ru.md">Русский</a></p>
</div>

```bash
brew tap yamamoto7/tap
brew trust yamamoto7/tap
brew install --cask vibe-awake
```

> [!NOTE]
> Se te pedirá la contraseña de administrador una sola vez al abrirlo por primera vez. macOS solo permite que un asistente con privilegios impida el reposo con la tapa cerrada → [Configuración](#configuración)

## Qué hace

Le encargas una tarea larga a Claude Code o Codex CLI, te levantas, y el Mac se duerme dejando el trabajo a medias. Vibe Awake vive en la barra de menús y bloquea el reposo **solo mientras una sesión está generando una respuesta** — **incluso con la tapa del MacBook cerrada**.

A diferencia de dejar `caffeinate` en marcha, una sesión parada en el prompt deja que el Mac se duerma con normalidad. Sin gastar batería esperando a que vuelvas.

## Herramientas compatibles

| | Compatible |
|---|:---:|
| Claude Code (terminal) | ✅ |
| Codex CLI (terminal) | ✅ |
| App de escritorio de Claude | ― |
| Cursor | ― |

Las ejecuciones sin interfaz (`claude -p`, `codex exec`) quedan fuera del alcance.

## Instalación

Requiere **macOS 13 (Ventura) o posterior**.

### Homebrew

```bash
brew tap yamamoto7/tap
brew trust yamamoto7/tap
brew install --cask vibe-awake
```

Homebrew 6 exige que los taps de terceros se marquen como de confianza antes de cargarlos; `brew trust` deja constancia de ese consentimiento. Si lo omites, la instalación se detiene con «Refusing to load cask ... from untrusted tap».

Actualizar y desinstalar también se hacen con Homebrew.

```bash
brew upgrade --cask vibe-awake
brew uninstall --cask vibe-awake   # elimina también el asistente
```

### Manualmente

Descarga el `.dmg` desde [Releases](https://github.com/yamamoto7/vibe-awake/releases) y arrastra `Vibe Awake.app` a `Aplicaciones`.

## Configuración

Al abrirlo por primera vez se te pedirá la **contraseña de administrador, una sola vez**.

macOS solo permite que un programa con permisos de administrador impida que el Mac entre en reposo con la tapa cerrada. El asistente que se instala no hace más que cambiar el ajuste de energía integrado (`pmset`): sin acceso a la red y sin recopilar datos. Puedes eliminarlo cuando quieras desde los ajustes.

El bloqueo de reposo no hace nada hasta que termines la configuración.

## Cómo se usa

Haz clic en el icono de la barra de menús para ver qué está pasando.

- **Trabajando** — generando una respuesta o ejecutando una herramienta
- **Esperando aprobación** — esperando a que confirmes algo
- **Inactiva** — parada en el prompt

Un icono relleno significa que se está bloqueando el reposo. Un icono naranja de advertencia significa que falta la configuración.

## Ajustes

| | |
|---|---|
| Bloquear el reposo | Desactiva todo temporalmente |
| Abrir al iniciar sesión | Se inicia junto con el Mac |
| Apagar la pantalla al cerrar la tapa | Mientras se bloquea el reposo, macOS deja encendida la pantalla integrada aunque la tapa esté cerrada. Apagarla ahorra energía. No hace nada si hay una pantalla externa conectada |
| Contar la espera de aprobación como trabajo | Actívalo si apruebas de forma remota, por ejemplo desde el móvil. Con esto desactivado, el Mac se duerme mientras una sesión espera tu aprobación |

## Idiomas

English, 日本語, 简体中文, 한국어, Español, Français, Deutsch, Português (Brasil), Русский. La app sigue el idioma configurado en macOS.

## Advertencias

La detección lee archivos de estado internos que ninguna de las dos CLI documenta, así que **una actualización de esas herramientas puede romperla**. Si deja de funcionar, abre una [incidencia](https://github.com/yamamoto7/vibe-awake/issues).

Esta es una herramienta no oficial, sin relación con Anthropic ni OpenAI. Claude, Claude Code y Codex son marcas de sus respectivos propietarios.

## Compilar desde el código

Requiere Swift 5.9 o posterior.

```bash
swift build                          # compilación de desarrollo
./Scripts/build_app.sh               # genera el .app en dist/
./Scripts/check_localizations.sh     # comprueba que las traducciones estén al día
```

Las compilaciones de distribución necesitan un certificado Developer ID.

```bash
./Scripts/build_app.sh --release     # firma Developer ID + Hardened Runtime
./Scripts/notarize.sh                # crea el DMG y lo notariza
```

### Traducciones

Cada idioma es un archivo `Localizable.strings` dentro de `Resources/<lang>.lproj/`. El inglés es el idioma de desarrollo, así que una clave que falte en otro idioma recurre al inglés en lugar de mostrar la clave en bruto. `Scripts/check_localizations.sh` informa de claves ausentes, sin usar o sin definir: ejecútalo después de tocar cualquier texto.

El razonamiento detrás de la lógica de detección y de las decisiones de diseño está en los comentarios del código.

## Licencia

[MIT](../LICENSE)
