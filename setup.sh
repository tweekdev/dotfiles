#!/bin/bash

MODE=$1

set -e  # Stop on error

do_install() {
  echo "📦 Début de l'installation..."

  # Assurez-vous que le script s'exécute depuis le répertoire ~
  cd ~ || exit

  # Vérifie si Homebrew est installé
  if ! command -v brew &>/dev/null; then
    echo "🍺 Installation de Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    echo "✅ Homebrew déjà installé."
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
    echo "🐳 Téléchargement de Docker Desktop ARM64..."
    cd ~/Downloads
    curl -L -o Docker.dmg "https://desktop.docker.com/mac/main/arm64/Docker.dmg?utm_source=docker&utm_medium=webreferral&utm_campaign=docs-driven-download-mac-arm64"
  else
    echo "✅ Docker est déjà installé."
  fi

  # Vérifie si NVM est installé
  if ! command -v nvm &>/dev/null; then
    echo "🧱 Installation de NVM et Node.js (LTS)..."
    brew install nvm
    export NVM_DIR="$HOME/.nvm"
    mkdir -p "$NVM_DIR"
    source "$(brew --prefix nvm)/nvm.sh"
    nvm install --lts
    nvm use --lts
  else
    echo "✅ NVM est déjà installé."
  fi

  # Vérifie si Yarn est installé
  if ! command -v yarn &>/dev/null; then
    echo "📦 Installation de Yarn..."
    npm install -g yarn
  else
    echo "✅ Yarn est déjà installé."
  fi

  # install cursor agent
  if ! command -v cursor &>/dev/null; then
    echo "📦 Installation de Cursor..."
    curl https://cursor.com/install -fsS | bash
    cursor --version
  else
    echo "✅ Cursor est déjà installé."
  fi

  # Vérifie si TypeScript est installé
  if ! npm list -g typescript &>/dev/null; then
    echo "📦 Installation de TypeScript..."
    npm install typescript --save-dev
  else
    echo "✅ TypeScript est déjà installé."
  fi

  # Vérifie si les outils de développement sont installés
  for tool in zen-browser neovim tmux fzf bat git zsh eza zoxide gh lazygit coursier starship ripgrep git-flow-avh gnu-tar postgresql pigz; do
    if ! command -v $tool &>/dev/null; then
      echo "🔨 Installation de $tool..."
      brew install $tool
    else
      echo "✅ $tool est déjà installé."
    fi
  done

  # Vérifie si Google Cloud SDK est installé
  if ! command -v gcloud &>/dev/null; then
    echo "☁️ Installation de Google Cloud SDK..."
    brew install awscli
    brew install --cask google-cloud-sdk
  else
    echo "✅ Google Cloud SDK est déjà installé."
  fi

  # verifier si slack est installe
  if ! command -v slack &>/dev/null; then
    if [ ! -d "/Applications/Slack.app" ]; then
      echo "🚀 Installation de slack..."
      brew install --cask slack
    fi
  else
    echo "✅ Slack est déjà installé."
  fi

  # verifier si ghostty terminal est installe
  if ! command -v ghostty &>/dev/null; then
    if [ ! -d "/Applications/Ghostty.app" ]; then
      echo "🚀 Installation de ghostty..."
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

  # Vérifie si sdkman est installé
  if ! command -v sdk &>/dev/null || [ ! -d "$HOME/.sdkman" ]; then
      echo "📦 Installation de SDKMAN..."
      curl -s "https://get.sdkman.io" | bash
      source "$HOME/.sdkman/bin/sdkman-init.sh"
      sdk version
      sdk install java 17.0.10-tem
      sdk install scala 2.13.11 
      sdk install sbt
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
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  else
    echo "✅ Oh My Zsh est déjà installé."
  fi

  # Installation des plugins Zsh
  echo "🧩 Installation des plugins Zsh..."
  
  # Vérifie si le plugin zsh-syntax-highlighting existe déjà et s'il est vide
  PLUGIN_DIR="${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
  if [ ! -d "$PLUGIN_DIR" ]; then
    echo "🔽 Installation du plugin zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$PLUGIN_DIR"
  else
    echo "✅ Plugin zsh-syntax-highlighting déjà installé."
  fi

  # Vérifie si le plugin zsh-autosuggestions existe déjà et s'il est vide
  PLUGIN_DIR="${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
  if [ ! -d "$PLUGIN_DIR" ]; then
    echo "🔽 Installation du plugin zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$PLUGIN_DIR"
  else
    echo "✅ Plugin zsh-autosuggestions déjà installé."
  fi

  # Vérifie si Kitty est installé
  if ! command -v kitty &>/dev/null; then
    echo "🐱 Installation de Kitty terminal..."
    curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
  else
    echo "✅ Kitty est déjà installé."
  fi

  # Vérifie si Tmux Plugin Manager est installé
  if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "📦 Installation de Tmux Plugin Manager..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  else
    echo "✅ Tmux Plugin Manager est déjà installé."
  fi

  echo "✅ Installation terminée."
}

