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

Le script accepte un argument qui détermine ce qu'il exécute :

- `install` – Installe les outils et dépendances.
- `links` – Supprime les anciens fichiers de config et crée des symlinks vers les dotfiles.
- `all` – Exécute à la fois `install` et `links`.

---

## ▶️ Utilisation

```bash
chmod +x setup.sh
./setup.sh {install|links|all}
```

> **Note:** Le script peut exécuter plusieurs fois sans problème.

> **Note:** Le script ne modifie pas les fichiers de configuration existants. Il créera des symlinks vers les dotfiles.

Exemples :

```bash
./setup.sh install
./setup.sh links
./setup.sh all
```

## 📦 Ce que le script installe (`install` ou `all`)

- **Homebrew** – Gestionnaire de paquets macOS
- **Rosetta 2** – Compatibilité avec les applications Intel
- **Docker Desktop** – Version ARM64
- **Node.js** (via `nvm`), en version LTS
- **Yarn**, **TypeScript**
- **Neovim**, **tmux**, **fzf**, **bat**, **git**, **zsh**
- **eza**, **zoxide**, **gh**, **lazygit**, **coursier**, **starship**
- **ripgrep**, **git-flow-avh**, **gnu-tar**, **postgresql**, **pigz**
- **Google Cloud SDK**
- **Raycast**
- **Oh My Zsh**, avec :
  - `zsh-syntax-highlighting`
  - `zsh-autosuggestions`
- **Kitty** – Terminal moderne
- **Tmux Plugin Manager (TPM)**

---

## 🔗 Symlinks créés (`links` ou `all`)

Le script supprime les fichiers de configuration existants s’ils sont présents, puis crée des liens symboliques vers les dotfiles stockés dans `~/.config/dotfiles` :

- `~/.zshrc`
- `~/.tmux.conf`
- `~/.gitconfig`
- `~/.gitignore_global`
- `~/.z`
- `~/.config/nvim`
- `~/.config/kitty`
- `~/.config/sesh`
- `~/.config/starship.toml`

---

## 📝 Prérequis

- macOS avec puce Apple Silicon
- Dossier `~/.config/dotfiles` correctement structuré

---

## ⚠️ Avertissement

Ce script **écrasera vos fichiers de configuration existants**. Assurez-vous de les sauvegarder si nécessaire.
