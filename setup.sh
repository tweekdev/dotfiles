#!/bin/bash

MODE=$1
shift || true

# ============================================
# Variables globales
# ============================================
DRY_RUN=false
LOG_FILE=""
VERBOSE=false
CONFIG_DIR="$HOME/.config"
DOTFILES="$CONFIG_DIR/dotfiles"
BREWFILE="$DOTFILES/Brewfile"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ============================================
# Parse des arguments
# ============================================
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
  --verbose | -v)
    VERBOSE=true
    shift
    ;;
  *)
    echo -e "${RED}Option inconnue: $1${NC}"
    exit 1
    ;;
  esac
done

if [ "$DRY_RUN" = false ]; then
  set -e # Stop on error
else
  set +e # Ne pas s'arrêter en dry-run
fi

# ============================================
# Fonctions utilitaires
# ============================================

# Affiche un header de section
section() {
  echo ""
  echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${BLUE}  $1${NC}"
  echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Log avec niveau
log() {
  local level=$1
  shift
  local message="$*"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  # Log dans fichier si spécifié
  if [ -n "$LOG_FILE" ]; then
    echo "[$timestamp] [$level] $message" >>"$LOG_FILE"
  fi

  # Affichage console
  case $level in
    SUCCESS) echo -e "  ${GREEN}✓${NC} $message" ;;
    ERROR)   echo -e "  ${RED}✗${NC} $message" ;;
    WARN)    echo -e "  ${YELLOW}⚠${NC} $message" ;;
    INFO)    echo -e "  ${CYAN}→${NC} $message" ;;
    SKIP)    echo -e "  ${GRAY}○${NC} ${GRAY}$message${NC}" ;;
    DRY)     echo -e "  ${PURPLE}◇${NC} ${PURPLE}[dry-run]${NC} $message" ;;
    DEBUG)   [ "$VERBOSE" = true ] && echo -e "  ${GRAY}  $message${NC}" ;;
  esac
}

# Fonction pour exécuter une commande (respecte dry-run)
run_cmd() {
  if [ "$DRY_RUN" = true ]; then
    log "DRY" "$*"
    return 0
  else
    "$@"
  fi
}

# Fonction pour vérifier la connexion internet
check_internet() {
  if ! ping -c 1 -W 2 8.8.8.8 &>/dev/null && ! ping -c 1 -W 2 1.1.1.1 &>/dev/null; then
    log "ERROR" "Pas de connexion internet détectée"
    log "WARN" "Le script nécessite une connexion internet pour fonctionner"
    exit 1
  fi
  log "SUCCESS" "Connexion internet OK"
}

# Fonction pour vérifier l'architecture
check_architecture() {
  local arch
  arch=$(uname -m)
  if [ "$arch" != "arm64" ]; then
    log "WARN" "Ce script est optimisé pour Apple Silicon (arm64)"
    log "INFO" "Architecture détectée : $arch"
    if [ "$DRY_RUN" = false ]; then
      read -p "   Voulez-vous continuer quand même ? (y/N) " -n 1 -r
      echo
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
      fi
    fi
  else
    log "SUCCESS" "Architecture Apple Silicon (arm64)"
  fi
}

