#!/bin/bash

MODE=$1
shift || true

# Variables globales
DRY_RUN=false
LOG_FILE=""
SELECTIVE_TOOLS=""
PROFILE=""
VERBOSE=false

# Parse des arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --log)
      LOG_FILE="$2"
      shift 2
      ;;
    --only)
      SELECTIVE_TOOLS="$2"
      shift 2
      ;;
    --profile)
      PROFILE="$2"
      shift 2
      ;;
    --verbose|-v)
      VERBOSE=true
      shift
      ;;
    *)
      echo "Option inconnue: $1"
      exit 1
      ;;
  esac
done

if [ "$DRY_RUN" = false ]; then
  set -e  # Stop on error
else
  set +e  # Ne pas s'arrêter en dry-run
fi

# Fonction pour logger
log() {
  local level=$1
  shift
  local message="$@"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  
  if [ -n "$LOG_FILE" ]; then
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
  fi
  
  if [ "$level" = "ERROR" ] || [ "$VERBOSE" = true ] || [ "$level" != "DEBUG" ]; then
    echo "$message"
  fi
}

# Fonction pour exécuter une commande (avec support dry-run)
execute() {
  local cmd="$@"
  if [ "$DRY_RUN" = true ]; then
    log "DRY-RUN" "Would execute: $cmd"
    return 0
  else
    log "DEBUG" "Executing: $cmd"
    eval "$cmd"
    return $?
  fi
}

# Fonction pour vérifier la connexion internet
check_internet() {
  if ! ping -c 1 -W 2 8.8.8.8 &>/dev/null && ! ping -c 1 -W 2 1.1.1.1 &>/dev/null; then
    echo "❌ Pas de connexion internet détectée."
    echo "⚠️  Le script nécessite une connexion internet pour fonctionner."
    exit 1
  fi
}

# Fonction pour vérifier l'architecture
check_architecture() {
  local arch
  arch=$(uname -m)
  if [ "$arch" != "arm64" ]; then
    echo "⚠️  Attention : Ce script est optimisé pour Apple Silicon (arm64)."
    echo "   Architecture détectée : $arch"
    if [ "$DRY_RUN" = false ]; then
      read -p "   Voulez-vous continuer quand même ? (y/N) " -n 1 -r
      echo
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
      fi
    fi
  fi
}

# Fonction pour sauvegarder les configs Cursor et VSCode
save_editor_configs() {
  CONFIG_DIR="$HOME/.config"
  DOTFILES="$CONFIG_DIR/dotfiles"
  
  # Fichiers de configuration essentiels à sauvegarder
  CONFIG_FILES=("settings.json" "keybindings.json" "snippets")
  
  # Cursor - ne sauvegarder que les fichiers essentiels
  if [ -d "$HOME/Library/Application Support/Cursor/User" ]; then
    log "INFO" "💾 Sauvegarde de la configuration Cursor..."
    mkdir -p "$DOTFILES/cursor/User"
    if [ "$DRY_RUN" = false ]; then
      for file in "${CONFIG_FILES[@]}"; do
        if [ -e "$HOME/Library/Application Support/Cursor/User/$file" ]; then
          cp -r "$HOME/Library/Application Support/Cursor/User/$file" "$DOTFILES/cursor/User/" 2>/dev/null || true
        fi
      done
      log "INFO" "✅ Configuration Cursor sauvegardée (fichiers essentiels uniquement)"
    else
      log "DRY-RUN" "Would copy Cursor config files (settings.json, keybindings.json, snippets)"
    fi
  fi
  
  # VSCode - ne sauvegarder que les fichiers essentiels
  if [ -d "$HOME/Library/Application Support/Code/User" ]; then
    log "INFO" "💾 Sauvegarde de la configuration VSCode..."
    mkdir -p "$DOTFILES/vscode/User"
    if [ "$DRY_RUN" = false ]; then
      for file in "${CONFIG_FILES[@]}"; do
        if [ -e "$HOME/Library/Application Support/Code/User/$file" ]; then
          cp -r "$HOME/Library/Application Support/Code/User/$file" "$DOTFILES/vscode/User/" 2>/dev/null || true
        fi
      done
      log "INFO" "✅ Configuration VSCode sauvegardée (fichiers essentiels uniquement)"
    else
      log "DRY-RUN" "Would copy VSCode config files (settings.json, keybindings.json, snippets)"
    fi
  fi
}

