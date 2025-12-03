#!/bin/bash

MODE=$1

set -e  # Stop on error

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
    read -p "   Voulez-vous continuer quand même ? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      exit 1
    fi
  fi
}

do_install() {
  echo "📦 Début de l'installation..."

  # Vérifications préliminaires
  check_internet
  check_architecture

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

  # Vérifie si les outils de développement sont installés
  # Utilise brew list pour vérifier l'installation (plus fiable que command -v)
  for tool in neovim tmux fzf bat git zsh eza zoxide gh lazygit starship ripgrep git-flow-avh gnu-tar postgresql pigz diff-so-fancy sesh; do
    if ! brew list "$tool" &>/dev/null; then
      echo "🔨 Installation de $tool..."
      brew install "$tool"
    else
      echo "✅ $tool est déjà installé."
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

  echo "✅ Installation terminée."
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
  for FILE in .zshrc .tmux.conf .gitconfig .gitignore_global .z; do
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
  for DIR in nvim kitty sesh ; do
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

# Vérification de l'argument
if [[ -z $MODE ]]; then
  echo "Usage: $0 {install|links|all}"
  exit 1
fi

# Exécution
case $MODE in
  install) do_install; do_post_install ;;
  links) do_links ;;
  all) do_install; do_links; do_post_install ;;
  *) echo "Usage: $0 {install|links|all}"; exit 1 ;;
esac



echo "🎉 Script terminé avec succès."

#echo "🔄 Redémarrage de sketchybar..."
#brew services start sketchybar
#yabai --start-service
#skhd --start-service