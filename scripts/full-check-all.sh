#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Liste des apps
APPS=("pro" "app" "shared" "admin" "pdf-service")

# Variables 
RESULTS=""
SUCCESS_COUNT=0
FAILURE_COUNT=0
COVERAGE_SUMMARY=""
TESTS_SUMMARY=""
ERRORS_SUMMARY=""
START_TIME=$(date +%s)

# Options de configuration
VERBOSE="false"
RUN_TESTS="true"
RUN_LINT="true"
RUN_TYPECHECK="true"
PARALLEL="false"
MAX_PARALLEL=2  # Nombre max de processus en parallèle (évite de saturer la RAM)
WITH_COVERAGE="false"  # Coverage désactivé par défaut (coûteux)
ONLY_CHANGED="false"   # Ne teste que les fichiers modifiés
TURBO_MODE="false"     # Mode turbo : max performance
SPECIFIC_APPS=()

# Couleurs pour l'affichage
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Affichage de l'aide
function show_help {
  echo -e "${BOLD}Usage:${NC} $0 [options] [app1 app2 ...]"
  echo ""
  echo -e "${BOLD}Description:${NC}"
  echo "  Lance les tests, lint et typecheck sur les applications du projet."
  echo ""
  echo -e "${BOLD}Options:${NC}"
  echo -e "  ${GREEN}--turbo${NC}           Mode turbo : parallèle + max workers (utilise 100% CPU)"
  echo -e "  ${GREEN}--parallel${NC}        Lance les apps en parallèle (2 à la fois par défaut)"
  echo -e "  ${GREEN}--jobs N${NC}          Nombre d'apps en parallèle (défaut: 2, turbo: 3)"
  echo -e "  ${GREEN}--verbose${NC}         Affiche les sorties en temps réel"
  echo -e "  ${GREEN}--no-tests${NC}        Désactive les tests unitaires"
  echo -e "  ${GREEN}--no-lint${NC}         Désactive le lint"
  echo -e "  ${GREEN}--no-typecheck${NC}    Désactive le typecheck"
  echo -e "  ${GREEN}--only-lint${NC}       Lance uniquement le lint"
  echo -e "  ${GREEN}--only-typecheck${NC}  Lance uniquement le typecheck"
  echo -e "  ${GREEN}--only-tests${NC}      Lance uniquement les tests"
  echo -e "  ${GREEN}--changed${NC}         Teste uniquement les fichiers modifiés (très rapide)"
  echo -e "  ${GREEN}--coverage${NC}        Active la couverture de code (désactivé par défaut)"
  echo -e "  ${GREEN}--help${NC}            Affiche cette aide"
  echo ""
  echo -e "${BOLD}Applications disponibles:${NC} ${CYAN}${APPS[*]}${NC}"
  echo ""
  echo -e "${BOLD}Exemples:${NC}"
  echo -e "  ${YELLOW}$0 --turbo${NC}                        # MAX PERF : 3 jobs + 75% workers"
  echo -e "  ${YELLOW}$0 --turbo --changed${NC}              # Turbo sur fichiers modifiés"
  echo -e "  ${YELLOW}$0 --parallel${NC}                     # Rapide : 2 jobs + 50% workers"
  echo -e "  ${YELLOW}$0 --parallel --changed${NC}           # Tests modifiés uniquement"
  echo -e "  ${YELLOW}$0 --parallel --only-lint${NC}         # Lint uniquement (très rapide)"
  echo -e "  ${YELLOW}$0 --parallel --coverage${NC}          # Avec couverture (CI)"
  exit 0
}

