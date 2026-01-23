#!/bin/bash

MODE=$1
ONLY=$2

# Vérifie si l'utilisateur est déjà dans une session tmux
CURRENT_SESSION=$(tmux display-message -p '#S' 2>/dev/null)

if [[ -z $MODE ]]; then
  echo "Usage: $0 {main|all|shared|admin|app|api|pro|pdf} [only]"
  exit 1
fi

SESSION_NAME="hemea-$MODE"
MAIN_SESSION="hemea-main"
session_created=false
# Tableau des services redémarrés
restarted_services=()

# Tue tout processus écoutant sur le port donné
free_port_if_used() {
  local port=$1
  pid=$(lsof -ti tcp:"$port")
  if [[ -n "$pid" ]]; then
    echo "🔌 Port $port occupé par PID $pid — kill..."
    kill -9 "$pid"
  fi
}

# Envoie une commande dans le pane, quelle que soit la situation actuelle
# + tue les processus écoutant sur les ports associés
send_if_absent() {
  local pane=$1
  local pattern=$2
  local cmd=$3
  shift 3
  local ports=("$@")

  # Libérer les ports avant d'envoyer
  for port in "${ports[@]}"; do
    free_port_if_used "$port"
  done

  # Vérifier si le service est déjà en cours d'exécution
  service_running=false
  if tmux capture-pane -pt "$pane" 2>/dev/null | grep -q "$pattern"; then
    service_running=true
  fi

  # Force le redémarrage si on est en mode "only" ou si on change de mode
  if [[ "$ONLY" == "only" || "$MODE_CHANGED" == "true" ]]; then
    # Envoyer d'abord un Ctrl+C pour arrêter proprement
    tmux send-keys -t "$pane" C-c
    sleep 0.2
    # Puis effacer l'écran
    tmux send-keys -t "$pane" "clear" Enter
    service_running=false
  fi
  
  # Lancer le service s'il n'est pas en cours
  if ! $service_running; then
    # Vérifier le répertoire actuel de façon plus fiable
    # On envoie pwd pour être sûr du répertoire actuel puis on le récupère
    tmux send-keys -t "$pane" "pwd > /tmp/tmux_pwd_$$.tmp && clear" Enter
    sleep 0.1
    current_dir=$(cat "/tmp/tmux_pwd_$$.tmp" 2>/dev/null || echo "")
    rm -f "/tmp/tmux_pwd_$$.tmp" 2>/dev/null
    
    # Simplifier pour éviter les erreurs de syntaxe avec regex
    target_folder=""
    
    # Vérifier si la commande commence par 'cd' suivi d'un dossier
    if echo "$cmd" | grep -q "^cd [^ &;]\+"; then
      # Extraire le nom du dossier après cd
      target_folder=$(echo "$cmd" | sed -E 's/^cd ([^ &;]+).*/\1/')
      
      # Vérifier si on est déjà dans le bon dossier
      if [[ "$current_dir" == *"$target_folder"* || "$current_dir" == *"/$(basename "$target_folder")"* ]]; then
        # Extraire la commande après '&&' s'il y en a une
        if echo "$cmd" | grep -q "&&"; then
          # Récupérer la partie après '&&'
          cmd=$(echo "$cmd" | sed -E 's/^cd [^ &;]+ *&& *//')
          echo "Déjà dans $target_folder, exécution directe de: $cmd"
        fi
      fi
    fi
    
    tmux send-keys -t "$pane" "$cmd" Enter
    restarted_services+=("$cmd")  # Ajout du service redémarré au tableau
  fi
}

# Détecter si on a changé de mode (silencieusement)
MODE_CHANGED="false"
LAST_MODE_FILE="/tmp/hemea_last_mode"
if [[ -f "$LAST_MODE_FILE" ]]; then
  LAST_MODE=$(cat "$LAST_MODE_FILE" 2>/dev/null)
  [[ "$LAST_MODE" != "$MODE" ]] && MODE_CHANGED="true"
