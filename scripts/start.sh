#!/bin/bash

set -o pipefail

# === Configuration ===
MODE=${1:-}
ONLY=${2:-}
SESSION_NAME="hemea-${MODE}"
LAST_MODE_FILE="/tmp/hemea_last_mode"
START_TIME=$(date +%s)

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# === Aide ===
show_help() {
  echo -e "${BOLD}Usage:${NC} $0 <mode> [option]"
  echo ""
  echo -e "${BOLD}Modes disponibles:${NC}"
  echo -e "  ${GREEN}main${NC}     API + Admin + App + Pro          ${CYAN}:9000 :3030 :3010 :3050${NC}"
  echo -e "  ${GREEN}all${NC}      Tout (6 services)                ${CYAN}+ :4999 :61000${NC}"
  echo -e "  ${GREEN}admin${NC}    Admin + API                      ${CYAN}:3030 :9000${NC}"
  echo -e "  ${GREEN}app${NC}      App + API                        ${CYAN}:3010 :9000${NC}"
  echo -e "  ${GREEN}pro${NC}      Pro + API                        ${CYAN}:3050 :9000${NC}"
  echo -e "  ${GREEN}pdf${NC}      PDF-service + API                ${CYAN}:4999 :9000${NC}"
  echo -e "  ${GREEN}api${NC}      API seul                         ${CYAN}:9000${NC}"
  echo -e "  ${GREEN}shared${NC}   Shared seul                      ${CYAN}:61000${NC}"
  echo ""
  echo -e "${BOLD}Commandes:${NC}"
  echo -e "  ${GREEN}--status${NC}    État des services"
  echo -e "  ${GREEN}--stop${NC}      Arrête tous les services"
  echo -e "  ${GREEN}--open${NC}      Ouvre les URLs dans le navigateur"
  echo ""
  echo -e "${BOLD}Options:${NC}"
  echo -e "  ${YELLOW}only${NC}        Mode exclusif : tue les autres sessions"
  echo ""
  echo -e "${BOLD}Exemples:${NC}"
  echo -e "  ${CYAN}$0 main${NC}              # Dev standard"
  echo -e "  ${CYAN}$0 main --restart${NC}    # Force redémarrage"
  echo -e "  ${CYAN}$0 --status${NC}          # État des services"
  echo -e "  ${CYAN}$0 --open${NC}            # Ouvre le navigateur"
  exit 0
}

# === Commandes spéciales ===
[[ -z "$MODE" || "$MODE" == "--help" || "$MODE" == "-h" ]] && show_help

# --status : Afficher l'état des services
if [[ "$MODE" == "--status" ]]; then
  echo -e "${BOLD}📊 État des services:${NC}"
  echo ""
  
  check_port() {
    local name=$1
    local port=$2
    if lsof -ti tcp:"$port" &>/dev/null; then
      echo -e "  ${GREEN}●${NC} $name ${CYAN}:$port${NC}"
    else
      echo -e "  ${RED}○${NC} $name ${CYAN}:$port${NC}"
    fi
  }
  
  check_port "API" 9000
  check_port "Admin" 3030
  check_port "App" 3010
  check_port "Pro" 3050
  check_port "PDF" 4999
  check_port "Shared" 61000
  
  echo ""
  echo -e "${BOLD}Sessions tmux:${NC}"
  tmux list-sessions 2>/dev/null | sed 's/^/  /' || echo "  Aucune session"
  exit 0
fi

# --stop : Arrêter tous les services
if [[ "$MODE" == "--stop" ]]; then
  echo -e "${YELLOW}🛑 Arrêt des services...${NC}"
  
  # Tuer les processus sur les ports
  for port in 9000 3030 3010 3050 4999 61000; do
    pid=$(lsof -ti tcp:"$port" 2>/dev/null)
    if [[ -n "$pid" ]]; then
      kill -9 "$pid" 2>/dev/null
      echo -e "  ${RED}✗${NC} Port $port (PID $pid)"
    fi
  done
  
  # Tuer les sessions hemea
  for sess in $(tmux list-sessions -F '#S' 2>/dev/null | grep "^hemea-"); do
    tmux kill-session -t "$sess" 2>/dev/null
    echo -e "  ${RED}✗${NC} Session $sess"
  done
  
  echo -e "${GREEN}✅ Tout arrêté${NC}"
  exit 0
fi