# Traitement des arguments
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --turbo)
      TURBO_MODE="true"
      PARALLEL="true"
      MAX_PARALLEL=3  # Plus agressif en turbo
      shift
      ;;
    --parallel)
      PARALLEL="true"
      shift
      ;;
    --jobs)
      shift
      if [[ $# -gt 0 && "$1" =~ ^[0-9]+$ ]]; then
        MAX_PARALLEL="$1"
        shift
      else
        echo "❌ --jobs nécessite un nombre (ex: --jobs 2)"
        exit 1
      fi
      ;;
    --verbose)
      VERBOSE="true"
      shift
      ;;
    --no-tests)
      RUN_TESTS="false"
      shift
      ;;
    --no-lint)
      RUN_LINT="false"
      shift
      ;;
    --no-typecheck)
      RUN_TYPECHECK="false"
      shift
      ;;
    --only-lint)
      RUN_TESTS="false"
      RUN_LINT="true"
      RUN_TYPECHECK="false"
      shift
      ;;
    --only-typecheck)
      RUN_TESTS="false"
      RUN_LINT="false"
      RUN_TYPECHECK="true"
      shift
      ;;
    --only-tests)
      RUN_TESTS="true"
      RUN_LINT="false"
      RUN_TYPECHECK="false"
      shift
      ;;
    --coverage)
      WITH_COVERAGE="true"
      shift
      ;;
    --changed)
      ONLY_CHANGED="true"
      shift
      ;;
    --help)
      show_help
      ;;
    -*)
      echo "Option inconnue: $1"
      show_help
      ;;
    *)
      POSITIONAL_ARGS+=("$1")
      shift
      ;;
  esac
done

