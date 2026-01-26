#!/bin/bash
#
# macOS Defaults - Configure system preferences
# Run: ./macos-defaults.sh [--dry-run]
#
# Testé sur: macOS Sequoia (15) / Tahoe (26)
# Source: https://macos-defaults.com/
#

set -e

# Mode dry-run ou check
DRY_RUN=false
CHECK_MODE=false
[[ "$1" == "--dry-run" || "$1" == "-n" ]] && DRY_RUN=true
[[ "$1" == "--check" || "$1" == "-c" ]] && CHECK_MODE=true

# Afficher l'aide
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  echo "Usage: ./macos-defaults.sh [option]"
  echo ""
  echo "Options:"
  echo "  (aucune)     Appliquer les préférences"
  echo "  --dry-run    Simuler sans appliquer"
  echo "  --check      Afficher les valeurs actuelles"
  echo "  --help       Afficher cette aide"
  exit 0
fi

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Fonction pour exécuter ou afficher les commandes
run() {
  if $DRY_RUN; then
    echo -e "  ${PURPLE}◇${NC} [dry-run] $*"
  else
    "$@"
  fi
}

# Fonction pour lire une valeur defaults
read_default() {
  local domain="$1"
  local key="$2"
  local value
  value=$(defaults read "$domain" "$key" 2>/dev/null) || value="${RED}non défini${NC}"
  echo -e "  $key = ${GREEN}$value${NC}"
}

# Mode check : afficher les valeurs actuelles
if $CHECK_MODE; then
  echo -e "${BLUE}📋 Valeurs actuelles des préférences macOS${NC}"
  echo ""
  
  echo -e "${YELLOW}[Finder]${NC}"
  read_default com.apple.finder AppleShowAllFiles
  read_default NSGlobalDomain AppleShowAllExtensions
  read_default com.apple.finder ShowPathbar
  read_default com.apple.finder ShowStatusBar
  read_default com.apple.finder FXPreferredViewStyle
  read_default com.apple.finder _FXSortFoldersFirst
  read_default com.apple.desktopservices DSDontWriteNetworkStores
  
  echo -e "\n${YELLOW}[Dock]${NC}"
  read_default com.apple.dock autohide
  read_default com.apple.dock autohide-delay
  read_default com.apple.dock autohide-time-modifier
  read_default com.apple.dock tilesize
  read_default com.apple.dock magnification
  read_default com.apple.dock show-recents
  read_default com.apple.dock mru-spaces
  
  echo -e "\n${YELLOW}[Screenshots]${NC}"
  read_default com.apple.screencapture location
  read_default com.apple.screencapture type
  read_default com.apple.screencapture disable-shadow
  
  echo -e "\n${YELLOW}[Time Machine]${NC}"
  read_default com.apple.TimeMachine DoNotOfferNewDisksForBackup
  
  echo ""
  exit 0
fi

echo -e "${BLUE}⚙️  Configuration des préférences macOS...${NC}"
$DRY_RUN && echo -e "  ${PURPLE}Mode simulation activé${NC}"
echo ""

if ! $DRY_RUN; then
  # Demander le mot de passe admin une seule fois
  sudo -v

  # Keep-alive: update existing sudo timestamp until script finishes
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
fi

###############################################################################
# Finder                                                                      #
###############################################################################

echo -e "  ${YELLOW}→${NC} Finder..."

# Afficher les fichiers cachés
run defaults write com.apple.finder AppleShowAllFiles -bool true

# Afficher les extensions de fichiers
run defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Afficher la barre de chemin
run defaults write com.apple.finder ShowPathbar -bool true

# Afficher la barre de statut
run defaults write com.apple.finder ShowStatusBar -bool true

# Rechercher dans le dossier courant par défaut
run defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Désactiver l'avertissement lors du changement d'extension
run defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Éviter la création de .DS_Store sur les volumes réseau et USB
run defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
run defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Utiliser la vue liste par défaut (codes: Nlsv, icnv, clmv, glyv)
run defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Garder les dossiers en haut lors du tri par nom
run defaults write com.apple.finder _FXSortFoldersFirst -bool true
run defaults write com.apple.finder _FXSortFoldersFirstOnDesktop -bool true