do_installs() {
  echo "📦 Début de l'installation..."

  # Vérifie si Homebrew est installé
  if ! command -v brew &>/dev/null; then
    echo "🍺 Installation de Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    echo "✅ Homebrew est déjà installé."
  fi

  echo "📥 Installation de Rosetta 2 (si nécessaire)..."
  softwareupdate --install-rosetta --agree-to-license || true

  echo "🐳 Téléchargement de Docker Desktop ARM64..."
  cd ~/Downloads
  curl -L -o Docker.dmg "https://desktop.docker.com/mac/main/arm64/Docker.dmg?utm_source=docker&utm_medium=webreferral&utm_campaign=docs-driven-download-mac-arm64"

  echo "🧱 Installation de NVM et Node.js LTS..."
  brew install nvm
  export NVM_DIR="$HOME/.nvm"
  mkdir -p "$NVM_DIR"
  source "$(brew --prefix nvm)/nvm.sh"
  nvm install --lts
  nvm use --lts

  echo "🧱 Installation de AWS CLI..."
  brew install awscli

  echo "📦 Installation de SDKMAN..."
  curl -s "https://get.sdkman.io" | bash
  source "$HOME/.sdkman/bin/sdkman-init.sh"
  sdk version
  sdk install java 17.0.10-tem
  sdk install scala 2.13.11
  sdk install sbt 

  echo "📦 Installation de Yarn et TypeScript..."
  npm install -g yarn
  npm install typescript --save-dev


  echo "🛠️ Installation des outils de développement..."
  brew install postgresql pigz gnu-tar ripgrep git-flow-avh neovim diff-so-fancy tmux fzf bat git zsh eza zoxide gh lazygit coursier/formulas/coursier starship ripgrep git-flow-avh gnu-tar postgresql pigz
  brew install --cask google-cloud-sdk raycast slack ghostty

  # # installation de skhd et yabai et sketchybar
  # echo "🌀 Installation de skhd, yabai et sketchybar..."
  # brew install --cask sf-symbols
  # brew tap koekeishiya/formulae
  # curl -L https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v1.0.23/sketchybar-app-font.ttf -o $HOME/Library/Fonts/sketchybar-app-font.ttf
  # brew install jq 
  #brew install koekeishiya/formulae/yabai
  #brew install koekeishiya/formulae/skhd
  # brew install koekeishiya/formulae/skhd koekeishiya/formulae/yabai sketchybar

  echo "🔌 Installation des plugins Zsh..."
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

  echo "🐱 Installation de Kitty terminal..."
  curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin

  echo "🔧 Installation des plugins Tmux..."
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

  echo "🌀 Installation de Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  echo "✅ Installation terminée."
}

do_links() {
  echo "🔗 Création des symlinks..."

  CONFIG_DIR="$HOME/.config"
  DOTFILES="$CONFIG_DIR/dotfiles"

 
  echo "🧼 Suppression des anciens fichiers de configuration..."

  # Fichiers à remplacer
  for FILE in .zshrc .tmux.conf .gitconfig .gitignore_global .z; do
    TARGET="$HOME/$FILE"
    if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
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
      echo "❌ Suppression de $TARGET"
      rm -rf "$TARGET"
    fi
    echo "🔗 Création du lien symbolique vers $DOTFILES/$DIR"
    ln -s "$DOTFILES/$DIR" "$TARGET"
  done

  # starship.toml
  TARGET="$CONFIG_DIR/starship.toml"
  if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
    echo "❌ Suppression de $TARGET"
    rm -f "$TARGET"
  fi
  echo "🔗 Création du lien symbolique vers $DOTFILES/starship.toml"
  ln -s "$DOTFILES/starship.toml" "$TARGET"

  echo "✅ Tous les liens symboliques ont été créés avec succès."
}

# Vérification de l'argument
if [[ -z $MODE ]]; then
  echo "Usage: $0 {install|links|all}"
  exit 1
fi

# Exécution
case $MODE in
  install) do_install ;;
  links) do_links ;;
  all) do_install; do_links ;;
  *) echo "Usage: $0 {install|links|all}"; exit 1 ;;
esac



echo "🎉 Script terminé avec succès."

#echo "🔄 Redémarrage de sketchybar..."
#brew services start sketchybar
#yabai --start-service
#skhd --start-service