# Si des apps spécifiques sont mentionnées, utiliser uniquement celles-ci
if [[ ${#POSITIONAL_ARGS[@]} -gt 0 ]]; then
  SPECIFIC_APPS=("${POSITIONAL_ARGS[@]}")
  APPS=("${SPECIFIC_APPS[@]}")
fi

# Construire la liste des checks actifs
ACTIVE_CHECKS=()
[[ "$RUN_TESTS" == "true" ]] && ACTIVE_CHECKS+=("tests")
[[ "$RUN_LINT" == "true" ]] && ACTIVE_CHECKS+=("lint")
[[ "$RUN_TYPECHECK" == "true" ]] && ACTIVE_CHECKS+=("typecheck")

# Désactiver verbose si parallel (incompatible)
if [[ "$PARALLEL" == "true" && "$VERBOSE" == "true" ]]; then
  echo "⚠️  --parallel et --verbose sont incompatibles, verbose ignoré"
  VERBOSE="false"
fi

# Affichage du résumé de ce qui va être exécuté
echo ""
echo "📋 Configuration :"
echo "   Apps    : ${APPS[*]}"
echo "   Checks  : ${ACTIVE_CHECKS[*]}"
[[ "$TURBO_MODE" == "true" ]] && echo "   Mode    : TURBO 🚀 ($MAX_PARALLEL jobs, 75% workers)"
[[ "$PARALLEL" == "true" && "$TURBO_MODE" == "false" ]] && echo "   Mode    : parallèle ⚡ ($MAX_PARALLEL jobs)"
[[ "$VERBOSE" == "true" ]] && echo "   Mode    : verbose"
[[ "$ONLY_CHANGED" == "true" && "$RUN_TESTS" == "true" ]] && echo "   Tests   : fichiers modifiés uniquement"
[[ "$WITH_COVERAGE" == "true" && "$RUN_TESTS" == "true" ]] && echo "   Coverage: activée"
echo ""

# Fonction pour extraire et formater la couverture
function extract_coverage {
  local output="$1"
  local app="$2"
  
  # Recherche de la couverture dans le format exact de Jest
  local coverage_raw=$(echo "$output" | grep -E "^All files" | head -1 || echo "")
  
  if [[ -z "$coverage_raw" ]]; then
    return
  fi
  
  local coverage=""
  # Extraire les pourcentages de la ligne (pattern: | XX.XX | XX.XX | XX.XX | XX.XX |)
  local stmts=$(echo "$coverage_raw" | grep -o -E "\|\s+[0-9]+\.[0-9]+\s+\|" | head -1 | tr -d '|' | tr -d ' ')
  local branch=$(echo "$coverage_raw" | grep -o -E "\|\s+[0-9]+\.[0-9]+\s+\|" | head -2 | tail -1 | tr -d '|' | tr -d ' ')
  local funcs=$(echo "$coverage_raw" | grep -o -E "\|\s+[0-9]+\.[0-9]+\s+\|" | head -3 | tail -1 | tr -d '|' | tr -d ' ')
  local lines=$(echo "$coverage_raw" | grep -o -E "\|\s+[0-9]+\.[0-9]+\s+\|" | head -4 | tail -1 | tr -d '|' | tr -d ' ')
  
  if [[ -n "$stmts" && -n "$branch" && -n "$funcs" && -n "$lines" ]]; then
    coverage="Stmts: $stmts%, Branch: $branch%, Funcs: $funcs%, Lines: $lines%"
  else
    # Méthode alternative d'extraction
    stmts=$(echo "$coverage_raw" | awk -F '|' '{print $2}' | tr -d ' ')
    branch=$(echo "$coverage_raw" | awk -F '|' '{print $3}' | tr -d ' ')
    funcs=$(echo "$coverage_raw" | awk -F '|' '{print $4}' | tr -d ' ')
    lines=$(echo "$coverage_raw" | awk -F '|' '{print $5}' | tr -d ' ')
    
    if [[ -n "$stmts" && -n "$branch" && -n "$funcs" && -n "$lines" ]]; then
      coverage="Stmts: $stmts%, Branch: $branch%, Funcs: $funcs%, Lines: $lines%"
    else
      coverage=$(echo "$coverage_raw" | tr -s ' ' | tr -s '|' | sed 's/All files/All files:/')
    fi
  fi
  
  COVERAGE_SUMMARY+="  $app : $coverage"$'\n'
}

# Fonction pour afficher le résumé final
function print_summary {
  local total=$((SUCCESS_COUNT + FAILURE_COUNT))
  local end_time=$(date +%s)
  local duration=$((end_time - START_TIME))
  local minutes=$((duration / 60))
  local seconds=$((duration % 60))
  
  # Formater le temps
  local time_str
  if [[ $minutes -gt 0 ]]; then
    time_str="${minutes}m ${seconds}s"
  else
    time_str="${seconds}s"
  fi
  
  echo -e "\n============================="
  echo -e "📊 Résumé : $SUCCESS_COUNT/$total apps OK  ⏱️  $time_str"
  echo -e "============================="
  printf "%b" "$RESULTS"
  
  # Afficher les détails des tests uniquement si les tests ont été lancés
  if [[ "$RUN_TESTS" == "true" && -n "$TESTS_SUMMARY" ]]; then
    echo -e "\n📝 Détails des tests :"
    printf "%b" "$TESTS_SUMMARY"
  fi
  
  # Afficher la couverture uniquement si activée et qu'il y a des données
  if [[ "$WITH_COVERAGE" == "true" && -n "$COVERAGE_SUMMARY" ]]; then
    echo -e "\n📈 Couverture :"
    printf "%b" "$COVERAGE_SUMMARY"
  fi
  
  # Afficher les erreurs uniquement s'il y en a
  if [[ -n "$ERRORS_SUMMARY" && "$ERRORS_SUMMARY" != "Aucune erreur détectée" ]]; then
    echo -e "\n❌ Erreurs :"
    printf "%b" "$ERRORS_SUMMARY"
  fi
}

# Fonction pour afficher les erreurs détaillées si mode verbose
function verbose_output {
  local app="$1"
  local output="$2"
  if [[ "$VERBOSE" == "true" ]]; then
    echo -e "\n📕 Erreurs dans $app :"
    echo "$output"
  fi
  
  # Créer une clé unique pour cette application
  local app_key="__${app}__"
  
  # Extraire les informations d'erreur pour le résumé final (en mode verbose et non-verbose)
  # Vérifier si on a déjà ajouté cette application dans le résumé
  if [[ "$ERRORS_SUMMARY" != *"$app_key"* ]]; then
    # Marquer que nous avons traité cette application
    ERRORS_SUMMARY+="$app_key"
    # Ajouter l'en-tête de l'application
    ERRORS_SUMMARY+="$app :\n"
  
  # Approche améliorée pour extraire les erreurs avec plus de précision
  
  # Patterns pour capturer différents types d'erreurs
  
  # 1. Pattern pour les lignes complètes contenant des chemins absolus vers des fichiers
  # Utilise le répertoire courant du script pour être portable
  local workspace_dir
  workspace_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  local escaped_workspace_dir=$(echo "$workspace_dir" | sed 's/[\/&]/\\&/g')
  local full_path_pattern="${escaped_workspace_dir}/[a-zA-Z0-9/_\.-]+\.[jt]sx?"
  
  # 2. Pattern ESLint: ligne avec numéro et erreur (ex: 39:21 error 'props' is defined...)
  local eslint_line_pattern="[0-9]+:[0-9]+\s+error"
  
  # 3. Pattern TypeScript: lignes d'erreur avec 'TS' (ex: TS2339: Property 'x' does not exist...)
  local typescript_error_pattern="TS[0-9]+:"
  
  # 4. Pattern pour les erreurs Jest
  local jest_error_pattern="Error: expect|● [^●]+failed:|FAIL "
  
  # 5. Pattern pour les erreurs génériques
  local generic_error_pattern="^Error:|^ERROR |^Failed "
  
  # 6. Pattern spécifique à admin (ajout pour capturer les erreurs admin)
  local admin_error_pattern="\ssrc/.*\.tsx?:[0-9]+:[0-9]+\s+error"
  
  # D'abord chercher les lignes avec des chemins absolus
  local file_errors=$(echo "$output" | grep -E "$full_path_pattern" | head -5)
  
  # Puis chercher les lignes avec des erreurs ESLint pour les inclure
  local eslint_errors=$(echo "$output" | grep -E "$eslint_line_pattern" | head -5)
  
  # Rechercher les erreurs TypeScript
  local typescript_errors=$(echo "$output" | grep -E "$typescript_error_pattern" | head -5)
  
  # Rechercher les erreurs admin spécifiques
  local admin_errors=$(echo "$output" | grep -E "$admin_error_pattern" | head -5)
  
  # Récupérer les lignes FAIL mais pas les lignes PASS
  local fail_lines=$(echo "$output" | grep "FAIL" | head -5)
  
  # Récupérer les détails d'erreur (lignes avec 'at')
  local error_details=$(echo "$output" | grep -E "^\s+at Object\." | head -10)
  
  # Combiner les résultats
  local combined_errors=""
  
  # Ajouter chaque type d'erreur trouvé à la liste combinée
  if [[ -n "$file_errors" ]]; then
    combined_errors+="$file_errors\n"
  fi
  
  if [[ -n "$eslint_errors" ]]; then
    combined_errors+="$eslint_errors\n"
  fi
  
  if [[ -n "$typescript_errors" ]]; then
    combined_errors+="$typescript_errors\n"
  fi
  
  if [[ -n "$admin_errors" ]]; then
    combined_errors+="$admin_errors\n"
  fi
  
  if [[ -n "$fail_lines" ]]; then
    combined_errors+="$fail_lines\n"
  fi
  
  if [[ -n "$error_details" ]]; then
    combined_errors+="$error_details\n"
  fi
  
  # Organiser les erreurs dans un ordre logique et supprimer les doublons et les lignes PASS
  if [[ -n "$combined_errors" ]]; then
    # D'abord, filtrer pour éliminer les lignes PASS
    local filtered_errors=$(echo -e "$combined_errors" | grep -v "PASS")
    
    # Ensuite, réorganiser pour avoir d'abord les fichiers FAIL, puis les détails
    local fail_files=$(echo "$filtered_errors" | grep "FAIL" | sort -u || echo "")
    local error_details=$(echo "$filtered_errors" | grep -E "^\s+at Object\." | sort -u || echo "")
    local other_errors=$(echo "$filtered_errors" | grep -v "FAIL" | grep -v -E "^\s+at Object\." | sort -u || echo "")
    
    # Reconstruire dans l'ordre logique (d'abord les fichiers FAIL, puis les détails)
    file_errors=""
    [[ -n "$fail_files" ]] && file_errors+="$fail_files\n"
    [[ -n "$error_details" ]] && file_errors+="$error_details\n"
    [[ -n "$other_errors" ]] && file_errors+="$other_errors\n"
    
    # Ne pas trier pour préserver l'ordre logique, mais limiter à 15 lignes et éliminer les doublons
    file_errors=$(echo -e "$file_errors" | awk '!seen[$0]++' | head -15)
  fi
  
  # Si rien n'est trouvé avec les patterns spécifiques, essayer une recherche plus générale
  if [[ -z "$file_errors" ]]; then
    # Chercher d'abord des chemins de fichiers typiques sans nécessairement être des chemins complets
    file_errors=$(echo "$output" | grep -E "src/[a-zA-Z0-9/_\.-]+\.[jt]sx?" | grep -v "PASS" | head -5)
    
    # Si toujours rien, chercher n'importe quel fichier suivi d'une erreur
    if [[ -z "$file_errors" ]]; then
      file_errors=$(echo "$output" | grep -E "\.[jt]sx?" | grep -E "error|Error|failed|Failed" | grep -v "PASS" | head -5)
    fi
  fi
  
  # Si on trouve des erreurs avec des chemins de fichiers, on les affiche
  if [[ -n "$file_errors" ]]; then
    ERRORS_SUMMARY+="$file_errors\n"
    
    # Compter le nombre total d'erreurs
    local total_errors=$(echo "$output" | grep -c -E "(error|failed)" || echo 0)
    
    # Si on a plus de 5 erreurs, on indique combien il en reste
    if [[ $total_errors -gt 5 ]]; then
      local remaining=$((total_errors - 5))
      if [[ $remaining -gt 0 ]]; then
        ERRORS_SUMMARY+="...et $remaining autres erreurs\n"
      fi
    fi
  else
    # Si on n'a pas trouvé d'erreurs avec des chemins de fichiers, on utilise une approche plus générique
    local general_errors=$(echo "$output" | grep -E "(error|Error|failed|Failed|TS[0-9]+:|ERROR)" | grep -v "PASS" | head -10)
    if [[ -n "$general_errors" ]]; then
      ERRORS_SUMMARY+="$general_errors\n"
      
      # Compter le nombre total d'erreurs générales avec un pattern plus inclusif
      local total_general=$(echo "$output" | grep -c -E "(error|Error|failed|Failed|TS[0-9]+:|ERROR)" || echo 0)
      
      # Si on a plus de 5 erreurs, on indique combien il en reste
      if [[ $total_general -gt 5 ]]; then
        local remaining_general=$((total_general - 5))
        if [[ $remaining_general -gt 0 ]]; then
          ERRORS_SUMMARY+="...et $remaining_general autres erreurs\n"
        fi
      fi
    fi
  fi
  
  # Fermer le bloc d'erreurs pour cette application
  ERRORS_SUMMARY+="\n"
  fi
}

# Désactiver l'arrêt sur erreur pour TOUT le script
set +e
set -o pipefail

# Variable pour indiquer si on a rencontré une erreur
HAS_ERROR=0
# Variable pour indiquer si on a fini l'exécution
EXECUTION_DONE=0

# Répertoire temporaire pour les résultats en mode parallèle
TEMP_DIR=$(mktemp -d)

# Fonction pour exécuter les checks sur une app
function run_app_checks {
  local APP="$1"
  local RESULT_FILE="$TEMP_DIR/${APP}.result"
  local OUTPUT_FILE="$TEMP_DIR/${APP}.output"
  
  # Initialiser le fichier de résultat
  echo "APP=$APP" > "$RESULT_FILE"
  
  pushd "$APP" > /dev/null 2>&1 || { 
    echo "STATUS=error" >> "$RESULT_FILE"
    echo "MESSAGE=Dossier introuvable" >> "$RESULT_FILE"
    return 1
  }

  # Construction de la commande
  local CMD=""
  
  if [[ "$APP" == "pdf-service" ]]; then
    if [[ "$RUN_LINT" == "true" ]] && [ -f "package.json" ] && grep -q "\"lint\"" package.json; then
      CMD+="yarn lint --fix"
    fi
    if [[ "$RUN_TYPECHECK" == "true" ]]; then
      [[ -n "$CMD" ]] && CMD+=" && "
      CMD+="yarn typecheck"
    fi
  else
    if [[ "$RUN_TESTS" == "true" ]]; then
      CMD+="yarn test:ci"
      # Turbo = max workers, sinon 50% pour laisser de la place aux autres apps
      if [[ "$TURBO_MODE" == "true" ]]; then
        CMD+=" --maxWorkers=75%"
      else
        CMD+=" --maxWorkers=50%"
      fi
      [[ "$ONLY_CHANGED" == "true" ]] && CMD+=" --onlyChanged"
      [[ "$WITH_COVERAGE" == "true" ]] && CMD+=" --coverage"
    fi
    if [[ "$RUN_LINT" == "true" ]]; then
      [[ -n "$CMD" ]] && CMD+=" && "
      CMD+="yarn lint --cache --fix"
    fi
    if [[ "$RUN_TYPECHECK" == "true" ]]; then
      [[ -n "$CMD" ]] && CMD+=" && "
      CMD+="yarn typecheck"
    fi
  fi
  
  if [[ -z "$CMD" ]]; then
    echo "STATUS=skipped" >> "$RESULT_FILE"
    popd > /dev/null
    return 0
  fi

  # Exécuter la commande
  local OUTPUT
  OUTPUT=$(bash -c "$CMD" 2>&1)
  local EXIT_CODE=$?
  echo "$OUTPUT" > "$OUTPUT_FILE"
  
  if [[ $EXIT_CODE -eq 0 ]]; then
    echo "STATUS=success" >> "$RESULT_FILE"
  else
    echo "STATUS=failed" >> "$RESULT_FILE"
  fi
  
  # Extraire stats de tests si applicable
  if [[ "$RUN_TESTS" == "true" && "$APP" != "pdf-service" ]]; then
    local TEST_SUITES=$(echo "$OUTPUT" | grep -E "^Test Suites:" | head -1 || echo "")
    local TEST_STATS=$(echo "$OUTPUT" | grep -E "^Tests:" | head -1 || echo "")
    [[ -z "$TEST_SUITES" ]] && TEST_SUITES=$(echo "$OUTPUT" | grep -E "Test Suites:" | head -1 || echo "")
    [[ -z "$TEST_STATS" ]] && TEST_STATS=$(echo "$OUTPUT" | grep -E "Tests:" | head -1 || echo "")
    # Quoter les valeurs pour éviter les problèmes avec les caractères spéciaux
    printf 'TEST_SUITES=%q\n' "$TEST_SUITES" >> "$RESULT_FILE"
    printf 'TEST_STATS=%q\n' "$TEST_STATS" >> "$RESULT_FILE"
  fi

  popd > /dev/null
  return $EXIT_CODE
}

# Définir une fonction pour capturer tous les signaux de sortie
function cleanup_and_exit {
  # Si on a déjà terminé l'exécution, ne rien faire
  if [[ $EXECUTION_DONE -eq 1 ]]; then
    return
  fi
  
  EXECUTION_DONE=1
  
  # S'assurer que ERRORS_SUMMARY a été initialisé, même s'il n'y a pas d'erreurs
  if [[ -z "$ERRORS_SUMMARY" ]]; then
    ERRORS_SUMMARY="Aucune erreur détectée"
  else
    # Supprimer les marqueurs d'applications avant d'afficher le résumé
    ERRORS_SUMMARY=$(echo "$ERRORS_SUMMARY" | sed 's/__[a-z-]*__//g')
  fi
  
  # Afficher le résumé
  print_summary
  
  # Sortir avec un code approprié (uniquement si la fonction est appelée via trap)
  # Si la fonction est appelée normalement à la fin du script, ne pas quitter
  if [[ ${FUNCNAME[1]} == "exit_trap" ]]; then
    if [[ $HAS_ERROR -eq 1 ]]; then
      echo -e "\n🔴 Terminé avec des erreurs"
      exit 1
    else
      echo -e "\n🟢 Tous les checks sont passés"
      exit 0
    fi
  fi
}

# Une fonction intermédiaire pour les traps
function exit_trap {
  cleanup_and_exit
  # Nettoyer le répertoire temporaire
  [[ -d "$TEMP_DIR" ]] && rm -rf "$TEMP_DIR"
}

# Définir les traps pour capturer toutes les façons de sortir du script
trap exit_trap EXIT INT TERM

# Exécution des checks
if [[ "$PARALLEL" == "true" ]]; then
  # Mode parallèle : lancer les apps par lots de MAX_PARALLEL
  echo "⚡ Lancement en parallèle ($MAX_PARALLEL à la fois)..."
  
  RUNNING_PIDS=()
  RUNNING_APPS=()
  
  for APP in "${APPS[@]}"; do
    # Lancer l'app en background
    run_app_checks "$APP" &
    RUNNING_PIDS+=($!)
    RUNNING_APPS+=("$APP")
    echo "   ▶ $APP lancé"
    
    # Si on atteint MAX_PARALLEL, attendre qu'un processus se termine
    while [[ ${#RUNNING_PIDS[@]} -ge $MAX_PARALLEL ]]; do
      # Attendre n'importe quel processus
      wait -n 2>/dev/null || true
      
      # Nettoyer les PIDs terminés
      NEW_PIDS=()
      NEW_APPS=()
      for i in "${!RUNNING_PIDS[@]}"; do
        if kill -0 "${RUNNING_PIDS[$i]}" 2>/dev/null; then
          NEW_PIDS+=("${RUNNING_PIDS[$i]}")
          NEW_APPS+=("${RUNNING_APPS[$i]}")
        fi
      done
      # Réassigner (gérer le cas où les tableaux sont vides)
      if [[ ${#NEW_PIDS[@]} -gt 0 ]]; then
        RUNNING_PIDS=("${NEW_PIDS[@]}")
        RUNNING_APPS=("${NEW_APPS[@]}")
      else
        RUNNING_PIDS=()
        RUNNING_APPS=()
      fi
    done
  done
  
  # Attendre les derniers processus
  for PID in "${RUNNING_PIDS[@]}"; do
    wait "$PID" 2>/dev/null || true
  done
  
  # Collecter les résultats
  for APP in "${APPS[@]}"; do
    RESULT_FILE="$TEMP_DIR/${APP}.result"
    OUTPUT_FILE="$TEMP_DIR/${APP}.output"
    
    if [[ ! -f "$RESULT_FILE" ]]; then
      RESULTS+="  ❌ $APP (pas de résultat)"$'\n'
      FAILURE_COUNT=$((FAILURE_COUNT + 1))
      HAS_ERROR=1
      continue
    fi
    
    # Initialiser les variables avant source (évite unbound variable)
    TEST_STATS=""
    TEST_SUITES=""
    STATUS=""
    MESSAGE=""
    
    source "$RESULT_FILE"
    
    case "$STATUS" in
      success)
        echo -e "✅ $APP: OK"
        RESULTS+="  ✅ $APP"$'\n'
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        ;;
      failed)
        echo -e "❌ $APP: Échec"
        RESULTS+="  ❌ $APP"$'\n'
        FAILURE_COUNT=$((FAILURE_COUNT + 1))
        HAS_ERROR=1
        [[ -f "$OUTPUT_FILE" ]] && verbose_output "$APP" "$(cat "$OUTPUT_FILE")"
        ;;
      skipped)
        echo -e "⏭️ $APP: Ignoré"
        RESULTS+="  ⏭️ $APP"$'\n'
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        ;;
      error)
        echo -e "❌ $APP: $MESSAGE"
        RESULTS+="  ❌ $APP ($MESSAGE)"$'\n'
        FAILURE_COUNT=$((FAILURE_COUNT + 1))
        HAS_ERROR=1
        ;;
    esac
    
    # Collecter stats de tests et couverture
    if [[ "$RUN_TESTS" == "true" && "$APP" != "pdf-service" && -f "$OUTPUT_FILE" ]]; then
      [[ -n "$TEST_STATS" ]] && TESTS_SUMMARY+="  $APP : $TEST_STATS"$'\n'
      [[ -n "$TEST_SUITES" ]] && TESTS_SUMMARY+="         $TEST_SUITES"$'\n'
      [[ "$WITH_COVERAGE" == "true" ]] && extract_coverage "$(cat "$OUTPUT_FILE")" "$APP"
    fi
  done
  
else
  # Mode séquentiel (par défaut)
  for APP in "${APPS[@]}"; do
    echo -e "🔄 $APP..."
    pushd "$APP" > /dev/null || { echo "❌ $APP: Dossier introuvable"; RESULTS+="  ❌ $APP (introuvable)"$'\n'; FAILURE_COUNT=$((FAILURE_COUNT + 1)); HAS_ERROR=1; continue; }

    # Construction de la commande
    CMD=""
    
    if [[ "$APP" == "pdf-service" ]]; then
      if [[ "$RUN_LINT" == "true" ]] && [ -f "package.json" ] && grep -q "\"lint\"" package.json; then
        CMD+="yarn lint --fix"
      fi
      if [[ "$RUN_TYPECHECK" == "true" ]]; then
        [[ -n "$CMD" ]] && CMD+=" && "
        CMD+="yarn typecheck"
      fi
    else
      if [[ "$RUN_TESTS" == "true" ]]; then
        CMD+="yarn test:ci"
        [[ "$ONLY_CHANGED" == "true" ]] && CMD+=" --onlyChanged"
        [[ "$WITH_COVERAGE" == "true" ]] && CMD+=" --coverage"
      fi
      if [[ "$RUN_LINT" == "true" ]]; then
        [[ -n "$CMD" ]] && CMD+=" && "
        CMD+="yarn lint --cache --fix"
      fi
      if [[ "$RUN_TYPECHECK" == "true" ]]; then
        [[ -n "$CMD" ]] && CMD+=" && "
        CMD+="yarn typecheck"
      fi
    fi
    
    if [[ -z "$CMD" ]]; then
      echo "⏭️ $APP: Ignoré"
      RESULTS+="  ⏭️ $APP"$'\n'
      SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
      popd > /dev/null
      continue
    fi

    if [[ "$VERBOSE" == "true" ]]; then
      OUTPUT=$(bash -c "$CMD" 2>&1 | tee /dev/tty)
      EXIT_CODE=${PIPESTATUS[0]}
    else
      OUTPUT=$(bash -c "$CMD" 2>&1)
      EXIT_CODE=$?
      if [[ $EXIT_CODE -eq 0 ]]; then
        echo -e "✅ $APP: OK"
      else
        echo -e "❌ $APP: Échec"
      fi
    fi

    # Extraire stats de tests
    TEST_STATS=""
    TEST_SUITES=""
    if [[ "$RUN_TESTS" == "true" && "$APP" != "pdf-service" ]]; then
      TEST_SUITES=$(echo "$OUTPUT" | grep -E "^Test Suites:" | head -1 || echo "")
      TEST_STATS=$(echo "$OUTPUT" | grep -E "^Tests:" | head -1 || echo "")
      [[ -z "$TEST_SUITES" ]] && TEST_SUITES=$(echo "$OUTPUT" | grep -E "Test Suites:" | head -1 || echo "")
      [[ -z "$TEST_STATS" ]] && TEST_STATS=$(echo "$OUTPUT" | grep -E "Tests:" | head -1 || echo "")
    fi
    
    if [[ $EXIT_CODE -eq 0 ]]; then
      RESULTS+="  ✅ $APP"$'\n'
      SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
      RESULTS+="  ❌ $APP"$'\n'
      FAILURE_COUNT=$((FAILURE_COUNT + 1))
      HAS_ERROR=1
      verbose_output "$APP" "$OUTPUT"
    fi
    
    # Collecter stats de tests et couverture
    if [[ "$RUN_TESTS" == "true" && "$APP" != "pdf-service" ]]; then
      [[ -n "$TEST_STATS" ]] && TESTS_SUMMARY+="  $APP : $TEST_STATS"$'\n'
      [[ -n "$TEST_SUITES" ]] && TESTS_SUMMARY+="         $TEST_SUITES"$'\n'
      [[ "$WITH_COVERAGE" == "true" ]] && extract_coverage "$OUTPUT" "$APP"
    fi

    popd > /dev/null || { echo "❌ Erreur de navigation"; continue; }
  done
fi

# Garder l'arrêt sur erreur désactivé pour que le script continue même en cas d'erreur
# set -e

# Vérifier qu'au moins une application a été vérifiée
if [[ $((SUCCESS_COUNT + FAILURE_COUNT)) -eq 0 ]]; then
  echo -e "\n⚠️ Aucune app vérifiée. Vérifiez le nom des apps spécifiées."
  HAS_ERROR=1
fi

# Indiquer que l'exécution normale est terminée
# Le résumé sera affiché via le trap EXIT
