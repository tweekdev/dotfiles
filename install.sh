#!/bin/bash
#
# Installation script for dotfiles
# Usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/tweekdev/dotfiles/master/install.sh)"
#

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║         🚀 Dotfiles Installation                 ║${NC}"
echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════╝${NC}"
echo ""

# Variables
DOTFILES_REPO="https://github.com/tweekdev/dotfiles.git"
DOTFILES_DIR="$HOME/.config/dotfiles"

# Vérifier macOS
if [[ "$(uname)" != "Darwin" ]]; then
  echo -e "${RED}❌ Ce script est uniquement pour macOS${NC}"
  exit 1
fi

# Étape 1: Xcode Command Line Tools
echo -e "${BOLD}[1/4]${NC} Xcode Command Line Tools..."
if ! xcode-select -p &>/dev/null; then
  echo -e "  ${YELLOW}→${NC} Installation en cours..."
  xcode-select --install
  echo -e "  ${YELLOW}⚠${NC} Attendez la fin de l'installation, puis relancez ce script"
  exit 0
else
  echo -e "  ${GREEN}✓${NC} Déjà installé"
fi

# Étape 2: Homebrew
echo -e "${BOLD}[2/4]${NC} Homebrew..."
if ! command -v brew &>/dev/null; then
  echo -e "  ${YELLOW}→${NC} Installation en cours..."
  echo -e "  ${YELLOW}⚠${NC} Appuyez sur ENTER quand demandé, puis entrez votre mot de passe"
  echo ""
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  
  # Ajouter Homebrew au PATH pour cette session
  if [[ -f "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  echo -e "  ${GREEN}✓${NC} Homebrew installé"
else
  echo -e "  ${GREEN}✓${NC} Déjà installé"
fi

# Étape 3: Cloner les dotfiles
echo -e "${BOLD}[3/4]${NC} Clonage des dotfiles..."
if [[ -d "$DOTFILES_DIR" ]]; then
  echo -e "  ${GREEN}✓${NC} Déjà présent dans $DOTFILES_DIR"
  cd "$DOTFILES_DIR"
  git pull --quiet
else
  echo -e "  ${YELLOW}→${NC} Clonage depuis $DOTFILES_REPO..."
  mkdir -p "$(dirname "$DOTFILES_DIR")"
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  cd "$DOTFILES_DIR"
fi

# Étape 4: Lancer setup.sh
echo -e "${BOLD}[4/4]${NC} Installation..."
chmod +x setup.sh
./setup.sh all

echo ""
echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${GREEN}  ✅ Installation terminée !${NC}"
echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${YELLOW}💡 IMPORTANT: Fermez et rouvrez votre terminal${NC}"
echo -e "  ${YELLOW}   puis lancez 'nvim' pour installer les plugins Neovim${NC}"
echo ""
