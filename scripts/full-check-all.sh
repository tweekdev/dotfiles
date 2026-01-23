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

# Options de configuration
VERBOSE="false"
RUN_TESTS="true"
RUN_LINT="true"
RUN_TYPECHECK="true"
SPECIFIC_APPS=()

# Affichage de l'aide
function show_help {
  echo "Usage: $0 [options] [app1 app2 ...]"
  echo "Options:"
  echo "  --verbose         Active le mode verbeux (affiche les sorties en temps réel)"
  echo "  --no-tests        Ignore les tests unitaires"
  echo "  --no-lint         Ignore les vérifications de lint"
  echo "  --no-typecheck    Ignore les vérifications de types"
  echo "  --only-lint       Exécute uniquement les vérifications de lint"
  echo "  --only-typecheck  Exécute uniquement les vérifications de types"
  echo "  --only-tests      Exécute uniquement les tests unitaires"
  echo "  --help            Affiche cette aide"
  echo ""
  echo "Si des noms d'applications sont spécifiés après les options, seules ces applications seront vérifiées."
  echo "Applications disponibles: ${APPS[*]}"
  exit 0
}

# Traitement des arguments
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
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
  echo "Vérification uniquement pour les applications: ${APPS[*]}"
fi

# Affichage des options sélectionnées
echo "🔍 Mode $([ "$VERBOSE" == "true" ] && echo "VERBOSE" || echo "NON-VERBOSE") activé"
[ "$RUN_TESTS" == "false" ] && echo "⏭️ Tests IGNORÉS"
[ "$RUN_LINT" == "false" ] && echo "⏭️ Lint IGNORÉ"
[ "$RUN_TYPECHECK" == "false" ] && echo "⏭️ Typecheck IGNORÉ"

# Fonction pour afficher le résumé final
function print_summary {
  echo -e "\n============================="
  echo -e "📊 Résumé des checks :"
  echo -e "============================="
  printf "%b" "$RESULTS"
  
  echo -e "\n============================="
  echo -e "🔍 Détails sur les tests par application :"
  echo -e "============================="
  echo -e "✅ Tests réussis total : $SUCCESS_COUNT / $((SUCCESS_COUNT + FAILURE_COUNT))"
  printf "%b" "$TESTS_SUMMARY"
  
  echo -e "\n============================="
  echo -e "💼 Couverture par application :"
  echo -e "============================="
  printf "%b" "$COVERAGE_SUMMARY"
  
  if [[ -n "$ERRORS_SUMMARY" ]]; then
    echo -e "\n============================="
    echo -e "❌ Erreurs par application :"
    echo -e "============================="
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
  # Format exact observé dans le projet: /Users/tweekdev/Developer/travauxlib/pro/src/components/StatusTagsDevis.tsx
  local full_path_pattern="/Users/tweekdev/Developer/travauxlib/[a-zA-Z0-9/_\.-]+\.[jt]sx?"
  
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
  combined_errors=""
  
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
      exit 1
    else
      exit 0
    fi
  fi
}

# Une fonction intermédiaire pour les traps
function exit_trap {
  cleanup_and_exit
}

# Définir les traps pour capturer toutes les façons de sortir du script
trap exit_trap EXIT INT TERM

