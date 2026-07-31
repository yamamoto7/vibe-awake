TAGLINE|Mantém seu Mac acordado apenas enquanto uma sessão de programação com IA está de fato trabalhando.
NOTE|Sua senha de administrador será pedida uma única vez no primeiro uso. O macOS só permite que um auxiliar privilegiado impeça o repouso com a tampa fechada → [Configuração](#configuração)
H_WHAT|O que faz
P_WHAT1|Você passa uma tarefa longa para o Claude Code ou o Codex CLI, sai de perto do computador, e o Mac entra em repouso com o trabalho pela metade. O Vibe Awake fica na barra de menus e bloqueia o repouso **apenas enquanto uma sessão está gerando uma resposta** — **inclusive com a tampa do MacBook fechada**.
P_WHAT2|Ao contrário de deixar o `caffeinate` rodando, uma sessão parada no prompt deixa o Mac entrar em repouso normalmente. Sem gastar bateria esperando você voltar.
H_TOOLS|Ferramentas compatíveis
T_SUPPORTED|Compatível
T_CLAUDE|Claude Code (terminal)
T_CODEX|Codex CLI (terminal)
T_DESKTOP|App do Claude para computador
T_CURSOR|Cursor
P_HEADLESS|Execuções sem interface (`claude -p`, `codex exec`) estão fora do escopo.
H_INSTALL|Instalação
P_REQ|Requer **macOS 13 (Ventura) ou posterior**.
H_BREW|Homebrew
P_BREW_UPD|Atualizar e desinstalar também passam pelo Homebrew.
C_UNINSTALL|# remove o auxiliar também
H_MANUAL|Manualmente
P_MANUAL|Baixe o `.dmg` em [Releases](https://github.com/yamamoto7/vibe-awake/releases) e arraste o `Vibe Awake.app` para `Aplicativos`.
H_SETUP|Configuração
P_SETUP1|No primeiro uso será pedida sua **senha de administrador, uma única vez**.
P_SETUP2|O macOS só permite que um programa com permissões de administrador impeça o Mac de entrar em repouso com a tampa fechada. O auxiliar instalado não faz nada além de ativar e desativar o ajuste de energia nativo (`pmset`) — sem acesso à rede e sem coletar dados. Você pode removê-lo a qualquer momento nos ajustes.
P_SETUP3|O bloqueio de repouso não faz nada até a configuração terminar.
H_USING|Como usar
P_USING|Clique no ícone da barra de menus para ver o que está acontecendo.
L_WORKING|**Trabalhando** — gerando uma resposta ou executando uma ferramenta
L_WAITING|**Aguardando aprovação** — esperando você confirmar algo
L_IDLE|**Ociosa** — parada no prompt
P_ICON|Um ícone preenchido significa que o repouso está bloqueado. Um ícone laranja de aviso significa que falta configurar.
H_SETTINGS|Ajustes
S_ENABLE|Bloquear repouso
S_ENABLE_D|Desliga tudo temporariamente
S_LOGIN|Abrir ao iniciar sessão
S_LOGIN_D|Inicia junto com o Mac
S_DISPLAY|Desligar a tela ao fechar a tampa
S_DISPLAY_D|Enquanto o repouso está bloqueado, o macOS deixa a tela integrada ligada mesmo com a tampa fechada. Desligá-la economiza energia. Não faz nada quando há uma tela externa conectada
S_APPROVAL|Considerar a espera por aprovação como trabalho
S_APPROVAL_D|Ative se você costuma aprovar remotamente, pelo celular, por exemplo. Com a opção desativada, o Mac entra em repouso enquanto uma sessão aguarda sua aprovação
H_LANGS|Idiomas
P_LANGS|English, 日本語, 简体中文, 한국어, Español, Français, Deutsch, Português (Brasil), Русский. O app segue o idioma configurado no macOS.
H_CAVEATS|Observações
P_CAVEAT1|A detecção lê arquivos de estado internos que nenhuma das duas CLIs documenta, então **uma atualização dessas ferramentas pode quebrá-la**. Se parar de funcionar, abra uma [issue](https://github.com/yamamoto7/vibe-awake/issues).
P_CAVEAT2|Esta é uma ferramenta não oficial, sem vínculo com a Anthropic ou a OpenAI. Claude, Claude Code e Codex são marcas de seus respectivos donos.
H_BUILD|Compilar a partir do código
P_BUILD_REQ|Requer Swift 5.9 ou posterior.
C_DEV|# compilação de desenvolvimento
C_APP|# gera o .app em dist/
C_L10N|# verifica se as traduções estão em dia
P_BUILD_DIST|Compilações para distribuição precisam de um certificado Developer ID.
C_SIGN|# assinatura Developer ID + Hardened Runtime
C_NOTARIZE|# monta o DMG e faz a notarização
H_TRANS|Traduções
P_TRANS|Cada idioma é um arquivo `Localizable.strings` em `Resources/<lang>.lproj/`. O inglês é o idioma de desenvolvimento, então uma chave que falte em outro idioma recorre ao inglês em vez de mostrar a chave crua. O `Scripts/check_localizations.sh` aponta chaves faltando, não usadas ou não definidas — rode-o depois de mexer em qualquer texto.
P_SOURCE|O raciocínio por trás da lógica de detecção e das decisões de projeto está nos comentários do código.
H_LICENSE|Licença
