#!/bin/bash

MODE=$1

if [[ -z $MODE ]]; then
  echo "Usage: $0 {main|all|shared}"
  exit 1
fi

SESSION_NAME="hemea-$MODE"
MAIN_SESSION="hemea-main"


set -e

# Démarre une nouvelle session seulement si on n'est PAS dans tmux
if [[ -z $TMUX ]]; then
  tmux new-session -s $SESSION_NAME -d -n work
  if switch-client -t $SESSION_NAME; then
    tmux switch-client -t $SESSION_NAME
  else
    tmux attach -t $SESSION_NAME
  fi
else
  tmux rename-window -t "$(tmux display-message -p '#S')" work 2>/dev/null
  tmux switch-client -t $SESSION_NAME
fi


if tmux has-session -t $SESSION_NAME 2>/dev/null; then
  echo "hemea-$MODE exists"



  tmux switch -t $SESSION_NAME
else
  echo "hemea-$MODE does not exist"
  
  # Créer la session seulement si elle n'existe pas

  tmux new-session -s $SESSION_NAME -d -n work
  tmux switch-client -t $SESSION_NAME
  tmux select-window -t "$SESSION_NAME:work" 2>/dev/null || true 

  if [[ $MODE == "main" || $MODE == "all" ]]; then
    tmux split-window -h -t $SESSION_NAME             # Pane 1
    tmux split-window -v -t $SESSION_NAME:work.0      # Pane 2 (left middle)
    tmux split-window -v -t $SESSION_NAME:work.2      # Pane 3 (left bottom)
    tmux split-window -v -t $SESSION_NAME:work.1      # Pane 4 (right middle)
    tmux split-window -v -t $SESSION_NAME:work.4      # Pane 5 (right bottom)

    # Forcer le layout en grille 3x2
    tmux select-layout -t $SESSION_NAME tiled

    panes=($(tmux list-panes -t $SESSION_NAME:work -F '#{pane_id}'))

    pane_api=${panes[0]}
    pane_admin=${panes[1]}
    pane_app=${panes[2]}
    pane_pro=${panes[3]}
    pane_pdf=${panes[4]}
    pane_shared=${panes[5]}


    tmux send-keys -t "$pane_api" 'cd api && sbt run' Enter
    tmux send-keys -t "$pane_admin" 'cd admin && yarn start' Enter
    tmux send-keys -t "$pane_app" 'cd app && yarn start' Enter
    tmux send-keys -t "$pane_pro" 'cd pro && yarn start' Enter

    if [[ $MODE == "all" ]]; then
      tmux send-keys -t "$pane_pdf" 'cd pdf-service && yarn start' Enter
      tmux send-keys -t "$pane_shared" 'cd shared && yarn start' Enter
    fi
  fi
  if [[ $MODE == "shared" ]]; then
    tmux send-keys -t $SESSION_NAME:work.0 'cd shared && yarn start:local' Enter
  fi

  tmux new-window -t $SESSION_NAME -n others
  tmux send-keys -t $SESSION_NAME:others 'nvim' Enter
  tmux split-window -v -t $SESSION_NAME:others
  tmux send-keys -t $SESSION_NAME:others.1 'ss' Enter

  if [[ -z $TMUX ]]; then
    tmux attach -t "$SESSION_NAME"
  fi


fi