do_install() {
  log "INFO" "📦 Début de l'installation..."

  # Vérifications préliminaires
  check_internet
  check_architecture

  # Sauvegarder les configs Cursor et VSCode si elles existent
  save_editor_configs

  # Assurez-vous que le script s'exécute depuis le répertoire home
  cd "$HOME" || exit

  # Vérifie si Git est installé (nécessaire pour Homebrew)
  if ! command -v git &>/dev/null; then
    echo "❌ Git n'est pas installé."
    echo ""
    echo "📝 Pour installer Git, exécutez l'une des commandes suivantes :"
    echo "   Option 1 (recommandé) : xcode-select --install"
    echo "   Option 2 : Téléchargez Xcode depuis l'App Store"
    echo ""
    echo "⚠️  Le script ne peut pas continuer sans Git."
    exit 1
  else
    echo "✅ Git est déjà installé ($(git --version))."
  fi

  # Vérifie si Homebrew est installé
  if ! command -v brew &>/dev/null; then
    echo "🍺 Installation de Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    echo "✅ Homebrew déjà installé."
    echo "🔄 Mise à jour de Homebrew et des formules..."
    brew update
    brew upgrade
  fi

  # Vérifie si Rosetta 2 est installé
  if ! /usr/sbin/softwareupdate --install-rosetta --agree-to-license &>/dev/null; then
    echo "🔄 Installation de Rosetta 2..."
    softwareupdate --install-rosetta --agree-to-license || true
  else
    echo "✅ Rosetta 2 est déjà installé."
  fi

  # Vérifie si Docker est déjà installé
  if ! command -v docker &>/dev/null; then
    if [ ! -d "/Applications/Docker.app" ]; then
      echo "🐳 Téléchargement de Docker Desktop ARM64..."
      cd "$HOME/Downloads" || mkdir -p "$HOME/Downloads" && cd "$HOME/Downloads"
      curl -L -o Docker.dmg "https://desktop.docker.com/mac/main/arm64/Docker.dmg?utm_source=docker&utm_medium=webreferral&utm_campaign=docs-driven-download-mac-arm64"
      if [ -f "Docker.dmg" ]; then
        echo "📦 Installation de Docker Desktop..."
        hdiutil attach Docker.dmg -quiet
        cp -R /Volumes/Docker/Docker.app /Applications/
        hdiutil detach /Volumes/Docker -quiet
        echo "🧹 Nettoyage du fichier Docker.dmg..."
        rm -f Docker.dmg
        echo "✅ Docker Desktop installé. Veuillez l'ouvrir pour terminer la configuration."
      fi
    else
      echo "✅ Docker est déjà installé."
    fi
  else
    echo "✅ Docker est déjà installé."
  fi

  # Vérifie si NVM est installé (vérifie via Homebrew car nvm est une fonction shell)
  if ! brew list nvm &>/dev/null; then
    echo "🧱 Installation de NVM et Node.js (LTS)..."
    brew install nvm
    export NVM_DIR="$HOME/.nvm"
    mkdir -p "$NVM_DIR"
    source "$(brew --prefix nvm)/nvm.sh"
    nvm install --lts
    nvm use --lts
    nvm alias default node
  else
    echo "✅ NVM est déjà installé."
  fi

  # Vérifie si Yarn est installé (nécessite npm/NVM)
  if ! command -v yarn &>/dev/null; then
    if command -v npm &>/dev/null; then
      echo "📦 Installation de Yarn..."
      npm install -g yarn
    else
      echo "⚠️  Yarn nécessite Node.js. Il sera installé après le redémarrage du terminal."
    fi
  else
    echo "✅ Yarn est déjà installé."
  fi

  # Vérifie si Cursor est installé
  if ! command -v cursor &>/dev/null; then
    echo "📦 Installation de Cursor..."
    curl https://cursor.com/install -fsS | bash
    cursor --version
  else
    echo "✅ Cursor est déjà installé."
  fi

  # Vérifie si TypeScript est installé (nécessite npm/NVM)
  if command -v npm &>/dev/null; then
    if ! npm list -g typescript &>/dev/null 2>&1; then
      echo "📦 Installation de TypeScript..."
      npm install -g typescript
    else
      echo "✅ TypeScript est déjà installé."
    fi
  else
    echo "⚠️  TypeScript nécessite Node.js. Il sera installé après le redémarrage du terminal."
  fi

  # Définir les outils selon le profil ou sélection
  if [ -n "$PROFILE" ]; then
    case "$PROFILE" in
      minimal)
        TOOLS_TO_INSTALL="git zsh neovim tmux"
        ;;
      dev)
        TOOLS_TO_INSTALL="neovim tmux fzf bat git zsh eza zoxide gh lazygit starship ripgrep git-flow-avh gnu-tar postgresql pigz diff-so-fancy sesh"
        ;;
      full)
        TOOLS_TO_INSTALL="neovim tmux fzf bat git zsh eza zoxide gh lazygit starship ripgrep git-flow-avh gnu-tar postgresql pigz diff-so-fancy sesh"
        ;;
      *)
        log "ERROR" "❌ Profil inconnu: $PROFILE (minimal|dev|full)"
        exit 1
        ;;
    esac
  elif [ -n "$SELECTIVE_TOOLS" ]; then
    TOOLS_TO_INSTALL="$SELECTIVE_TOOLS"
  else
    TOOLS_TO_INSTALL="neovim tmux fzf bat git zsh eza zoxide gh lazygit starship ripgrep git-flow-avh gnu-tar postgresql pigz diff-so-fancy sesh"
  fi

  # Vérifie si les outils de développement sont installés
  # Utilise brew list pour vérifier l'installation (plus fiable que command -v)
  # Parser les outils (peuvent être séparés par des virgules ou des espaces)
  if [[ "$TOOLS_TO_INSTALL" == *","* ]]; then
    # Séparés par des virgules (mode --only)
    IFS=',' read -ra TOOLS <<< "$TOOLS_TO_INSTALL"
  else
    # Séparés par des espaces (profils)
    read -ra TOOLS <<< "$TOOLS_TO_INSTALL"
  fi
  
  for tool in "${TOOLS[@]}"; do
    tool=$(echo "$tool" | xargs)  # Trim whitespace
    if [ -z "$tool" ]; then
      continue  # Skip empty tools
    fi
    if ! brew list "$tool" &>/dev/null 2>&1; then
      log "INFO" "🔨 Installation de $tool..."
      execute "brew install '$tool'"
    else
      log "INFO" "✅ $tool est déjà installé."
    fi
  done

  # Installation de coursier (nécessite un tap spécial)
  if ! command -v coursier &>/dev/null; then
    echo "🔨 Installation de coursier..."
    brew install coursier/formulas/coursier
  else
    echo "✅ coursier est déjà installé."
  fi

  # Vérifie si AWS CLI est installé
  if ! command -v aws &>/dev/null; then
    echo "☁️ Installation de AWS CLI..."
    brew install awscli
  else
    echo "✅ AWS CLI est déjà installé."
  fi

  # Vérifie si Google Cloud SDK est installé
  if ! command -v gcloud &>/dev/null; then
    echo "☁️ Installation de Google Cloud SDK..."
    brew install --cask google-cloud-sdk
  else
    echo "✅ Google Cloud SDK est déjà installé."
  fi

  # Vérifie si Slack est installé
  if ! command -v slack &>/dev/null; then
    if [ ! -d "/Applications/Slack.app" ]; then
      echo "🚀 Installation de Slack..."
      brew install --cask slack
    fi
  else
    echo "✅ Slack est déjà installé."
  fi

  # Vérifie si Ghostty terminal est installé
  if ! command -v ghostty &>/dev/null; then
    if [ ! -d "/Applications/Ghostty.app" ]; then
      echo "🚀 Installation de Ghostty..."
      brew install --cask ghostty
    fi
  else
    echo "✅ Ghostty est déjà installé."
  fi

  # Vérifie si google-chrome est installé
  if ! command -v google-chrome &>/dev/null; then
    if [ ! -d "/Applications/Google Chrome.app" ]; then
      echo "🌐 Installation de Google Chrome..."
      brew install --cask google-chrome
    fi
  else
    echo "✅ Google Chrome est déjà installé."
  fi

  # Vérifie si SDKMAN est installé
  if [ ! -d "$HOME/.sdkman" ]; then
    echo "📦 Installation de SDKMAN..."
    curl -s "https://get.sdkman.io" | bash
    if [ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
      source "$HOME/.sdkman/bin/sdkman-init.sh"
      sdk version
      sdk install java 17.0.10-tem
      sdk install scala 2.13.11
      sdk install sbt
    else
      echo "⚠️  SDKMAN installé mais nécessite un redémarrage du terminal pour être utilisé."
    fi
  else
    echo "✅ SDKMAN est déjà installé."
  fi

  # Vérifie si la commande raycast -v fonctionne
  if raycast -v &>/dev/null; then
    echo "✅ Raycast est déjà installé (vérification par commande)."
  else
    # Si la commande échoue, vérifie si le dossier existe dans /Applications
    if [ -d "/Applications/Raycast.app" ]; then
      echo "✅ Raycast est déjà installé (vérification par dossier)."
    else
      echo "🚀 Installation de Raycast..."
      brew install --cask raycast
    fi
  fi

  # Vérifie si Oh My Zsh est installé
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "⚙️ Installation de Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  else
    echo "✅ Oh My Zsh est déjà installé."
  fi

  # Installation des plugins Zsh (après Oh My Zsh)
  echo "🧩 Installation des plugins Zsh..."
  
  # Vérifie si le plugin zsh-syntax-highlighting existe déjà
  PLUGIN_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
  if [ ! -d "$PLUGIN_DIR" ]; then
    echo "🔽 Installation du plugin zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$PLUGIN_DIR"
  else
    echo "✅ Plugin zsh-syntax-highlighting déjà installé."
    echo "🔄 Mise à jour du plugin zsh-syntax-highlighting..."
    (cd "$PLUGIN_DIR" && git pull --quiet || true)
  fi

  # Vérifie si le plugin zsh-autosuggestions existe déjà
  PLUGIN_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
  if [ ! -d "$PLUGIN_DIR" ]; then
    echo "🔽 Installation du plugin zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$PLUGIN_DIR"
  else
    echo "✅ Plugin zsh-autosuggestions déjà installé."
    echo "🔄 Mise à jour du plugin zsh-autosuggestions..."
    (cd "$PLUGIN_DIR" && git pull --quiet || true)
  fi

  # Vérifie si Kitty est installé
  if ! command -v kitty &>/dev/null; then
    if [ ! -d "/Applications/kitty.app" ]; then
      echo "🐱 Installation de Kitty terminal..."
      curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
    else
      echo "✅ Kitty est déjà installé."
    fi
  else
    echo "✅ Kitty est déjà installé."
  fi

  # Vérifie si Tmux Plugin Manager est installé
  if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "📦 Installation de Tmux Plugin Manager..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  else
    echo "✅ Tmux Plugin Manager est déjà installé."
    echo "🔄 Mise à jour de TPM..."
    (cd "$HOME/.tmux/plugins/tpm" && git pull --quiet || true)
  fi

  log "INFO" "✅ Installation terminée."
  
  # Générer un rapport si logging activé
  if [ -n "$LOG_FILE" ]; then
    {
      echo ""
      echo "=== RAPPORT D'INSTALLATION ==="
      echo "Date: $(date)"
      echo "Mode: $MODE"
      [ -n "$PROFILE" ] && echo "Profil: $PROFILE"
      [ -n "$SELECTIVE_TOOLS" ] && echo "Outils sélectionnés: $SELECTIVE_TOOLS"
      echo "Dry-run: $DRY_RUN"
      echo ""
      echo "Outils installés:"
      for tool in "${TOOLS[@]}"; do
        tool=$(echo "$tool" | xargs)
        if command -v "$tool" &>/dev/null || brew list "$tool" &>/dev/null 2>&1; then
          echo "  ✅ $tool"
        else
          echo "  ❌ $tool (non installé)"
        fi
      done
    } >> "$LOG_FILE"
  fi
}