# Afficher le dossier ~/Library
run chflags nohidden ~/Library

# Afficher le dossier /Volumes
if ! $DRY_RUN; then
  sudo chflags nohidden /Volumes
else
  echo -e "  ${PURPLE}◇${NC} [dry-run] sudo chflags nohidden /Volumes"
fi

###############################################################################
# Dock                                                                        #
###############################################################################

echo -e "  ${YELLOW}→${NC} Dock..."

# Activer le masquage automatique du Dock
run defaults write com.apple.dock autohide -bool true

# Supprimer le délai de masquage automatique
run defaults write com.apple.dock autohide-delay -float 0

# Accélérer l'animation de masquage
run defaults write com.apple.dock autohide-time-modifier -float 0.3

# Définir la taille des icônes
run defaults write com.apple.dock tilesize -int 48

# Minimiser les fenêtres dans l'icône de l'application
run defaults write com.apple.dock minimize-to-application -bool true

# Activer l'effet de grossissement
run defaults write com.apple.dock magnification -bool true
run defaults write com.apple.dock largesize -int 64

# Ne pas afficher les applications récentes
run defaults write com.apple.dock show-recents -bool false

# Accélérer les animations Mission Control
run defaults write com.apple.dock expose-animation-duration -float 0.1

###############################################################################
# Mission Control                                                             #
###############################################################################

echo -e "  ${YELLOW}→${NC} Mission Control..."

# Ne pas réorganiser les Spaces automatiquement selon l'utilisation
run defaults write com.apple.dock mru-spaces -bool false

# Grouper les fenêtres par application
run defaults write com.apple.dock expose-group-apps -bool true

###############################################################################
# Safari (nécessite de fermer Safari d'abord)                                 #
###############################################################################

echo -e "  ${YELLOW}→${NC} Safari..."

# Note: Safari est sandboxé, ces commandes peuvent échouer
# Activer le menu Développeur (via Safari > Settings > Advanced > Show Develop menu)
# Afficher l'URL complète (via Safari > Settings > Advanced > Show full website address)

# Alternative: ouvrir les préférences Safari manuellement
if ! $DRY_RUN; then
  echo -e "  ${YELLOW}⚠${NC}  Safari sandboxé - configurer manuellement:"
  echo -e "      Settings > Advanced > Show Develop menu"
  echo -e "      Settings > Advanced > Show full website address"
else
  echo -e "  ${PURPLE}◇${NC} [dry-run] Safari sandboxé - config manuelle requise"
fi

###############################################################################
# Screenshots                                                                 #
###############################################################################

echo -e "  ${YELLOW}→${NC} Screenshots..."

# Sauvegarder les captures dans ~/Pictures/Screenshots
run mkdir -p ~/Pictures/Screenshots
run defaults write com.apple.screencapture location -string "${HOME}/Pictures/Screenshots"

# Format PNG
run defaults write com.apple.screencapture type -string "png"

# Désactiver les ombres dans les captures
run defaults write com.apple.screencapture disable-shadow -bool true

###############################################################################
# Time Machine                                                                #
###############################################################################

echo -e "  ${YELLOW}→${NC} Time Machine..."

# Ne pas proposer les nouveaux disques pour Time Machine
run defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

###############################################################################
# Redémarrer les applications affectées                                       #
###############################################################################

echo ""
if ! $DRY_RUN; then
  echo -e "${BLUE}🔄 Redémarrage des applications...${NC}"
  for app in "Dock" "Finder" "Safari" "SystemUIServer"; do
    killall "${app}" &> /dev/null || true
  done
else
  echo -e "  ${PURPLE}◇${NC} [dry-run] killall Dock Finder Safari SystemUIServer"
fi

echo ""
echo -e "${GREEN}✅ Configuration macOS terminée !${NC}"
echo ""
echo -e "${YELLOW}⚠️  Certains changements nécessitent un redémarrage pour prendre effet.${NC}"
echo ""
