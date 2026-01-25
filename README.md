# 🛠️ Dotfiles

Configuration personnelle pour macOS (Apple Silicon).

---

## 🚀 Nouveau Mac ? Fais ça :

### Étape 1 : Ouvre Terminal

Cherche "Terminal" dans Spotlight (Cmd + Espace) et ouvre-le.

### Étape 2 : Copie-colle cette commande

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/tweekdev/dotfiles/master/install.sh)"
```

### Étape 3 : Attends

Le script va :
1. Installer Xcode Command Line Tools (si nécessaire)
2. Installer Homebrew
3. Cloner ce repo dans `~/.config/dotfiles`
4. Installer tous les outils (Brewfile)
5. Créer les symlinks

**Durée : ~15-20 minutes** (selon ta connexion)

### Étape 4 : Redémarre le terminal

Ferme et rouvre Terminal (ou lance `source ~/.zshrc`).

### Étape 5 : Ouvre Neovim

```bash
nvim
```

Les plugins s'installent automatiquement au premier lancement.

---

## ⚠️ Si Xcode demande une installation

Si le script s'arrête avec un message sur Xcode :
1. Une fenêtre va s'ouvrir pour installer Xcode Command Line Tools
2. Clique "Installer" et attends la fin
3. **Relance la même commande** (Étape 2)

---

## 🔧 Installation manuelle (alternative)

Si le one-liner ne marche pas :

```bash
# 1. Installer Xcode Command Line Tools
xcode-select --install
# Attendre la fin de l'installation...

# 2. Installer Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 3. Cloner les dotfiles
mkdir -p ~/.config
cd ~/.config
git clone https://github.com/tweekdev/dotfiles.git
cd dotfiles

# 4. Lancer l'installation
./setup.sh all

# 5. Redémarrer le terminal
```

---

## 📦 Ce qui est installé

### Via Brewfile (automatique)

| Catégorie | Outils |
|-----------|--------|
| **Terminal** | Ghostty, tmux, starship |
| **Éditeurs** | Neovim, Cursor, VS Code |
| **Dev Tools** | git, gh, lazygit, fzf, ripgrep |
| **Node.js** | nvm, yarn (via npm) |
| **Java/Scala** | SDKMAN, Java 17, Scala, SBT |
| **Shell** | zsh, Oh My Zsh, zsh-autosuggestions, zsh-syntax-highlighting |
| **Utilitaires** | bat, eza, zoxide, jq, fd, entr |
| **Cloud** | AWS CLI, Google Cloud SDK |
| **Apps** | Raycast, Zen Browser |

### Apps manuelles (optionnel)

Ces apps sont commentées dans le Brewfile car souvent déjà installées :
- Docker Desktop
- Google Chrome  
- Slack

Pour les installer via Homebrew, décommentez-les dans `Brewfile` puis :
```bash
brew bundle --file=~/.config/dotfiles/Brewfile
```

---

## 🔗 Symlinks créés

```
~/.zshrc              → dotfiles/.zshrc
~/.tmux.conf          → dotfiles/.tmux.conf
~/.gitconfig          → dotfiles/.gitconfig
~/.gitignore_global   → dotfiles/.gitignore_global
~/.config/nvim/       → dotfiles/nvim/
~/.config/cursor/     → dotfiles/cursor/
~/.config/vscode/     → dotfiles/vscode/
~/.config/sesh/       → dotfiles/sesh/
~/.config/git/        → dotfiles/git/
~/.config/ghostty/    → dotfiles/ghostty/
~/.config/starship.toml → dotfiles/starship.toml
~/Pictures/Wallpapers/  ← dotfiles/wallpapers/ (copie)
```

---

## 🎮 Commandes

```bash
./setup.sh <mode> [options]
```

### Modes

| Mode | Description |
|------|-------------|
| `all` | Installation complète (install + links) |
| `install` | Installe les outils via Brewfile |
| `links` | Crée les symlinks |
| `update` | Met à jour tout (Homebrew, npm, plugins) |
| `check` | Vérifie l'état de l'installation |
| `clean` | Nettoie les anciens backups |
| `rollback` | Restaure un backup précédent |
| `sync` | Pull git + met à jour les symlinks |

### Options

| Option | Description |
|--------|-------------|
| `--dry-run` | Simulation sans exécution |
| `--verbose` | Mode verbeux |
| `--log FILE` | Enregistre les logs |

### Exemples

```bash
# Installation complète
./setup.sh all

# Simulation
./setup.sh all --dry-run

# Vérification
./setup.sh check

# Mise à jour
./setup.sh update

# Restaurer un backup
./setup.sh rollback
```

---

## 🍺 Brewfile

Gestion déclarative des packages Homebrew.

```bash
# Installer les packages manquants
brewfile        # ou: brew bundle --file=~/.config/dotfiles/Brewfile

# Vérifier l'état
brewcheck       # ou: brew bundle check --file=~/.config/dotfiles/Brewfile

# Voir les packages non déclarés
brewclean       # ou: brew bundle cleanup --file=~/.config/dotfiles/Brewfile

# Exporter les packages installés
brewdump        # ou: brew bundle dump --force --file=~/.config/dotfiles/Brewfile
```

---

## 📁 Structure

```
~/.config/dotfiles/
├── .zshrc              # Config Zsh + aliases
├── .tmux.conf          # Config Tmux
├── .gitconfig          # Config Git
├── .gitignore_global   # Gitignore global
├── Brewfile            # Packages Homebrew
├── starship.toml       # Prompt Starship
├── setup.sh            # Script d'installation
├── maintain.sh         # Script de maintenance
├── cursor/             # Config Cursor IDE
├── vscode/             # Config VS Code
├── nvim/               # Config Neovim (LazyVim)
├── sesh/               # Sessions Tmux
├── git/                # Templates Git
└── scripts/            # Scripts utilitaires
```

---

## ⚙️ Maintenance

```bash
# Mise à jour complète
./setup.sh update

# Ou manuellement :
brew update && brew upgrade    # Homebrew
sdk selfupdate                 # SDKMAN
npm update -g                  # npm global packages
```

---

## 🍎 macOS Defaults

Configurer les préférences système macOS (Dock, Finder, Keyboard, etc.) :

```bash
./macos-defaults.sh
```

Ce script configure :
- Clavier rapide (répétition des touches)
- Dock auto-hide avec animations rapides
- Finder avec barre de chemin et extensions
- Screenshots dans ~/Pictures/Screenshots
- Trackpad tap-to-click
- Et plus...

---

## 🔄 Synchronisation

Pour synchroniser les dotfiles après des modifications :

```bash
# Depuis le repo distant
./setup.sh sync

# Ou manuellement
cd ~/.config/dotfiles
git pull
./setup.sh links
```

---

## ⚠️ Notes

- **Backup automatique** : Les fichiers existants sont sauvegardés dans `~/.config/dotfiles-backup-*`
- **Idempotent** : Le script peut être exécuté plusieurs fois sans problème
- **Apple Silicon** : Optimisé pour les Mac M1/M2/M3
- **Git config** : Ton nom/email sont dans `.gitconfig`, pas besoin de les reconfigurer