# --open : Ouvrir les URLs dans le navigateur
if [[ "$MODE" == "--open" ]]; then
  echo -e "${BLUE}🌐 Ouverture des URLs...${NC}"
  
  # URLs des services
  declare -a URLS=(
    "http://localhost:3030|Admin"
    "http://localhost:3010|App"
    "http://localhost:3050|Pro"
  )
  
  for entry in "${URLS[@]}"; do
    url="${entry%%|*}"
    name="${entry##*|}"
    port="${url##*:}"
    
    if lsof -ti tcp:"$port" &>/dev/null; then
      open "$url" 2>/dev/null && echo -e "  ${GREEN}●${NC} $name → $url"
    else
      echo -e "  ${RED}○${NC} $name (non démarré)"
    fi
  done
  exit 0
fi

# Gérer --restart comme option
if [[ "$ONLY" == "--restart" ]]; then
  ONLY="only"
fi

# === Validation du mode ===
VALID_MODES="main all shared admin app api pro pdf"
if ! echo "$VALID_MODES" | grep -qw "$MODE"; then
  echo -e "${RED}❌ Mode invalide: $MODE${NC}"
  show_help
fi

# === Fonctions utilitaires ===

# Libère un port s'il est utilisé
free_port() {
  local port=$1
  local pid=$(lsof -ti tcp:"$port" 2>/dev/null)
  [[ -n "$pid" ]] && kill -9 "$pid" 2>/dev/null
}

# Lance une commande dans un pane tmux
run_in_pane() {
  local pane=$1
  local dir=$2
  local cmd=$3
  local port=$4

  free_port "$port"
  tmux send-keys -t "$pane" "cd $dir && $cmd" Enter
}

# Stop un pane (Ctrl+C + clear)
stop_pane() {
  local pane=$1
  tmux send-keys -t "$pane" C-c 2>/dev/null
  sleep 0.1
  tmux send-keys -t "$pane" "clear" Enter 2>/dev/null
}

# === Détection changement de mode ===
MODE_CHANGED="false"
if [[ -f "$LAST_MODE_FILE" ]]; then
  [[ "$(cat "$LAST_MODE_FILE" 2>/dev/null)" != "$MODE" ]] && MODE_CHANGED="true"
fi
echo "$MODE" > "$LAST_MODE_FILE"

# === Gestion des sessions ===
CURRENT_SESSION=$(tmux display-message -p '#S' 2>/dev/null)

# Mode "only" : nettoyer les autres sessions
if [[ "$ONLY" == "only" ]]; then
  echo -e "${YELLOW}🛡️  Mode exclusif${NC}"
  for sess in $(tmux list-sessions -F '#S' 2>/dev/null | grep -v "^$SESSION_NAME$"); do
    tmux kill-session -t "$sess" 2>/dev/null
  done
fi

# Créer ou rejoindre la session
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  tmux switch-client -t "$SESSION_NAME" 2>/dev/null || true
else
  tmux new-session -s "$SESSION_NAME" -d -n work
  tmux switch-client -t "$SESSION_NAME" 2>/dev/null || true
fi

# Forcer redémarrage si "only" ou changement de mode
FORCE_RESTART="false"
[[ "$ONLY" == "only" || "$MODE_CHANGED" == "true" ]] && FORCE_RESTART="true"

# === Layouts par mode ===

setup_main() {
  # 4 panes : API | Admin | App | Pro
  local win="$SESSION_NAME:work"
  local current_panes=$(tmux list-panes -t "$win" 2>/dev/null | wc -l | tr -d ' ')
  
  # Recréer les panes si pas le bon nombre ou force restart
  if [[ "$FORCE_RESTART" == "true" || "$current_panes" != "4" ]]; then
    # Garder un seul pane
    while [[ $(tmux list-panes -t "$win" 2>/dev/null | wc -l) -gt 1 ]]; do
      tmux kill-pane -t "$win.1" 2>/dev/null || break
    done
    
    # Créer le layout 2x2
    tmux split-window -h -t "$win"
    tmux split-window -v -t "$win.0"
    tmux split-window -v -t "$win.2"
    tmux select-layout -t "$win" tiled
  fi
  
  sleep 0.3
  local panes=($(tmux list-panes -t "$win" -F '#{pane_id}'))
  
  run_in_pane "${panes[0]}" "api" "sbt run" 9000
  run_in_pane "${panes[1]}" "admin" "yarn start" 3030
  run_in_pane "${panes[2]}" "app" "yarn start" 3010
  run_in_pane "${panes[3]}" "pro" "yarn start" 3050
  
  echo -e "${GREEN}✓${NC} API + Admin + App + Pro"
}

