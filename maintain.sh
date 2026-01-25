#!/bin/bash

# Script de maintenance automatique pour les dotfiles

CONFIG_DIR="$HOME/.config"
DOTFILES="$CONFIG_DIR/dotfiles"

echo "🔧 Maintenance des dotfiles..."

# 1. Vérifier les mises à jour disponibles
echo "📥 Vérification des mises à jour..."
if [ -d "$DOTFILES/.git" ]; then
  cd "$DOTFILES" || exit 1
  git fetch
  
  local=$(git rev-parse HEAD)
  remote=$(git rev-parse @{u})
  
  if [ "$local" != "$remote" ]; then
    echo "🔄 Des mises à jour sont disponibles"
    read -p "Voulez-vous mettre à jour ? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      git pull
      echo "✅ Mise à jour effectuée"
    fi
  else
    echo "✅ Déjà à jour"
  fi
fi

# 2. Vérifier l'intégrité des symlinks
echo "🔍 Vérification des symlinks..."
errors=0

# Fichiers
files=(".zshrc" ".tmux.conf" ".gitconfig" ".gitignore_global")
for file in "${files[@]}"; do
  if [ -L "$HOME/$file" ]; then
    target=$(readlink "$HOME/$file")
    if [[ "$target" == "$DOTFILES"* ]]; then
      echo "  ✅ $file"
    else
      echo "  ❌ $file pointe vers: $target"
      ((errors++))
    fi
  elif [ -f "$HOME/$file" ]; then
    echo "  ⚠️  $file existe mais n'est pas un symlink"
    ((errors++))
  else
    echo "  ⚠️  $file n'existe pas"
    ((errors++))
  fi
done

# Dossiers
dirs=("nvim" "sesh" "cursor" "vscode" "git" "ghostty")
for dir in "${dirs[@]}"; do
  if [ -L "$CONFIG_DIR/$dir" ]; then
    echo "  ✅ $dir/"
  elif [ -d "$CONFIG_DIR/$dir" ]; then
    echo "  ⚠️  $dir/ existe mais n'est pas un symlink"
    ((errors++))
  else
    echo "  ⚠️  $dir/ n'existe pas"
    ((errors++))
  fi
done

# starship.toml
if [ -L "$CONFIG_DIR/starship.toml" ]; then
  echo "  ✅ starship.toml"
else
  echo "  ⚠️  starship.toml n'est pas un symlink"
  ((errors++))
fi

if [ $errors -eq 0 ]; then
  echo "✅ Tous les symlinks sont corrects"
else
  echo "⚠️  $errors problème(s) détecté(s)"
  read -p "Voulez-vous recréer les symlinks ? (y/N) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    "$DOTFILES/setup.sh" links
  fi
fi

# 3. Nettoyer les anciens backups (garder les 5 derniers)
echo "🧹 Nettoyage des anciens backups..."
if [ -d "$CONFIG_DIR" ]; then
  old_backups=($(ls -td "$CONFIG_DIR"/dotfiles-backup-* 2>/dev/null | tail -n +6))
  if [ ${#old_backups[@]} -gt 0 ]; then
    echo "  🗑️  Suppression de ${#old_backups[@]} ancien(s) backup(s)..."
    for backup in "${old_backups[@]}"; do
      rm -rf "$backup"
      echo "    Supprimé: $(basename "$backup")"
    done
  else
    echo "  ✅ Aucun ancien backup à supprimer"
  fi
fi

# 4. Vérifier les mises à jour Homebrew
echo "🍺 Vérification des mises à jour Homebrew..."
if command -v brew &>/dev/null; then
  outdated=$(brew outdated --quiet 2>/dev/null | wc -l | tr -d ' ')
  if [ "$outdated" -gt 0 ]; then
    echo "  📦 $outdated paquet(s) peuvent être mis à jour"
    read -p "Voulez-vous mettre à jour ? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      brew update && brew upgrade
      echo "✅ Mise à jour effectuée"
    fi
  else
    echo "  ✅ Tous les paquets sont à jour"
  fi
  
  # Nettoyer Homebrew
  echo "  🧹 Nettoyage de Homebrew..."
  brew cleanup
fi

# 5. Vérifier l'espace disque utilisé par les backups
echo "💾 Espace disque utilisé par les backups..."
if [ -d "$CONFIG_DIR" ]; then
  total_size=$(du -sh "$CONFIG_DIR"/dotfiles-backup-* 2>/dev/null | awk '{sum+=$1} END {print sum}' || echo "0")
  if [ "$total_size" != "0" ]; then
    echo "  📊 Taille totale: $(du -sh "$CONFIG_DIR"/dotfiles-backup-* 2>/dev/null | awk '{sum+=$1} END {print sum}')"
  else
    echo "  ✅ Aucun backup"
  fi
fi

echo ""
echo "✅ Maintenance terminée"