do_install() {
  section "🚀 Installation"
  
  if [ "$DRY_RUN" = true ]; then
    echo -e "  ${PURPLE}Mode simulation activé${NC}"
  fi

  # Vérifications préliminaires
  section "🔍 Vérifications"
  check_internet
  check_architecture

  cd "$HOME" || exit

  # Prérequis
  section "📋 Prérequis"
  
  # Git
  if ! command -v git &>/dev/null; then
    log "ERROR" "Git n'est pas installé"
    echo ""
    echo -e "  ${YELLOW}Pour installer Git :${NC}"
    echo -e "    xcode-select --install"
    echo ""
    exit 1
  else
    log "SUCCESS" "Git $(git --version | cut -d' ' -f3)"
  fi

  # Homebrew
  if ! command -v brew &>/dev/null; then
    log "INFO" "Installation de Homebrew..."
    run_cmd /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    log "SUCCESS" "Homebrew installé"
    log "INFO" "Mise à jour de Homebrew..."
    run_cmd brew update
  fi

  # Rosetta 2
  if /usr/bin/pgrep -q oahd &>/dev/null; then
    log "SUCCESS" "Rosetta 2 installé"
  else
    log "INFO" "Installation de Rosetta 2..."
    run_cmd softwareupdate --install-rosetta --agree-to-license || true
  fi

  # Brewfile
  section "📦 Packages (Brewfile)"
  if [ -f "$BREWFILE" ]; then
    log "INFO" "Installation via Brewfile..."
    run_cmd brew bundle --file="$BREWFILE"
    log "SUCCESS" "Brewfile appliqué"
  else
    log "ERROR" "Brewfile non trouvé: $BREWFILE"
    exit 1
  fi

  # Installations spéciales
  section "🔧 Outils supplémentaires"

  # Cursor
  if [ ! -d "/Applications/Cursor.app" ]; then
    log "INFO" "Installation de Cursor..."
    if [ "$DRY_RUN" = true ]; then
      log "DRY" "curl https://cursor.com/install -fsS | bash"
    else
      curl https://cursor.com/install -fsS | bash
      log "SUCCESS" "Cursor installé"
    fi
  else
    log "SUCCESS" "Cursor"
  fi

  # Docker
  #if ! command -v docker &>/dev/null && [ ! -d "/Applications/Docker.app" ]; then
  #  log "WARN" "Docker non installé"
  #  echo -e "    ${GRAY}→ https://www.docker.com/products/docker-desktop/${NC}"
  #else
  #  log "SUCCESS" "Docker"
  #fi

  # NVM + Node.js
  export NVM_DIR="$HOME/.nvm"
  run_cmd mkdir -p "$NVM_DIR"
  if [ "$DRY_RUN" = true ]; then
    log "DRY" "nvm install --lts && nvm alias default node"
  elif [ -s "$(brew --prefix nvm)/nvm.sh" ]; then
    source "$(brew --prefix nvm)/nvm.sh"
    if ! nvm list 2>/dev/null | grep -q "default"; then
      log "INFO" "Installation de Node.js LTS..."
      nvm install --lts
      nvm use --lts
      nvm alias default node
      log "SUCCESS" "Node.js LTS installé"
    else
      log "SUCCESS" "Node.js $(node --version 2>/dev/null || echo 'installé')"
    fi
  else
    log "WARN" "NVM non disponible (vérifiez le Brewfile)"
  fi

  # Yarn
  if [ "$DRY_RUN" = true ]; then
    log "DRY" "npm install -g yarn"
  elif command -v npm &>/dev/null && ! command -v yarn &>/dev/null; then
    log "INFO" "Installation de Yarn..."
    npm install -g yarn
    log "SUCCESS" "Yarn installé"
  else
    log "SUCCESS" "Yarn $(yarn --version 2>/dev/null || echo 'installé')"
  fi

  # TypeScript
  if [ "$DRY_RUN" = true ]; then
    log "DRY" "npm install -g typescript"
  elif command -v npm &>/dev/null; then
    if ! npm list -g typescript &>/dev/null 2>&1; then
      log "INFO" "Installation de TypeScript..."
      npm install -g typescript
      log "SUCCESS" "TypeScript installé"
    else
      log "SUCCESS" "TypeScript $(tsc --version 2>/dev/null | cut -d' ' -f2 || echo 'installé')"
    fi
  fi

  # SDKMAN
  if [ ! -d "$HOME/.sdkman" ]; then
    log "INFO" "Installation de SDKMAN..."
    if [ "$DRY_RUN" = true ]; then
      log "DRY" "curl -s https://get.sdkman.io | bash"
      log "DRY" "sdk install java 17.0.10-tem"
      log "DRY" "sdk install scala 2.13.11"
      log "DRY" "sdk install sbt"
    else
      curl -s "https://get.sdkman.io" | bash
      if [ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
        source "$HOME/.sdkman/bin/sdkman-init.sh"
        sdk install java 17.0.10-tem
        sdk install scala 2.13.11
        sdk install sbt
      fi
      log "SUCCESS" "SDKMAN + Java/Scala/SBT installés"
    fi
  else
    log "SUCCESS" "SDKMAN"
  fi

  # Shell
  section "🐚 Shell (Oh My Zsh)"
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log "INFO" "Installation de Oh My Zsh..."
    if [ "$DRY_RUN" = true ]; then
      log "DRY" "Installation Oh My Zsh"
    else
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
      log "SUCCESS" "Oh My Zsh installé"
    fi
  else
    log "SUCCESS" "Oh My Zsh"
  fi

  # Plugin zsh-syntax-highlighting
  PLUGIN_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
  if [ ! -d "$PLUGIN_DIR" ]; then
    log "INFO" "Installation zsh-syntax-highlighting..."
    run_cmd git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$PLUGIN_DIR"
  else
    log "SUCCESS" "zsh-syntax-highlighting"
  fi

  # Plugin zsh-autosuggestions
  PLUGIN_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
  if [ ! -d "$PLUGIN_DIR" ]; then
    log "INFO" "Installation zsh-autosuggestions..."
    run_cmd git clone https://github.com/zsh-users/zsh-autosuggestions "$PLUGIN_DIR"
  else
    log "SUCCESS" "zsh-autosuggestions"
  fi

  # Tmux
  section "🖥️  Tmux"
  if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    log "INFO" "Installation de TPM..."
    run_cmd git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  else
    log "SUCCESS" "Tmux Plugin Manager (TPM)"
  fi
}

do_links() {
  section "🔗 Symlinks"

  # Vérifier que le dossier dotfiles existe
  if [ ! -d "$DOTFILES" ]; then
    log "ERROR" "Le dossier $DOTFILES n'existe pas"
    log "WARN" "Clonez vos dotfiles dans $DOTFILES avant d'exécuter cette commande"
    exit 1
  fi

  # Créer un dossier de backup
  BACKUP_DIR="$HOME/.config/dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
  if [ "$DRY_RUN" = true ]; then
    log "DRY" "mkdir -p $BACKUP_DIR"
  else
    mkdir -p "$BACKUP_DIR"
    log "INFO" "Backup → ${GRAY}$BACKUP_DIR${NC}"
  fi

  echo ""
  echo -e "  ${BOLD}Fichiers :${NC}"
  # Fichiers à remplacer
  for FILE in .zshrc .tmux.conf .gitconfig .gitignore_global .aerospace.toml; do
    TARGET="$HOME/$FILE"
    if [ "$DRY_RUN" = true ]; then
      log "DRY" "$FILE → ~/$FILE"
    else
      if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
        cp -r "$TARGET" "$BACKUP_DIR/$FILE" 2>/dev/null || true
        rm -f "$TARGET"
      fi
      ln -s "$DOTFILES/$FILE" "$TARGET"
      log "SUCCESS" "$FILE"
    fi
  done

  echo ""
  echo -e "  ${BOLD}Dossiers :${NC}"
  # Dossiers à remplacer
  for DIR in nvim sesh git ghostty; do
    TARGET="$CONFIG_DIR/$DIR"
    if [ "$DRY_RUN" = true ]; then
      log "DRY" "$DIR/ → ~/.config/$DIR"
    else
      if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
        cp -r "$TARGET" "$BACKUP_DIR/$DIR" 2>/dev/null || true
        rm -rf "$TARGET"
      fi
      ln -s "$DOTFILES/$DIR" "$TARGET"
      log "SUCCESS" "$DIR/"
    fi
  done

  # starship.toml
  TARGET="$CONFIG_DIR/starship.toml"
  if [ "$DRY_RUN" = true ]; then
    log "DRY" "starship.toml → ~/.config/starship.toml"
  else
    if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
      cp -r "$TARGET" "$BACKUP_DIR/starship.toml" 2>/dev/null || true
      rm -f "$TARGET"
    fi
    ln -s "$DOTFILES/starship.toml" "$TARGET"
    log "SUCCESS" "starship.toml"
  fi

  # Wallpapers
  echo ""
  echo -e "  ${BOLD}Wallpapers :${NC}"
  WALLPAPERS_SRC="$DOTFILES/wallpapers"
  WALLPAPERS_DST="$HOME/Pictures/Wallpapers"
  if [ -d "$WALLPAPERS_SRC" ]; then
    if [ "$DRY_RUN" = true ]; then
      log "DRY" "wallpapers/ → ~/Pictures/Wallpapers/"
    else
      mkdir -p "$WALLPAPERS_DST"
      cp -r "$WALLPAPERS_SRC/"* "$WALLPAPERS_DST/" 2>/dev/null || true
      count=$(ls -1 "$WALLPAPERS_DST" 2>/dev/null | wc -l | tr -d ' ')
      log "SUCCESS" "$count wallpapers copiés"
    fi
  else
    log "SKIP" "Pas de dossier wallpapers"
  fi

  # Dossier Developer
  echo ""
  echo -e "  ${BOLD}Developer :${NC}"
  DEVELOPER_DIR="$HOME/Developer"
  if [ "$DRY_RUN" = true ]; then
    log "DRY" "mkdir ~/Developer"
  else
    if [ -d "$DEVELOPER_DIR" ]; then
      log "SKIP" "~/Developer existe déjà"
    else
      mkdir -p "$DEVELOPER_DIR"
      log "SUCCESS" "~/Developer créé"
    fi
  fi
}

do_post_install() {
  section "⚙️  Post-installation"

  # Installation des plugins Tmux
  if [ -f "$HOME/.tmux.conf" ] || [ -L "$HOME/.tmux.conf" ]; then
    log "INFO" "Installation des plugins Tmux..."
    "$HOME/.tmux/plugins/tpm/bin/install_plugins" &>/dev/null || true
    log "SUCCESS" "Plugins Tmux installés"
  fi

  # Configuration Git (si pas déjà configuré)
  if ! git config --global user.name &>/dev/null; then
    echo ""
    log "WARN" "Configuration Git requise"
    read -p "    Nom pour Git : " git_name
    [ -n "$git_name" ] && git config --global user.name "$git_name"
  fi

  if ! git config --global user.email &>/dev/null; then
    read -p "    Email pour Git : " git_email
    [ -n "$git_email" ] && git config --global user.email "$git_email"
  fi

  echo ""
  echo -e "  ${YELLOW}💡 Redémarrez votre terminal pour appliquer les changements${NC}"
}

do_update() {
  section "🔄 Mise à jour"

  # Homebrew
  if command -v brew &>/dev/null; then
    log "INFO" "Homebrew..."
    brew update && brew upgrade
    log "SUCCESS" "Homebrew à jour"
  fi

  # NVM + Node.js
  export NVM_DIR="$HOME/.nvm"
  if [ -s "$(brew --prefix nvm)/nvm.sh" ]; then
    source "$(brew --prefix nvm)/nvm.sh"
    log "INFO" "Node.js LTS..."
    nvm install --lts --reinstall-packages-from=current 2>/dev/null || true
    log "SUCCESS" "Node.js à jour"
  fi

  # npm global packages
  if command -v npm &>/dev/null; then
    log "INFO" "Packages npm globaux..."
    npm update -g 2>/dev/null || true
    log "SUCCESS" "npm à jour"
  fi

  # SDKMAN
  if [ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    log "INFO" "SDKMAN..."
    sdk selfupdate 2>/dev/null || true
    log "SUCCESS" "SDKMAN à jour"
  fi

  # Plugins Zsh
  for plugin in zsh-syntax-highlighting zsh-autosuggestions; do
    PLUGIN_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin"
    if [ -d "$PLUGIN_DIR" ]; then
      log "INFO" "$plugin..."
      (cd "$PLUGIN_DIR" && git pull --quiet)
      log "SUCCESS" "$plugin à jour"
    fi
  done

  # TPM
  if [ -d "$HOME/.tmux/plugins/tpm" ]; then
    log "INFO" "TPM..."
    (cd "$HOME/.tmux/plugins/tpm" && git pull --quiet)
    log "SUCCESS" "TPM à jour"
  fi
}

do_check() {
  section "🔍 Vérification"

  local errors=0
  local warnings=0

  echo ""
  echo -e "  ${BOLD}Outils :${NC}"
  for tool in git brew nvim tmux zsh fzf; do
    if command -v "$tool" &>/dev/null; then
      local version=$($tool --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
      log "SUCCESS" "$tool ${GRAY}${version}${NC}"
    else
      log "ERROR" "$tool manquant"
      ((errors++))
    fi
  done

  echo ""
  echo -e "  ${BOLD}Symlinks :${NC}"
  for file in .zshrc .tmux.conf .gitconfig; do
    if [ -L "$HOME/$file" ]; then
      log "SUCCESS" "$file"
    elif [ -f "$HOME/$file" ]; then
      log "WARN" "$file (pas un symlink)"
      ((warnings++))
    else
      log "ERROR" "$file manquant"
      ((errors++))
    fi
  done

  echo ""
  echo -e "  ${BOLD}Brewfile :${NC}"
  if [ -f "$DOTFILES/Brewfile" ]; then
    log "SUCCESS" "Brewfile présent"
    if brew bundle check --file="$DOTFILES/Brewfile" &>/dev/null; then
      log "SUCCESS" "Toutes les dépendances installées"
    else
      log "WARN" "Dépendances manquantes (brew bundle install)"
      ((warnings++))
    fi
  else
    log "ERROR" "Brewfile manquant"
    ((errors++))
  fi

  # Résumé
  echo ""
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  if [ $errors -eq 0 ] && [ $warnings -eq 0 ]; then
    echo -e "  ${GREEN}${BOLD}✓ Tout est OK${NC}"
  else
    echo -e "  ${RED}$errors erreur(s)${NC}, ${YELLOW}$warnings avertissement(s)${NC}"
  fi
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  
  [ $errors -eq 0 ] && return 0 || return 1
}

do_clean() {
  section "🧹 Nettoyage"

  # Anciens backups (garder les 5 derniers)
  local backups=($(ls -td "$CONFIG_DIR"/dotfiles-backup-* 2>/dev/null | tail -n +6))
  if [ ${#backups[@]} -gt 0 ]; then
    log "INFO" "Suppression de ${#backups[@]} ancien(s) backup(s)..."
    for backup in "${backups[@]}"; do
      rm -rf "$backup"
      log "SUCCESS" "Supprimé: $(basename $backup)"
    done
  else
    log "SKIP" "Pas de backup à supprimer"
  fi

  # Homebrew cleanup
  if command -v brew &>/dev/null; then
    log "INFO" "Nettoyage Homebrew..."
    brew cleanup
    log "SUCCESS" "Homebrew nettoyé"
  fi
}

do_rollback() {
  section "⏪ Rollback"

  local backups=($(ls -td "$CONFIG_DIR"/dotfiles-backup-* 2>/dev/null))
  if [ ${#backups[@]} -eq 0 ]; then
    log "ERROR" "Aucun backup trouvé"
    return 1
  fi

  echo ""
  echo -e "  ${BOLD}Backups disponibles :${NC}"
  for i in "${!backups[@]}"; do
    echo -e "    ${CYAN}$((i + 1))${NC}. $(basename ${backups[$i]})"
  done
  echo ""

  read -p "  Choisissez (1-${#backups[@]}): " choice
  if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#backups[@]} ]; then
    local backup_dir="${backups[$((choice - 1))]}"
    
    log "INFO" "Restauration depuis $(basename $backup_dir)..."
    
    for file in .zshrc .tmux.conf .gitconfig .gitignore_global; do
      if [ -f "$backup_dir/$file" ]; then
        cp "$backup_dir/$file" "$HOME/$file"
        log "SUCCESS" "$file"
      fi
    done
    
    for dir in nvim sesh git ghostty; do
      if [ -d "$backup_dir/$dir" ]; then
        rm -rf "$CONFIG_DIR/$dir"
        cp -r "$backup_dir/$dir" "$CONFIG_DIR/$dir"
        log "SUCCESS" "$dir/"
      fi
    done
  else
    log "ERROR" "Choix invalide"
    return 1
  fi
}

do_sync() {
  section "🔄 Synchronisation"

  if [ ! -d "$DOTFILES/.git" ]; then
    log "ERROR" "$DOTFILES n'est pas un dépôt git"
    return 1
  fi

  cd "$DOTFILES" || return 1
  
  log "INFO" "Pull des modifications..."
  git pull
  log "SUCCESS" "Repository à jour"
  
  do_links
}

# ============================================
# Main
# ============================================
show_help() {
  echo ""
  echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${BLUE}║           🛠️  Dotfiles Setup Script              ║${NC}"
  echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "${BOLD}Usage:${NC} $0 <mode> [options]"
  echo ""
  echo -e "${BOLD}Modes:${NC}"
  echo -e "  ${CYAN}install${NC}    Installe tout via Brewfile + dépendances"
  echo -e "  ${CYAN}links${NC}      Crée les symlinks vers les dotfiles"
  echo -e "  ${CYAN}all${NC}        install + links (installation complète)"
  echo -e "  ${CYAN}update${NC}     Met à jour Homebrew, npm, plugins..."
  echo -e "  ${CYAN}check${NC}      Vérifie l'état de l'installation"
  echo -e "  ${CYAN}clean${NC}      Nettoie les anciens backups"
  echo -e "  ${CYAN}rollback${NC}   Restaure un backup précédent"
  echo -e "  ${CYAN}sync${NC}       Pull git + met à jour les symlinks"
  echo ""
  echo -e "${BOLD}Options:${NC}"
  echo -e "  ${YELLOW}--dry-run${NC}  Simulation sans exécution"
  echo -e "  ${YELLOW}--log${NC} FILE Enregistre les logs dans un fichier"
  echo -e "  ${YELLOW}--verbose${NC}  Mode verbeux (affiche les détails)"
  echo ""
  echo -e "${BOLD}Exemples:${NC}"
  echo -e "  ${GRAY}$0 all${NC}              # Installation complète"
  echo -e "  ${GRAY}$0 install --dry-run${NC} # Simulation d'installation"
  echo -e "  ${GRAY}$0 check${NC}            # Vérifier l'état"
  echo ""
}

if [[ -z $MODE ]]; then
  show_help
  exit 1
fi

# Header
echo ""
echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║           🛠️  Dotfiles Setup Script              ║${NC}"
echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════╝${NC}"

case $MODE in
  install)
    do_install
    do_post_install
    ;;
  links)
    do_links
    ;;
  all)
    do_install
    do_links
    do_post_install
    ;;
  update)
    do_update
    ;;
  check)
    do_check
    ;;
  clean)
    do_clean
    ;;
  rollback)
    do_rollback
    ;;
  sync)
    do_sync
    ;;
  *)
    echo -e "${RED}Mode inconnu: $MODE${NC}"
    show_help
    exit 1
    ;;
esac

# Footer
echo ""
echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${GREEN}  ✅ Terminé !${NC}"
echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