do_post_install() {
  echo "⚙️ Configuration post-installation..."

  # Installation des plugins Tmux si .tmux.conf existe
  if [ -f "$HOME/.tmux.conf" ] || [ -L "$HOME/.tmux.conf" ]; then
    echo "🔌 Installation des plugins Tmux..."
    "$HOME/.tmux/plugins/tpm/bin/install_plugins" &>/dev/null || true
  fi

  # Vérifier si NVM est configuré dans .zshrc
  if [ -f "$HOME/.zshrc" ] || [ -L "$HOME/.zshrc" ]; then
    if ! grep -q "NVM_DIR" "$HOME/.zshrc" 2>/dev/null; then
      echo "📝 Ajout de la configuration NVM dans .zshrc..."
      {
        echo ""
        echo "# NVM Configuration"
        echo "export NVM_DIR=\"\$HOME/.nvm\""
        echo "[ -s \"\$(brew --prefix nvm)/nvm.sh\" ] && source \"\$(brew --prefix nvm)/nvm.sh\""
      } >> "$HOME/.zshrc"
    fi
  fi

  # Configuration Git initiale (si pas déjà configuré)
  if ! git config --global user.name &>/dev/null; then
    echo "📝 Configuration Git initiale requise..."
    read -p "   Entrez votre nom pour Git : " git_name
    if [ -n "$git_name" ]; then
      git config --global user.name "$git_name"
    fi
  fi

  if ! git config --global user.email &>/dev/null; then
    read -p "   Entrez votre email pour Git : " git_email
    if [ -n "$git_email" ]; then
      git config --global user.email "$git_email"
    fi
  fi

  echo "✅ Configuration post-installation terminée."
}

