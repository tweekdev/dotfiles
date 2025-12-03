# 💻 Mac Dev Environment Setup

Ce dépôt contient un script Bash pour configurer rapidement un environnement de développement moderne sur macOS (Apple Silicon).

---

## 🚀 Première installation sur un nouveau MacBook

### Étape 1 : Installer Git (si nécessaire)

Sur macOS, Git peut être installé de deux façons :

**Option A : Via Xcode Command Line Tools (recommandé)**
```bash
xcode-select --install
```

**Option B : Via Homebrew (si Homebrew est déjà installé)**
```bash
brew install git
```

### Étape 2 : Cloner ce dépôt

```bash
# Créer le dossier de configuration si nécessaire
mkdir -p ~/.config

# Cloner le dépôt (remplacez <URL_DU_REPO> par l'URL de votre dépôt)
cd ~/.config
git clone <URL_DU_REPO> dotfiles

# Aller dans le dossier
cd dotfiles
```

> **Note :** Si vous n'avez pas encore de dépôt Git, vous pouvez créer un nouveau dépôt sur GitHub/GitLab, puis cloner l'URL fournie.

### Étape 3 : Exécuter le script de setup

```bash
# Rendre le script exécutable
chmod +x setup.sh

# Installer tous les outils et créer les liens symboliques
./setup.sh all
```

Le script va :
1. Installer Homebrew (si pas déjà installé)
2. Installer tous les outils nécessaires (Git, Neovim, Node.js, etc.)
3. Créer les liens symboliques vers vos dotfiles

### Étape 4 : Redémarrer le terminal

Fermez et rouvrez votre terminal pour que tous les changements prennent effet.

### Étape 5 : Configurer Neovim (première fois)

Lors de la première ouverture de Neovim, les plugins seront automatiquement installés via LazyVim :
```bash
nvim
```

Attendez que l'installation des plugins se termine (cela peut prendre quelques minutes).

---

## 🛠️ Modes disponibles

Le script accepte plusieurs modes d'exécution :

### Modes de base
- `install` – Installe les outils et dépendances.
- `links` – Crée des symlinks vers les dotfiles (avec backup automatique).
- `all` – Exécute à la fois `install` et `links`.

### Modes avancés
- `update` – Met à jour les outils déjà installés (Homebrew, plugins Zsh/Tmux).
- `check` – Vérifie l'état de l'installation et l'intégrité des symlinks.
- `clean` – Nettoie les fichiers temporaires et anciens backups (garde les 5 derniers).
- `rollback` – Restaure un backup précédent (liste les backups disponibles).
- `sync` – Synchronise avec le dépôt distant et met à jour les symlinks.

---

## ▶️ Utilisation

### Utilisation de base

```bash
chmod +x setup.sh
./setup.sh {install|links|all|update|check|clean|rollback|sync}
```

### Options disponibles

- `--dry-run` – Simulation sans exécution (affiche ce qui serait fait).
- `--log FILE` – Enregistre tous les logs dans un fichier.
- `--only TOOLS` – Installe uniquement les outils spécifiés (séparés par des virgules).
- `--profile PROFILE` – Utilise un profil d'installation (`minimal`, `dev`, `full`).
- `--verbose` ou `-v` – Mode verbeux (affiche plus de détails).

### Exemples

```bash
# Installation complète
./setup.sh all

# Installation avec profil minimal
./setup.sh install --profile minimal

# Installation sélective
./setup.sh install --only neovim,tmux,git

# Simulation (dry-run)
./setup.sh install --dry-run

# Avec logging
./setup.sh install --log setup.log

# Vérification de l'état
./setup.sh check

# Mise à jour
./setup.sh update

# Nettoyage
./setup.sh clean

# Restauration d'un backup
./setup.sh rollback
```

> **Note:** Le script peut être exécuté plusieurs fois sans problème (idempotent).

> **Note:** Le script crée automatiquement un backup avant toute modification.

## 📦 Ce que le script installe (`install` ou `all`)