fi
# Sauvegarder le mode actuel pour la prochaine exécution
echo "$MODE" > "$LAST_MODE_FILE" 2>/dev/null

if [[ "$ONLY" == "only" ]]; then
  # Mode 'only' : on tue toutes les autres sessions
  echo "🛡️ Option 'only' activée - Mode exclusif pour $SESSION_NAME"
  
  # Vérifier si nous sommes dans la session cible
  if [[ "$CURRENT_SESSION" == "$SESSION_NAME" ]]; then
    echo "Session actuelle = $SESSION_NAME. On tue toutes les autres."
    tmux list-sessions -F '#S' | grep -v "^$SESSION_NAME\$" | xargs -I {} tmux kill-session -t {}
    
    # Fermer toutes les fenêtres sauf celle en cours
    current_window=$(tmux display-message -p '#I')
    for window in $(tmux list-windows -t "$SESSION_NAME" -F '#I' | grep -v "^$current_window$"); do
      tmux kill-window -t "$SESSION_NAME:$window"
    done
    
    # Si la fenêtre active n'est pas 'work', la créer
    if ! tmux list-windows -t "$SESSION_NAME" | grep -q "work"; then
      tmux rename-window -t "$SESSION_NAME" work
    fi
  else
    # Utiliser une approche alternative: créer la nouvelle session d'abord,
    # puis détacher toutes les autres sessions pour les tuer plus tard
    
    # Créer d'abord la nouvelle session (même si elle existe déjà)
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
      echo "🚪 La session $SESSION_NAME existe déjà, on s'y attache."
      # On ne la tue pas, on va la "recycler"
    else
      echo "🎯 Création de la session $SESSION_NAME"
      tmux new-session -s "$SESSION_NAME" -d -n work
    fi
    
    # S'attacher à la nouvelle session
    tmux switch-client -t "$SESSION_NAME"
    
    # Puis tuer toutes les autres sessions à la fin du script avec un trap
    cleanup_sessions=""
    for sess in $(tmux list-sessions -F '#S' 2>/dev/null | grep -v "^$SESSION_NAME\$"); do
      cleanup_sessions="$cleanup_sessions $sess"
    done
    
    # Sauvegarder les sessions à nettoyer pour le trap
    if [[ -n "$cleanup_sessions" ]]; then
      echo "Sessions à nettoyer à la fin: $cleanup_sessions"
      # Créer un trap pour exécuter à la fin du script
      trap "echo 'Nettoyage des sessions...'; for sess in $cleanup_sessions; do tmux kill-session -t \"\$sess\" 2>/dev/null || true; done" EXIT
    fi
    
    # La session a déjà été créée ou nous nous y sommes attachés plus haut
  fi
  
  # Toujours indiquer que la session a été créée/recréée
  session_created=true
else
  # Mode normal (pas 'only')
  if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "La session $SESSION_NAME existe déjà, on s'y attache."
    tmux switch-client -t "$SESSION_NAME"
  else
    tmux new-session -s "$SESSION_NAME" -d -n work
    session_created=true
    tmux switch-client -t "$SESSION_NAME"
  fi
fi

# Gérer la fenêtre 'work'
if [[ "$session_created" == false ]]; then
  if tmux list-windows -t "$SESSION_NAME" | grep -q "^0: work"; then
    tmux select-window -t "$SESSION_NAME:work"
  else
    tmux new-window -t "$SESSION_NAME" -n work
    tmux select-window -t "$SESSION_NAME:work"
  fi
fi

