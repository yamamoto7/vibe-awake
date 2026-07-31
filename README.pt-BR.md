<div align="center">
  <img src="Resources/logo.png" width="128" alt="Vibe Awake">
  <h1>Vibe Awake</h1>
  <p>Mantém seu Mac acordado apenas enquanto uma sessão de programação com IA está de fato trabalhando.</p>
  <p><a href="README.md">English</a> · <a href="README.ja.md">日本語</a> · <a href="README.zh-Hans.md">简体中文</a> · <a href="README.ko.md">한국어</a> · <a href="README.es.md">Español</a> · <a href="README.fr.md">Français</a> · <a href="README.de.md">Deutsch</a> · Português · <a href="README.ru.md">Русский</a></p>
</div>

```bash
brew tap yamamoto7/tap
brew install --cask vibe-awake
```

> [!NOTE]
> Sua senha de administrador será pedida uma única vez no primeiro uso. O macOS só permite que um auxiliar privilegiado impeça o repouso com a tampa fechada → [Configuração](#configuração)

## O que faz

Você passa uma tarefa longa para o Claude Code ou o Codex CLI, sai da frente, e o Mac entra em repouso com o trabalho pela metade. O Vibe Awake fica na barra de menus e bloqueia o repouso **apenas enquanto uma sessão está gerando uma resposta** — **inclusive com a tampa do MacBook fechada**.

Diferente de deixar o `caffeinate` ligado, uma sessão parada no prompt deixa o Mac dormir normalmente. Sem gastar bateria esperando você voltar.

## Ferramentas compatíveis

| | Compatível |
|---|:---:|
| Claude Code (terminal) | ✅ |
| Codex CLI (terminal) | ✅ |
| App de mesa do Claude | ― |
| Cursor | ― |

Execuções sem interface (`claude -p`, `codex exec`) estão fora do escopo.

## Instalação

Requer **macOS 13 (Ventura) ou posterior**.

### Homebrew

```bash
brew tap yamamoto7/tap
brew install --cask vibe-awake
```

Atualizar e desinstalar também passam pelo Homebrew.

```bash
brew upgrade --cask vibe-awake
brew uninstall --cask vibe-awake   # remove o auxiliar também
```

### Manualmente

Baixe o `.dmg` em [Releases](https://github.com/yamamoto7/vibe-awake/releases) e arraste o `Vibe Awake.app` para `Aplicativos`.

## Configuração

No primeiro uso será pedida sua **senha de administrador, uma única vez**.

O macOS só permite que um programa com permissões de administrador impeça o Mac de dormir com a tampa fechada. O auxiliar instalado não faz nada além de alternar o ajuste de energia nativo (`pmset`) — sem acesso à rede e sem coletar dados. Você pode removê-lo a qualquer momento nos ajustes.

O bloqueio de repouso não faz nada até a configuração terminar.

## Como usar

Clique no ícone da barra de menus para ver o que está acontecendo.

- **Trabalhando** — gerando uma resposta ou executando uma ferramenta
- **Aguardando aprovação** — esperando você confirmar algo
- **Ociosa** — parada no prompt

Um ícone preenchido significa que o repouso está bloqueado. Um ícone laranja de aviso significa que falta configurar.

## Ajustes

| | |
|---|---|
| Bloquear repouso | Desliga tudo temporariamente |
| Abrir ao iniciar sessão | Inicia junto com o Mac |
| Desligar a tela ao fechar a tampa | Enquanto o repouso está bloqueado, o macOS deixa a tela interna ligada atrás da tampa fechada. Desligá-la economiza energia. Não faz nada quando há uma tela externa conectada |
| Contar espera por aprovação como trabalho | Ative se você aprova remotamente, pelo celular por exemplo. Desativado, o Mac dorme enquanto uma sessão espera sua aprovação |

## Idiomas

English, 日本語, 简体中文, 한국어, Español, Français, Deutsch, Português (Brasil), Русский. O app segue o idioma configurado no macOS.

## Observações

A detecção lê arquivos de estado internos que nenhuma das duas CLIs documenta, então **uma atualização dessas ferramentas pode quebrá-la**. Se parar de funcionar, abra uma [issue](https://github.com/yamamoto7/vibe-awake/issues).

Esta é uma ferramenta não oficial, sem vínculo com a Anthropic ou a OpenAI. Claude, Claude Code e Codex são marcas de seus respectivos donos.

## Compilar a partir do código

Requer Swift 5.9 ou posterior.

```bash
swift build                          # compilação de desenvolvimento
./Scripts/build_app.sh               # gera o .app em dist/
./Scripts/check_localizations.sh     # verifica se as traduções estão em dia
```

Compilações para distribuição precisam de um certificado Developer ID.

```bash
./Scripts/build_app.sh --release     # assinatura Developer ID + Hardened Runtime
./Scripts/notarize.sh                # monta o DMG e faz a notarização
```

### Traduções

Cada idioma é um arquivo `Localizable.strings` em `Resources/<lang>.lproj/`. O inglês é o idioma de desenvolvimento, então uma chave que falte em outro idioma recorre ao inglês em vez de mostrar a chave crua. O `Scripts/check_localizations.sh` aponta chaves faltando, não usadas ou não definidas — rode-o depois de mexer em qualquer texto.

O raciocínio por trás da lógica de detecção e das decisões de projeto está nos comentários do código.

## Licença

[MIT](LICENSE)