- **Homebrew** – Gestionnaire de paquets macOS (avec mise à jour automatique)
- **Rosetta 2** – Compatibilité avec les applications Intel
- **Docker Desktop** – Version ARM64 (installation automatique)
- **Node.js** (via `nvm`), en version LTS
- **Yarn**, **TypeScript**
- **Neovim**, **tmux**, **fzf**, **bat**, **git**, **zsh**
- **eza**, **zoxide**, **gh**, **lazygit**, **coursier**, **starship**
- **ripgrep**, **git-flow-avh**, **gnu-tar**, **postgresql**, **pigz**, **diff-so-fancy**, **sesh**
- **AWS CLI**, **Google Cloud SDK**
- **Raycast**, **Slack**, **Ghostty**, **Google Chrome**
- **Cursor** – Éditeur de code IA
- **Oh My Zsh**, avec :
  - `zsh-syntax-highlighting` (mise à jour automatique)
  - `zsh-autosuggestions` (mise à jour automatique)
- **Kitty** – Terminal moderne
- **Tmux Plugin Manager (TPM)** (avec installation automatique des plugins)
- **SDKMAN** avec Java, Scala et SBT

---

## 🔗 Symlinks créés (`links` ou `all`)

Le script crée automatiquement un backup de vos fichiers existants dans `~/.config/dotfiles-backup-YYYYMMDD-HHMMSS/`, puis crée des liens symboliques vers les dotfiles stockés dans `~/.config/dotfiles` :

- `~/.zshrc`
- `~/.tmux.conf`
- `~/.gitconfig`
- `~/.gitignore_global`
- `~/.config/nvim`
- `~/.config/kitty`
- `~/.config/sesh`
- `~/.config/cursor` (configuration Cursor)
- `~/.config/vscode` (configuration VSCode)
- `~/.config/starship.toml`

> **Note :** Le fichier `~/.z` (base de données z/zoxide) n'est pas suivi par git car il contient des données locales qui changent constamment.

> **Note :** Les configurations Cursor et VSCode sont automatiquement sauvegardées depuis `~/Library/Application Support/` lors de l'installation.

---

## 📝 Prérequis

- macOS avec puce Apple Silicon
- Dossier `~/.config/dotfiles` correctement structuré

---

## ✨ Fonctionnalités

### Fonctionnalités de base
- ✅ **Backup automatique** : Tous les fichiers existants sont sauvegardés avant d'être remplacés
- ✅ **Vérifications préliminaires** : Connexion internet et architecture système
- ✅ **Mise à jour automatique** : Homebrew et tous les packages sont mis à jour
- ✅ **Détection intelligente** : Le script détecte ce qui est déjà installé
- ✅ **Configuration automatique** : NVM, Git et plugins sont configurés automatiquement
- ✅ **Gestion d'erreurs** : Messages clairs en cas de problème

### Fonctionnalités avancées
- ✅ **Sauvegarde Cursor/VSCode** : Sauvegarde automatique des configurations des éditeurs
- ✅ **Mode dry-run** : Simulation sans exécution pour vérifier les actions
- ✅ **Installation sélective** : Installation uniquement des outils spécifiés
- ✅ **Profils d'installation** : Profils prédéfinis (minimal, dev, full)
- ✅ **Logging** : Enregistrement de toutes les actions dans un fichier
- ✅ **Vérification de santé** : Mode `check` pour vérifier l'état de l'installation
- ✅ **Restauration** : Mode `rollback` pour restaurer un backup précédent
- ✅ **Synchronisation** : Mode `sync` pour synchroniser avec le dépôt distant
- ✅ **Nettoyage automatique** : Mode `clean` pour nettoyer les anciens backups

## 🔧 Script de maintenance

Un script de maintenance automatique est disponible :

```bash
./maintain.sh
```

Ce script effectue :
- Vérification des mises à jour du dépôt
- Vérification de l'intégrité des symlinks
- Nettoyage des anciens backups (garde les 5 derniers)
- Vérification des mises à jour Homebrew
- Rapport sur l'espace disque utilisé

---

## ⚠️ Avertissement

Ce script **remplacera vos fichiers de configuration existants** par des symlinks. Un backup automatique est créé dans `~/.config/dotfiles-backup-YYYYMMDD-HHMMSS/` avant toute modification.
