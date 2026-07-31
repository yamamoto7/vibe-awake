TAGLINE|Garde votre Mac éveillé uniquement pendant qu'une session de codage IA travaille réellement.
NOTE|Votre mot de passe administrateur vous sera demandé une seule fois au premier lancement. Sous macOS, seul un assistant privilégié peut empêcher la veille en mode écran fermé → [Configuration](#configuration)
H_WHAT|À quoi ça sert
P_WHAT1|Vous confiez une longue tâche à Claude Code ou Codex CLI, vous vous absentez, et le Mac se met en veille avec le travail à moitié fait. Vibe Awake se loge dans la barre des menus et bloque la veille **uniquement pendant qu'une session génère une réponse** — **y compris en mode écran fermé**.
P_WHAT2|Contrairement à `caffeinate` laissé actif en permanence, une session qui attend à l'invite laisse le Mac se mettre en veille normalement. Plus de batterie gaspillée à vous attendre.
H_TOOLS|Outils pris en charge
T_SUPPORTED|Pris en charge
T_CLAUDE|Claude Code (terminal)
T_CODEX|Codex CLI (terminal)
T_DESKTOP|Application de bureau Claude
T_CURSOR|Cursor
P_HEADLESS|Les exécutions sans interface (`claude -p`, `codex exec`) ne sont pas concernées.
H_INSTALL|Installation
P_REQ|Nécessite **macOS 13 (Ventura) ou ultérieur**.
H_BREW|Homebrew
P_BREW_UPD|La mise à jour et la désinstallation passent aussi par Homebrew.
C_UNINSTALL|# supprime également l'assistant
H_MANUAL|Manuellement
P_MANUAL|Téléchargez le `.dmg` depuis [Releases](https://github.com/yamamoto7/vibe-awake/releases) et faites glisser `Vibe Awake.app` dans `Applications`.
H_SETUP|Configuration
P_SETUP1|Au premier lancement, votre **mot de passe administrateur vous sera demandé une seule fois**.
P_SETUP2|Sous macOS, seul un programme disposant des droits administrateur peut empêcher la mise en veille en mode écran fermé. L'assistant installé ne fait rien d'autre que basculer le réglage d'énergie intégré (`pmset`) : aucun accès réseau, aucune donnée collectée. Vous pouvez le supprimer à tout moment depuis les réglages.
P_SETUP3|Le blocage de la veille ne fait rien tant que la configuration n'est pas terminée.
H_USING|Utilisation
P_USING|Cliquez sur l'icône de la barre des menus pour voir ce qui se passe.
L_WORKING|**En cours** — génère une réponse ou exécute un outil
L_WAITING|**En attente d'approbation** — attend que vous confirmiez quelque chose
L_IDLE|**Inactive** — à l'invite, aucune tâche en cours
P_ICON|Une icône pleine signifie que la veille est bloquée. Une icône d'avertissement orange signifie que la configuration n'a pas été faite.
H_SETTINGS|Réglages
S_ENABLE|Bloquer la veille
S_ENABLE_D|Désactive tout temporairement
S_LOGIN|Ouvrir avec la session
S_LOGIN_D|Démarre avec votre Mac
S_DISPLAY|Éteindre l'écran en mode écran fermé
S_DISPLAY_D|Pendant le blocage de la veille, macOS laisse l'écran intégré allumé même en mode écran fermé. L'éteindre économise de l'énergie. Sans effet si un écran externe est connecté
S_APPROVAL|Compter l'attente d'approbation comme du travail
S_APPROVAL_D|Activez cette option si vous approuvez à distance, depuis votre téléphone par exemple. Sinon, le Mac se met en veille pendant qu'une session attend votre approbation
H_LANGS|Langues
P_LANGS|English, 日本語, 简体中文, 한국어, Español, Français, Deutsch, Português (Brasil), Русский. L'app suit la langue configurée dans macOS.
H_CAVEATS|À savoir
P_CAVEAT1|La détection lit des fichiers d'état internes qu'aucune des deux CLI ne documente ; **une mise à jour de ces outils peut donc la casser**. Si cela ne fonctionne plus, ouvrez un [ticket](https://github.com/yamamoto7/vibe-awake/issues).
P_CAVEAT2|Ceci est un outil non officiel, sans lien avec Anthropic ni OpenAI. Claude, Claude Code et Codex sont des marques de leurs propriétaires respectifs.
H_BUILD|Compiler depuis les sources
P_BUILD_REQ|Nécessite Swift 5.9 ou ultérieur.
C_DEV|# compilation de développement
C_APP|# produit le .app dans dist/
C_L10N|# vérifie que les traductions sont à jour
P_BUILD_DIST|Les compilations de distribution nécessitent un certificat Developer ID.
C_SIGN|# signature Developer ID + Hardened Runtime
C_NOTARIZE|# crée le DMG et le fait notariser
H_TRANS|Traductions
P_TRANS|Chaque langue est un fichier `Localizable.strings` sous `Resources/<lang>.lproj/`. L'anglais est la langue de développement : une clé manquante ailleurs retombe sur l'anglais au lieu d'afficher la clé brute. `Scripts/check_localizations.sh` signale les clés manquantes, inutilisées ou non définies — lancez-le après avoir touché au moindre texte.
P_SOURCE|Le raisonnement derrière la logique de détection et les choix de conception se trouve dans les commentaires du code.
H_LICENSE|Licence