# === MAIN ou ALL: Création des 6 panneaux ===
if [[ "$MODE" == "main" || "$MODE" == "all" ]]; then
  echo "Préparation de la structure pour le mode $MODE"
  
  # Sélectionner ou créer la fenêtre work
  if tmux list-windows -t "$SESSION_NAME" | grep -q "work"; then
    tmux select-window -t "$SESSION_NAME:work"
  else
    tmux new-window -t "$SESSION_NAME" -n work
  fi

  # Toujours recréer complètement les panneaux en mode "only"
  if [[ "$ONLY" == "only" || "$session_created" == "true" ]]; then
    echo "Recréation complète des panneaux pour $MODE"

    # Forcer la suppression explicite de tous les panneaux sauf le premier
    while [[ $(tmux list-panes -t "$SESSION_NAME:work" | wc -l | tr -d ' ') -gt 1 ]]; do
      pane_count=$(tmux list-panes -t "$SESSION_NAME:work" | wc -l | tr -d ' ')
      for (( i=$pane_count-1; i>0; i-- )); do
        echo "Suppression du panneau $i"
        tmux kill-pane -t "$SESSION_NAME:work.$i" 2>/dev/null || true
      done
    done
    
    # Après avoir nettoyé, créer 6 panneaux en sequence
    # Vérification que nous avons au moins un panneau
    if [[ $(tmux list-panes -t "$SESSION_NAME:work" | wc -l | tr -d ' ') -lt 1 ]]; then
      echo "Aucun panneau trouvé, création d'un panneau initial"
      tmux new-window -t "$SESSION_NAME" -n work
    fi

    # Définir un layout plus simple et fiable
    tmux select-layout -t "$SESSION_NAME:work" even-horizontal
    sleep 0.2

    echo "Création du panneau 1"
    tmux split-window -h -t "$SESSION_NAME:work.0"
    sleep 0.2
    
    echo "Création du panneau 2 et 3"
    tmux split-window -v -t "$SESSION_NAME:work.0"
    sleep 0.2
    tmux split-window -v -t "$SESSION_NAME:work.2"
    sleep 0.2
    
    echo "Création du panneau 4 et 5"
    tmux split-window -v -t "$SESSION_NAME:work.1"
    sleep 0.2
    tmux split-window -v -t "$SESSION_NAME:work.4"
    sleep 0.2
    
    # Forcer le layout tiled pour une meilleure disposition
    tmux select-layout -t "$SESSION_NAME:work" tiled
    sleep 0.2
  fi

  tmux select-layout -t "$SESSION_NAME" tiled

  # Un peu de temps pour que tout soit bien initialisé
  sleep 0.5
  
  # Récupérer les IDs des panneaux
  panes=($(tmux list-panes -t "$SESSION_NAME:work" -F '#{pane_id}'))

  # Assignation logique
  pane_api=${panes[0]}
  pane_admin=${panes[1]}
  pane_app=${panes[2]}
  pane_pro=${panes[3]}
  pane_pdf=${panes[4]}
  pane_shared=${panes[5]}

  # Fonction pour envoyer la commande correcte selon l'emplacement
  execute_in_dir() {
    local pane=$1
    local dir=$2
    local cmd=$3
    local port=$4
    
    # Exécuter pwd dans le panneau pour savoir où on est
    tmux send-keys -t "$pane" "pwd > /tmp/tmux_dir_$$.tmp && clear" Enter
    sleep 0.2
    local current=$(cat "/tmp/tmux_dir_$$.tmp" 2>/dev/null || echo "")
    rm -f "/tmp/tmux_dir_$$.tmp"
    
    # Libérer le port
    free_port_if_used "$port"
    
    # Déterminer si on doit changer de répertoire
    if [[ "$current" == *"/$dir"* || "$current" == *"/travauxlib/$dir"* ]]; then
      tmux send-keys -t "$pane" "$cmd" Enter
    else
      tmux send-keys -t "$pane" "cd $dir && $cmd" Enter
    fi
    
    # Ajouter aux services redémarrés
    restarted_services+=("$dir: $cmd")
  }
  
  # Lancer les services de base (pour main et all) avec la nouvelle fonction
  execute_in_dir "$pane_api" "api" "sbt run" 9000
  execute_in_dir "$pane_admin" "admin" "yarn start" 3030
  execute_in_dir "$pane_app" "app" "yarn start" 3010
  execute_in_dir "$pane_pro" "pro" "yarn start" 3050

  if [[ "$MODE" == "all" ]]; then
    # Mode ALL: lancer aussi pdf-service et shared
    execute_in_dir "$pane_pdf" "pdf-service" "yarn start" 4999
    execute_in_dir "$pane_shared" "shared" "yarn start:local" 61000
  elif [[ "$MODE" == "main" && "$MODE_CHANGED" == "true" ]]; then
    # Si on est passé de all à main, arrêter les services supplémentaires
    tmux send-keys -t "$pane_pdf" C-c
    sleep 0.2
    tmux send-keys -t "$pane_pdf" "clear" Enter
    tmux send-keys -t "$pane_shared" C-c
    sleep 0.2
    tmux send-keys -t "$pane_shared" "clear" Enter
  fi