do_links() {
  echo "🔗 Création des symlinks..."

  CONFIG_DIR="$HOME/.config"
  DOTFILES="$CONFIG_DIR/dotfiles"

  # Vérifier que le dossier dotfiles existe
  if [ ! -d "$DOTFILES" ]; then
    echo "❌ Le dossier $DOTFILES n'existe pas."
    echo "⚠️  Veuillez cloner vos dotfiles dans $DOTFILES avant d'exécuter cette commande."
    exit 1
  fi

  # Créer un dossier de backup
  BACKUP_DIR="$HOME/.config/dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$BACKUP_DIR"
  echo "💾 Création d'un backup dans $BACKUP_DIR..."

  echo "🧼 Suppression des anciens fichiers de configuration..."

  # Fichiers à remplacer
  for FILE in .zshrc .tmux.conf .gitconfig .gitignore_global; do
    TARGET="$HOME/$FILE"
    if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
      echo "💾 Backup de $TARGET vers $BACKUP_DIR/"
      cp -r "$TARGET" "$BACKUP_DIR/$FILE" 2>/dev/null || true
      echo "❌ Suppression de $TARGET"
      rm -f "$TARGET"
    fi
    echo "🔗 Création du lien symbolique vers $DOTFILES/$FILE"
    ln -s "$DOTFILES/$FILE" "$TARGET"
  done

  echo "🧼 Suppression des anciens dossiers de configuration..."

  # Dossiers à remplacer
  for DIR in nvim kitty sesh cursor vscode ; do
    TARGET="$CONFIG_DIR/$DIR"
    if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
      echo "💾 Backup de $TARGET vers $BACKUP_DIR/"
      cp -r "$TARGET" "$BACKUP_DIR/$DIR" 2>/dev/null || true
      echo "❌ Suppression de $TARGET"
      rm -rf "$TARGET"
    fi
    echo "🔗 Création du lien symbolique vers $DOTFILES/$DIR"
    ln -s "$DOTFILES/$DIR" "$TARGET"
  done

  # starship.toml
  TARGET="$CONFIG_DIR/starship.toml"
  if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
    echo "💾 Backup de $TARGET vers $BACKUP_DIR/"
    cp -r "$TARGET" "$BACKUP_DIR/starship.toml" 2>/dev/null || true
    echo "❌ Suppression de $TARGET"
    rm -f "$TARGET"
  fi
  echo "🔗 Création du lien symbolique vers $DOTFILES/starship.toml"
  ln -s "$DOTFILES/starship.toml" "$TARGET"

  echo "✅ Tous les liens symboliques ont été créés avec succès."
  echo "💾 Backup disponible dans : $BACKUP_DIR"
}