setup_all() {
  # 6 panes : API | Admin | App | Pro | PDF | Shared
  local win="$SESSION_NAME:work"
  local current_panes=$(tmux list-panes -t "$win" 2>/dev/null | wc -l | tr -d ' ')
  
  # Recréer les panes si pas le bon nombre ou force restart
  if [[ "$FORCE_RESTART" == "true" || "$current_panes" != "6" ]]; then
    while [[ $(tmux list-panes -t "$win" 2>/dev/null | wc -l) -gt 1 ]]; do
      tmux kill-pane -t "$win.1" 2>/dev/null || break
    done
    
    # Layout 3x2
    tmux split-window -h -t "$win"
    tmux split-window -h -t "$win"
    tmux split-window -v -t "$win.0"
    tmux split-window -v -t "$win.2"
    tmux split-window -v -t "$win.4"
    tmux select-layout -t "$win" tiled
  fi
  
  sleep 0.3
  local panes=($(tmux list-panes -t "$win" -F '#{pane_id}'))
  
  run_in_pane "${panes[0]}" "api" "sbt run" 9000
  run_in_pane "${panes[1]}" "admin" "yarn start" 3030
  run_in_pane "${panes[2]}" "app" "yarn start" 3010
  run_in_pane "${panes[3]}" "pro" "yarn start" 3050
  run_in_pane "${panes[4]}" "pdf-service" "yarn start" 4999
  run_in_pane "${panes[5]}" "shared" "yarn start:local" 61000
  
  echo -e "${GREEN}✓${NC} Tous les services (6)"
}

setup_dual() {
  # 2 panes : Service + API
  local service=$1
  local dir=$2
  local cmd=$3
  local port=$4
  local win="$SESSION_NAME:work"
  local current_panes=$(tmux list-panes -t "$win" 2>/dev/null | wc -l | tr -d ' ')
  
  # Recréer si pas 2 panes ou force restart
  if [[ "$FORCE_RESTART" == "true" || "$current_panes" != "2" ]]; then
    while [[ $(tmux list-panes -t "$win" 2>/dev/null | wc -l) -gt 1 ]]; do
      tmux kill-pane -t "$win.1" 2>/dev/null || break
    done
    tmux split-window -v -t "$win"
  fi
  
  sleep 0.2
  local panes=($(tmux list-panes -t "$win" -F '#{pane_id}'))
  
  run_in_pane "${panes[0]}" "$dir" "$cmd" "$port"
  run_in_pane "${panes[1]}" "api" "sbt run" 9000
  
  echo -e "${GREEN}✓${NC} $service + API"
}

setup_single() {
  # 1 pane seul
  local service=$1
  local dir=$2
  local cmd=$3
  local port=$4
  local win="$SESSION_NAME:work"
  
  if [[ "$FORCE_RESTART" == "true" ]]; then
    while [[ $(tmux list-panes -t "$win" 2>/dev/null | wc -l) -gt 1 ]]; do
      tmux kill-pane -t "$win.1" 2>/dev/null || break
    done
  fi
  
  local panes=($(tmux list-panes -t "$win" -F '#{pane_id}'))
  run_in_pane "${panes[0]}" "$dir" "$cmd" "$port"
  
  echo -e "${GREEN}✓${NC} $service"
}

# === Exécution selon le mode ===
echo -e "${BLUE}🚀 Démarrage: ${BOLD}$MODE${NC}"

case "$MODE" in
  main)   setup_main ;;
  all)    setup_all ;;
  admin)  setup_dual "Admin" "admin" "yarn start" 3030 ;;
  app)    setup_dual "App" "app" "yarn start" 3010 ;;
  pro)    setup_dual "Pro" "pro" "yarn start" 3050 ;;
  pdf)    setup_dual "PDF" "pdf-service" "yarn start" 4999 ;;
  api)    setup_single "API" "api" "sbt run" 9000 ;;
  shared) setup_single "Shared" "shared" "yarn start:local" 61000 ;;
esac

# === Fenêtre "others" (terminal + nvim) ===
if ! tmux list-windows -t "$SESSION_NAME" 2>/dev/null | grep -q "others"; then
  tmux new-window -t "$SESSION_NAME" -n others
  tmux send-keys -t "$SESSION_NAME:others" 'cd .' Enter
  tmux split-window -v -t "$SESSION_NAME:others"
  tmux send-keys -t "$SESSION_NAME:others.1" 'nvim' Enter
fi

# Revenir à work
tmux select-window -t "$SESSION_NAME:work"

# Attacher si pas déjà dans tmux
[[ -z "$TMUX" ]] && tmux attach -t "$SESSION_NAME"

# Calculer le temps écoulé
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo -e "${GREEN}✅ Session ${BOLD}$SESSION_NAME${NC}${GREEN} prête${NC} ${CYAN}⏱️ ${DURATION}s${NC}"