fi

# === SHARED uniquement : 1 seul panneau ===
if [[ "$MODE" == "shared" ]]; then
  send_if_absent "$SESSION_NAME:work.0" "yarn start:local" 'cd shared && yarn start:local' 61000
fi

if [[ "$MODE" == "admin" ]]; then
  send_if_absent "$SESSION_NAME:work.0" "yarn start" 'cd admin && yarn start' 3030
  tmux split-window -v -t "$SESSION_NAME:work.0"
  sleep 0.2
  send_if_absent "$SESSION_NAME:work.1" "sbt run" 'cd api && sbt run' 9000
fi

if [[ "$MODE" == "app" ]]; then
  send_if_absent "$SESSION_NAME:work.0" "yarn start" 'cd app && yarn start' 3010
  tmux split-window -v -t "$SESSION_NAME:work.0"
  sleep 0.2
  send_if_absent "$SESSION_NAME:work.1" "sbt run" 'cd api && sbt run' 9000
fi

if [[ "$MODE" == "api" ]]; then
  send_if_absent "$SESSION_NAME:work.0" "sbt run" 'cd api && sbt run' 9000
  tmux split-window -v -t "$SESSION_NAME:work.0"
  sleep 0.2
  send_if_absent "$SESSION_NAME:work.1" "sbt run" 'cd api && sbt run' 9000
  fi

if [[ "$MODE" == "pro" ]]; then
  send_if_absent "$SESSION_NAME:work.0" "yarn start" 'cd pro && yarn start' 3050
  tmux split-window -v -t "$SESSION_NAME:work.0"
  sleep 0.2
  send_if_absent "$SESSION_NAME:work.1" "sbt run" 'cd api && sbt run' 9000
fi

if [[ "$MODE" == "pdf" ]]; then
  send_if_absent "$SESSION_NAME:work.0" "yarn start" 'cd pdf-service && yarn start' 4999
  tmux split-window -v -t "$SESSION_NAME:work.0"
  sleep 0.2
  send_if_absent "$SESSION_NAME:work.1" "sbt run" 'cd api && sbt run' 9000
fi


# === Deuxième fenêtre : z et nvim ===
if ! tmux list-windows -t "$SESSION_NAME" | grep -q "others"; then
  tmux new-window -t "$SESSION_NAME" -n others
  tmux send-keys -t "$SESSION_NAME:others" 'z' Enter
  tmux split-window -v -t "$SESSION_NAME:others"
  tmux send-keys -t "$SESSION_NAME:others.1" 'nvim' Enter
fi

# Revenir à la fenêtre principale
tmux select-window -t "$SESSION_NAME:work"

# Attacher uniquement si on n'est pas déjà dans tmux
if [[ -z $TMUX ]]; then
  tmux attach -t "$SESSION_NAME"
fi

# === Résumé concis ===
if [ ${#restarted_services[@]} -gt 0 ]; then
  echo "✅ Services ($MODE): ${#restarted_services[@]} service(s) lancé(s)"
fi
