# Raycast Configuration

## Export (sauvegarder ta config)

1. Ouvre Raycast (⌘ + Space)
2. Tape "Export" et sélectionne "Export Settings & Data"
3. Choisis un mot de passe (ou laisse vide)
4. Sauvegarde le fichier `.rayconfig` dans ce dossier

```bash
# Ou via la ligne de commande (si tu as le fichier)
cp ~/Downloads/*.rayconfig ~/.config/dotfiles/raycast/
```

## Import (sur un nouveau Mac)

1. Ouvre Raycast
2. Tape "Import" et sélectionne "Import Settings & Data"
3. Sélectionne le fichier `.rayconfig`
4. Entre le mot de passe (si défini)

## Ce qui est exporté

- Extensions installées
- Snippets
- Quicklinks
- Hotkeys personnalisés
- Préférences
- Thème

## Note

Le fichier `.rayconfig` peut contenir des données sensibles.
Il est ajouté au `.gitignore` par sécurité.