# Exécution des checks
for APP in "${APPS[@]}"; do
  echo -e "\n🚀 Checking $APP..."
  pushd "$APP" > /dev/null || { echo "❌ Impossible d'accéder au répertoire $APP"; continue; }

  # Construction de la commande en fonction des options
  CMD=""
  
  if [[ "$APP" == "pdf-service" ]]; then
    # Cas spécial pour pdf-service qui n'a pas de tests
    if [[ "$RUN_LINT" == "true" ]] && [ -f "package.json" ] && grep -q "\"lint\"" package.json; then
      CMD+="yarn lint --fix"
    fi
    
    if [[ "$RUN_TYPECHECK" == "true" ]]; then
      [[ -n "$CMD" ]] && CMD+="&& "
      CMD+="yarn typecheck"
    fi
  else
    # Pour les autres applications
    if [[ "$RUN_TESTS" == "true" ]]; then
      CMD+="yarn test:ci --coverage"
    fi
    
    if [[ "$RUN_LINT" == "true" ]]; then
      [[ -n "$CMD" ]] && CMD+="&& "
      CMD+="yarn lint --fix"
    fi
    
    if [[ "$RUN_TYPECHECK" == "true" ]]; then
      [[ -n "$CMD" ]] && CMD+="&& "
      CMD+="yarn typecheck"
    fi
  fi
  
  # Si aucune commande n'est configurée, on saute cette application mais on l'enregistre comme succès
  if [[ -z "$CMD" ]]; then
    echo "⏭️ Tous les checks sont ignorés pour $APP"
    RESULTS+="$APP: ✅ Ignoré"$'\n'
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    popd > /dev/null
    continue
  fi

  if [[ "$VERBOSE" == "true" ]]; then
    echo -e "\n🔍 Exécution de la commande : $CMD"
    # En mode verbose, exécute la commande mais capture le code de sortie
    # en utilisant set +e pour empêcher le script de s'arrêter en cas d'erreur
    set +e
    bash -c "$CMD"
    EXIT_CODE=$?
    set -e
    # Garder une trace de la sortie pour l'affichage du résumé
    OUTPUT="Sortie déjà affichée en temps réel"
  else
    # En mode non-verbose, capture la sortie dans une variable
    # Désactiver temporairement l'arrêt sur erreur
    set +e
    OUTPUT=$(bash -c "$CMD" 2>&1)
    EXIT_CODE=$?
    # Ne pas réactiver l'arrêt sur erreur ici car nous voulons continuer même en cas d'erreur
    echo -e "\n🕐 $APP: Commande terminée avec code $EXIT_CODE"
  fi

  # Extraire le nombre de tests
  TEST_STATS=""
  TEST_SUITES=""
  if [[ "$APP" != "pdf-service" ]]; then
    # Capturer le format exact des tests de Jest
    TEST_SUITES=$(echo "$OUTPUT" | grep -E "^Test Suites:" | head -1 || echo "")
    TEST_STATS=$(echo "$OUTPUT" | grep -E "^Tests:" | head -1 || echo "")
    
    # Si aucun résultat n'est trouvé, essayer un pattern plus général
    if [[ -z "$TEST_SUITES" && -z "$TEST_STATS" ]]; then
      TEST_SUITES=$(echo "$OUTPUT" | grep -E "Test Suites:" | head -1 || echo "")
      TEST_STATS=$(echo "$OUTPUT" | grep -E "Tests:" | head -1 || echo "")
    fi
    
    # Si toujours rien, indiquer qu'aucun test n'a été détecté
    if [[ -z "$TEST_STATS" ]]; then
      TEST_STATS="Pas de tests détectés"
    fi
  fi
  
  if [[ $EXIT_CODE -eq 0 ]]; then
    RESULTS+="$APP: ✅ Success"$'\n'
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    
    # Collecte des informations pour toutes les applications (pas seulement en cas de succès)
    if [[ "$APP" != "pdf-service" ]]; then
      # Recherche de la couverture dans le format exact de Jest
      COVERAGE_RAW=$(echo "$OUTPUT" | grep -E "^All files" | head -1 || echo "Pas de couverture détectée")
      
      # Formater la couverture pour un affichage plus propre
      if [[ "$COVERAGE_RAW" != "Pas de couverture détectée" ]]; then
        # Extraire les pourcentages de la ligne (pattern: | XX.XX | XX.XX | XX.XX | XX.XX |)
        STMTS=$(echo "$COVERAGE_RAW" | grep -o -E "\|\s+[0-9]+\.[0-9]+\s+\|" | head -1 | tr -d '|' | tr -d ' ')
        BRANCH=$(echo "$COVERAGE_RAW" | grep -o -E "\|\s+[0-9]+\.[0-9]+\s+\|" | head -2 | tail -1 | tr -d '|' | tr -d ' ')
        FUNCS=$(echo "$COVERAGE_RAW" | grep -o -E "\|\s+[0-9]+\.[0-9]+\s+\|" | head -3 | tail -1 | tr -d '|' | tr -d ' ')
        LINES=$(echo "$COVERAGE_RAW" | grep -o -E "\|\s+[0-9]+\.[0-9]+\s+\|" | head -4 | tail -1 | tr -d '|' | tr -d ' ')
        
        # Si l'extraction a fonctionné, afficher un format propre
        if [[ -n "$STMTS" && -n "$BRANCH" && -n "$FUNCS" && -n "$LINES" ]]; then
          COVERAGE="Stmts: $STMTS%, Branch: $BRANCH%, Funcs: $FUNCS%, Lines: $LINES%"
        else
          # Méthode alternative d'extraction
          STMTS=$(echo "$COVERAGE_RAW" | awk -F '|' '{print $2}' | tr -d ' ')
          BRANCH=$(echo "$COVERAGE_RAW" | awk -F '|' '{print $3}' | tr -d ' ')
          FUNCS=$(echo "$COVERAGE_RAW" | awk -F '|' '{print $4}' | tr -d ' ')
          LINES=$(echo "$COVERAGE_RAW" | awk -F '|' '{print $5}' | tr -d ' ')
          
          if [[ -n "$STMTS" && -n "$BRANCH" && -n "$FUNCS" && -n "$LINES" ]]; then
            COVERAGE="Stmts: $STMTS%, Branch: $BRANCH%, Funcs: $FUNCS%, Lines: $LINES%"
          else
            # Si tout échoue, simplement retirer les espaces excessifs
            COVERAGE=$(echo "$COVERAGE_RAW" | tr -s ' ' | tr -s '|' | sed 's/All files/All files:/')
          fi
        fi
      else
        COVERAGE="$COVERAGE_RAW"
      fi
      
      COVERAGE_SUMMARY+="$APP : $COVERAGE"$'\n'
      
      # Ajouter les stats de tests au résumé
      if [[ -n "$TEST_STATS" ]]; then
        TESTS_SUMMARY+="$APP : $TEST_STATS"$'\n'
        if [[ -n "$TEST_SUITES" ]]; then
          TESTS_SUMMARY+="       $TEST_SUITES"$'\n'
        fi
      fi
    fi
  else
    RESULTS+="$APP: ❌ Failed"$'\n'
    FAILURE_COUNT=$((FAILURE_COUNT + 1))
    HAS_ERROR=1
    
    # Ajouter quand même les stats de tests au résumé même en cas d'échec
    if [[ "$APP" != "pdf-service" && -n "$TEST_STATS" ]]; then
      TESTS_SUMMARY+="$APP : $TEST_STATS"$'\n'
      if [[ -n "$TEST_SUITES" ]]; then
        TESTS_SUMMARY+="       $TEST_SUITES"$'\n'
      fi
    fi
    
    # Afficher les erreurs en mode verbose et les enregistrer pour le résumé
    verbose_output "$APP" "$OUTPUT"
    
    # Extraire des informations de couverture même en cas d'échec
    if [[ "$APP" != "pdf-service" ]]; then
      # Recherche de la couverture dans le format exact de Jest
      COVERAGE_RAW=$(echo "$OUTPUT" | grep -E "^All files" | head -1 || echo "Pas de couverture détectée")
      
      # Formater la couverture pour un affichage plus propre
      if [[ "$COVERAGE_RAW" != "Pas de couverture détectée" ]]; then
        # Extraire les pourcentages de la ligne (pattern: | XX.XX | XX.XX | XX.XX | XX.XX |)
        STMTS=$(echo "$COVERAGE_RAW" | grep -o -E "\|\s+[0-9]+\.[0-9]+\s+\|" | head -1 | tr -d '|' | tr -d ' ')
        BRANCH=$(echo "$COVERAGE_RAW" | grep -o -E "\|\s+[0-9]+\.[0-9]+\s+\|" | head -2 | tail -1 | tr -d '|' | tr -d ' ')
        FUNCS=$(echo "$COVERAGE_RAW" | grep -o -E "\|\s+[0-9]+\.[0-9]+\s+\|" | head -3 | tail -1 | tr -d '|' | tr -d ' ')
        LINES=$(echo "$COVERAGE_RAW" | grep -o -E "\|\s+[0-9]+\.[0-9]+\s+\|" | head -4 | tail -1 | tr -d '|' | tr -d ' ')
        
        # Si l'extraction a fonctionné, afficher un format propre
        if [[ -n "$STMTS" && -n "$BRANCH" && -n "$FUNCS" && -n "$LINES" ]]; then
          COVERAGE="Stmts: $STMTS%, Branch: $BRANCH%, Funcs: $FUNCS%, Lines: $LINES%"
        else
          # Méthode alternative d'extraction
          STMTS=$(echo "$COVERAGE_RAW" | awk -F '|' '{print $2}' | tr -d ' ')
          BRANCH=$(echo "$COVERAGE_RAW" | awk -F '|' '{print $3}' | tr -d ' ')
          FUNCS=$(echo "$COVERAGE_RAW" | awk -F '|' '{print $4}' | tr -d ' ')
          LINES=$(echo "$COVERAGE_RAW" | awk -F '|' '{print $5}' | tr -d ' ')
          
          if [[ -n "$STMTS" && -n "$BRANCH" && -n "$FUNCS" && -n "$LINES" ]]; then
            COVERAGE="Stmts: $STMTS%, Branch: $BRANCH%, Funcs: $FUNCS%, Lines: $LINES%"
          else
            # Si tout échoue, simplement retirer les espaces excessifs
            COVERAGE=$(echo "$COVERAGE_RAW" | tr -s ' ' | tr -s '|' | sed 's/All files/All files:/')
          fi
        fi
        
        COVERAGE_SUMMARY+="$APP : $COVERAGE"$'\n'
      fi
    fi
    
    # Afficher les erreurs en mode verbose et les enregistrer pour le résumé
    verbose_output "$APP" "$OUTPUT"
  fi

  popd > /dev/null || { echo "❌ Retour impossible au dossier parent depuis $APP"; continue; }
done

# Garder l'arrêt sur erreur désactivé pour que le script continue même en cas d'erreur
# set -e

# S'assurer qu'il y a toujours un résumé à afficher, même si aucune application n'a été vérifiée
if [[ $((SUCCESS_COUNT + FAILURE_COUNT)) -eq 0 ]]; then
  echo -e "\n⚠️ Aucune application n'a été vérifiée. Vérifiez vos options ou le nom des applications spécifiées."
  HAS_ERROR=1
fi

# Indiquer que l'exécution normale est terminée
# Le résumé sera affiché parsuccess_count=0
faisuccess_count + failhas_eexitvia le trap EXIT