do_post_install() {
  echo "⚙️ Configuration post-installation..."

  # Installation des plugins Tmux si .tmux.conf existe
  if [ -f "$HOME/.tmux.conf" ] || [ -L "$HOME/.tmux.conf" ]; then
    echo "🔌 Installation des plugins Tmux..."
    "$HOME/.tmux/plugins/tpm/bin/install_plugins" &>/dev/null || true
  fi

  # Vérifier si NVM est configuré dans .zshrc
  if [ -f "$HOME/.zshrc" ] || [ -L "$HOME/.zshrc" ]; then
    if ! grep -q "NVM_DIR" "$HOME/.zshrc" 2>/dev/null; then
      echo "📝 Ajout de la configuration NVM dans .zshrc..."
      {
        echo ""
        echo "# NVM Configuration"
        echo "export NVM_DIR=\"\$HOME/.nvm\""
        echo "[ -s \"\$(brew --prefix nvm)/nvm.sh\" ] && source \"\$(brew --prefix nvm)/nvm.sh\""
      } >> "$HOME/.zshrc"
    fi
  fi

  # Configuration Git initiale (si pas déjà configuré)
  if ! git config --global user.name &>/dev/null; then
    echo "📝 Configuration Git initiale requise..."
    read -p "   Entrez votre nom pour Git : " git_name
    if [ -n "$git_name" ]; then
      git config --global user.name "$git_name"
    fi
  fi

  if ! git config --global user.email &>/dev/null; then
    read -p "   Entrez votre email pour Git : " git_email
    if [ -n "$git_email" ]; then
      git config --global user.email "$git_email"
    fi
  fi

  echo "✅ Configuration post-installation terminée."
  echo ""
  echo "📝 Note : Certains outils nécessitent un redémarrage du terminal pour être utilisés :"
  echo "   - NVM (Node Version Manager)"
  echo "   - SDKMAN"
  echo "   - Oh My Zsh (si c'est la première installation)"
  echo ""
  echo "💡 Conseil : Fermez et rouvrez votre terminal pour que tous les changements prennent effet."
}

