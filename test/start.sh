#!/bin/bash

MODE=$1

if [[ -z $MODE ]]; then
  echo "Usage: $0 {main|all|shared}"
  exit 1
fi

SESSION_NAME="hemea-$MODE"
MAIN_SESSION="hemea-main"
session_created=false

# Si la session existe déjà, on s'y attache, sinon on la crée
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  echo "La session $SESSION_NAME existe déjà, on s'y attache."
  tmux switch-client -t "$SESSION_NAME"
else
  tmux new-session -s "$SESSION_NAME" -d -n work
  session_created=true
  tmux switch-client -t "$SESSION_NAME"
fi

# Si la session vient d’être créée, on est déjà dans la fenêtre 'work'
if [[ "$session_created" == false ]]; then
  # Si la fenêtre 'work' existe, on s'y place
  if tmux list-windows -t "$SESSION_NAME" | grep -q "^0: work"; then
    tmux select-window -t "$SESSION_NAME:work"
  else
    tmux new-window -t "$SESSION_NAME" -n work
    tmux select-window -t "$SESSION_NAME:work"
  fi
fi

# === MAIN ou ALL: Création des 6 panneaux ===
if [[ "$session_created" == true && ( "$MODE" == "main" || "$MODE" == "all" ) ]]; then
  tmux split-window -h -t "$SESSION_NAME"             # Pane 1
  tmux split-window -v -t "$SESSION_NAME:work.0"      # Pane 2 (left middle)
  tmux split-window -v -t "$SESSION_NAME:work.2"      # Pane 3 (left bottom)
  tmux split-window -v -t "$SESSION_NAME:work.1"      # Pane 4 (right middle)
  tmux split-window -v -t "$SESSION_NAME:work.4"      # Pane 5 (right bottom)

  tmux select-layout -t "$SESSION_NAME" tiled

  # Récupérer les IDs des panneaux
  panes=($(tmux list-panes -t "$SESSION_NAME:work" -F '#{pane_id}'))

  # Assignation logique
  pane_api=${panes[0]}
  pane_admin=${panes[1]}
  pane_app=${panes[2]}
  pane_pro=${panes[3]}
  pane_pdf=${panes[4]}
  pane_shared=${panes[5]}

  # Lancer les services
  tmux send-keys -t "$pane_api" 'cd api && sbt run' Enter
  tmux send-keys -t "$pane_admin" 'cd admin && yarn start' Enter
  tmux send-keys -t "$pane_app" 'cd app && yarn start' Enter
  tmux send-keys -t "$pane_pro" 'cd pro && yarn start' Enter

  if [[ "$MODE" == "all" ]]; then
    tmux send-keys -t "$pane_pdf" 'cd pdf-service && yarn start' Enter
    tmux send-keys -t "$pane_shared" 'cd shared && yarn start:local' Enter
  fi
fi

# === SHARED uniquement : 1 seul panneau ===
if [[ "$MODE" == "shared" ]]; then
  tmux send-keys -t "$SESSION_NAME:work.0" 'cd shared && yarn start:local' Enter
fi

# === Deuxième fenêtre : z et nvim ===
tmux new-window -t "$SESSION_NAME" -n others
tmux send-keys -t "$SESSION_NAME:others" 'z' Enter
tmux split-window -v -t "$SESSION_NAME:others"
tmux send-keys -t "$SESSION_NAME:others.1" 'nvim' Enter

# Revenir à la fenêtre principale
tmux select-window -t "$SESSION_NAME:work"

# Attacher uniquement si on n'est pas déjà dans tmux
if [[ -z $TMUX ]]; then
  tmux attach -t "$SESSION_NAME"
fi