# Nouvelles fonctions pour les modes avancés
do_update() {
  log "INFO" "🔄 Mise à jour des outils installés..."
  
  if command -v brew &>/dev/null; then
    log "INFO" "🔄 Mise à jour de Homebrew..."
    execute "brew update"
    execute "brew upgrade"
  fi
  
  # Mise à jour des plugins Zsh
  PLUGIN_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
  if [ -d "$PLUGIN_DIR" ]; then
    log "INFO" "🔄 Mise à jour de zsh-syntax-highlighting..."
    (cd "$PLUGIN_DIR" && execute "git pull")
  fi
  
  PLUGIN_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
  if [ -d "$PLUGIN_DIR" ]; then
    log "INFO" "🔄 Mise à jour de zsh-autosuggestions..."
    (cd "$PLUGIN_DIR" && execute "git pull")
  fi
  
  # Mise à jour de TPM
  if [ -d "$HOME/.tmux/plugins/tpm" ]; then
    log "INFO" "🔄 Mise à jour de TPM..."
    (cd "$HOME/.tmux/plugins/tpm" && execute "git pull")
  fi
  
  log "INFO" "✅ Mise à jour terminée."
}

do_check() {
  log "INFO" "🔍 Vérification de l'état de l'installation..."
  
  local errors=0
  local warnings=0
  
  # Vérifier les outils essentiels
  local tools=("git" "brew" "nvim" "tmux" "zsh")
  for tool in "${tools[@]}"; do
    if command -v "$tool" &>/dev/null; then
      log "INFO" "✅ $tool est installé"
    else
      log "ERROR" "❌ $tool n'est pas installé"
      ((errors++))
    fi
  done
  
  # Vérifier les symlinks
  CONFIG_DIR="$HOME/.config"
  DOTFILES="$CONFIG_DIR/dotfiles"
  
  local files=(".zshrc" ".tmux.conf" ".gitconfig")
  for file in "${files[@]}"; do
    if [ -L "$HOME/$file" ]; then
      local target=$(readlink "$HOME/$file")
      if [[ "$target" == "$DOTFILES"* ]]; then
        log "INFO" "✅ $file est correctement lié"
      else
        log "ERROR" "❌ $file pointe vers un mauvais emplacement: $target"
        ((errors++))
      fi
    elif [ -f "$HOME/$file" ]; then
      log "WARN" "⚠️  $file existe mais n'est pas un symlink"
      ((warnings++))
    else
      log "WARN" "⚠️  $file n'existe pas"
      ((warnings++))
    fi
  done
  
  # Vérifier Git config
  if git config --global user.name &>/dev/null && git config --global user.email &>/dev/null; then
    log "INFO" "✅ Git est configuré"
  else
    log "WARN" "⚠️  Git n'est pas configuré (user.name ou user.email manquant)"
    ((warnings++))
  fi
  
  echo ""
  log "INFO" "📊 Résumé: $errors erreur(s), $warnings avertissement(s)"
  
  if [ $errors -eq 0 ]; then
    log "INFO" "✅ Tous les checks sont passés !"
    return 0
  else
    log "ERROR" "❌ Des erreurs ont été détectées"
    return 1
  fi
}

do_clean() {
  log "INFO" "🧹 Nettoyage des fichiers temporaires..."
  
  CONFIG_DIR="$HOME/.config"
  
  # Nettoyer les anciens backups (garder les 5 derniers)
  if [ -d "$CONFIG_DIR" ]; then
    local backups=($(ls -td "$CONFIG_DIR"/dotfiles-backup-* 2>/dev/null | tail -n +6))
    if [ ${#backups[@]} -gt 0 ]; then
      log "INFO" "🗑️  Suppression de ${#backups[@]} ancien(s) backup(s)..."
      for backup in "${backups[@]}"; do
        execute "rm -rf '$backup'"
        log "INFO" "   Supprimé: $backup"
      done
    else
      log "INFO" "✅ Aucun ancien backup à supprimer"
    fi
  fi
  
  # Nettoyer Homebrew
  if command -v brew &>/dev/null; then
    log "INFO" "🧹 Nettoyage de Homebrew..."
    execute "brew cleanup"
  fi
  
  log "INFO" "✅ Nettoyage terminé."
}

do_rollback() {
  local backup_dir="$1"
  CONFIG_DIR="$HOME/.config"
  
  if [ -z "$backup_dir" ]; then
    log "INFO" "📋 Backups disponibles:"
    local backups=($(ls -td "$CONFIG_DIR"/dotfiles-backup-* 2>/dev/null))
    if [ ${#backups[@]} -eq 0 ]; then
      log "ERROR" "❌ Aucun backup trouvé"
      return 1
    fi
    
    for i in "${!backups[@]}"; do
      echo "  $((i+1)). ${backups[$i]}"
    done
    
    read -p "Choisissez un backup (1-${#backups[@]}): " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#backups[@]} ]; then
      backup_dir="${backups[$((choice-1))]}"
    else
      log "ERROR" "❌ Choix invalide"
      return 1
    fi
  fi
  
  if [ ! -d "$backup_dir" ]; then
    log "ERROR" "❌ Backup introuvable: $backup_dir"
    return 1
  fi
  
  log "INFO" "🔄 Restauration depuis $backup_dir..."
  
  # Restaurer les fichiers
  for file in .zshrc .tmux.conf .gitconfig .gitignore_global; do
    if [ -f "$backup_dir/$file" ]; then
      execute "cp '$backup_dir/$file' '$HOME/$file'"
      log "INFO" "✅ Restauré: $file"
    fi
  done
  
  # Restaurer les dossiers
  for dir in nvim kitty sesh; do
    if [ -d "$backup_dir/$dir" ]; then
      execute "rm -rf '$CONFIG_DIR/$dir'"
      execute "cp -r '$backup_dir/$dir' '$CONFIG_DIR/$dir'"
      log "INFO" "✅ Restauré: $dir"
    fi
  done
  
  log "INFO" "✅ Restauration terminée."
}

do_sync() {
  log "INFO" "🔄 Synchronisation avec le dépôt distant..."
  
  CONFIG_DIR="$HOME/.config"
  DOTFILES="$CONFIG_DIR/dotfiles"
  
  if [ ! -d "$DOTFILES" ]; then
    log "ERROR" "❌ Le dossier $DOTFILES n'existe pas"
    return 1
  fi
  
  cd "$DOTFILES" || return 1
  
  if [ -d ".git" ]; then
    log "INFO" "📥 Pull des dernières modifications..."
    execute "git pull"
    
    log "INFO" "🔄 Mise à jour des symlinks si nécessaire..."
    do_links
  else
    log "ERROR" "❌ $DOTFILES n'est pas un dépôt git"
    return 1
  fi
  
  log "INFO" "✅ Synchronisation terminée."
}

# Vérification de l'argument
if [[ -z $MODE ]]; then
  echo "Usage: $0 {install|links|all|update|check|clean|rollback|sync} [options]"
  echo ""
  echo "Modes:"
  echo "  install    - Installe les outils et dépendances"
  echo "  links      - Crée les symlinks vers les dotfiles"
  echo "  all        - Exécute install et links"
  echo "  update     - Met à jour les outils déjà installés"
  echo "  check      - Vérifie l'état de l'installation"
  echo "  clean      - Nettoie les fichiers temporaires et anciens backups"
  echo "  rollback   - Restaure un backup précédent"
  echo "  sync       - Synchronise avec le dépôt distant"
  echo ""
  echo "Options:"
  echo "  --dry-run  - Simulation sans exécution"
  echo "  --log FILE - Enregistre les logs dans un fichier"
  echo "  --only TOOLS - Installe uniquement les outils spécifiés (séparés par des virgules)"
  echo "  --profile PROFILE - Utilise un profil d'installation (minimal|dev|full)"
  echo "  --verbose  - Mode verbeux"
  exit 1
fi

# Exécution
case $MODE in
  install) do_install; do_post_install ;;
  links) do_links ;;
  all) do_install; do_links; do_post_install ;;
  update) do_update ;;
  check) do_check ;;
  clean) do_clean ;;
  rollback) do_rollback "$@" ;;
  sync) do_sync ;;
  *) echo "Mode inconnu: $MODE"; exit 1 ;;
esac



echo "🎉 Script terminé avec succès."

#echo "🔄 Redémarrage de sketchybar..."
#brew services start sketchybar
#yabai --start-service
#skhd --start-service