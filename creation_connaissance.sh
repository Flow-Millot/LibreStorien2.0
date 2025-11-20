#!/usr/bin/env bash
set -euo pipefail

################################
# Couleurs console ANSI
################################
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
RESET="\033[0m"

##############################
# Fonctions utilitaires      #
##############################

# Fonctions d’affichage coloré
info()    { echo -e "${CYAN}$*${RESET}"; }
success() { echo -e "${GREEN}$*${RESET}"; }
warn()    { echo -e "${YELLOW}$*${RESET}"; }
error()   { echo -e "${RED}$*${RESET}" >&2; }

########################################
# 0. Configuration de base
########################################

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$PROJECT_DIR/docs"

KNOW_NAME="Documents Montpellibre"
KNOW_DESC="Connaissance contenant les documents officiels de l'association Montpellibre (statuts, rapports, PV d’AG, AAP, etc.)"

# URL par défaut d'OpenWebUI (peut être changée à l'exécution)
DEFAULT_OPENWEBUI_URL="http://127.0.0.1:8080"
OPENWEBUI_URL="${OPENWEBUI_URL:-$DEFAULT_OPENWEBUI_URL}"

########################################
# 1. Fonctions utilitaires
########################################

die() {
  error "[Erreur] $*" >&2
  exit 1
}

detect_pkg_manager() {
  if command -v apt >/dev/null 2>&1; then
    info "apt"
  elif command -v dnf >/dev/null 2>&1; then
    info "dnf"
  elif command -v pacman >/dev/null 2>&1; then
    info "pacman"
  elif command -v brew >/dev/null 2>&1; then
    info "brew"
  else
    info ""
  fi
}

ensure_cmd() {
  local cmd="$1"
  local pkg="$2"

  if command -v "$cmd" >/dev/null 2>&1; then
    return 0
  fi

  warn "[LibreStorien] Commande '$cmd' introuvable. Tentative d'installation du paquet '$pkg'..."

  local pm
  pm="$(detect_pkg_manager)"

  case "$pm" in
    apt)
      sudo apt update
      sudo apt install -y "$pkg"
      ;;
    dnf)
      sudo dnf install -y "$pkg"
      ;;
    pacman)
      sudo pacman -Sy --noconfirm "$pkg"
      ;;
    brew)
      brew install "$pkg"
      ;;
    *)
      die "Impossible d'installer automatiquement '$pkg'. Installer manuellement puis relancer."
      ;;
  esac

  if ! command -v "$cmd" >/dev/null 2>&1; then
    die "La commande '$cmd' reste introuvable après installation."
  fi
}

########################################
# 2. Vérification des dépendances
########################################

ensure_cmd curl curl
ensure_cmd jq jq

# Vérifier l'existence du dossier docs, le créer si besoin
if [[ ! -d "$DOCS_DIR" ]]; then
  warn "[LibreStorien] Le dossier docs/ n'existe pas encore. Création dans : $DOCS_DIR"
  mkdir -p "$DOCS_DIR"
fi

# Vérifier qu'il contient bien des fichiers
if ! ls "$DOCS_DIR"/* >/dev/null 2>&1; then
  die "Le dossier docs/ est vide ($DOCS_DIR). Ajouter les documents à indexer avant de lancer ce script."
fi

########################################
# 3. Lecture des paramètres utilisateur
########################################

info "[LibreStorien] Configuration de la connexion à OpenWebUI"

if [[ -z "${OPENWEBUI_JWT:-}" ]]; then
  info "Tu peux récupérer ton JWT dans OpenWebUI : Réglages -> Compte -> Clés d'API -> Copier le JWT."
  read -r -p "JWT OpenWebUI (coller ici) : " OPENWEBUI_JWT
fi

if [[ -z "${OPENWEBUI_JWT:-}" ]]; then
  die "Aucun JWT fourni. Abandon."
fi

AUTH_HEADER="Authorization: Bearer $OPENWEBUI_JWT"

########################################
# 4. Vérifier que l'API OpenWebUI répond
########################################

echo
info "[LibreStorien] Vérification de la disponibilité de l'API OpenWebUI ($OPENWEBUI_URL)..."

HEALTH_OK=false

# On essaie /api/v1/system/health puis /api/config en fallback
for i in {1..10}; do
  status="$(curl -sS -o /dev/null -w "%{http_code}" \
    -H "$AUTH_HEADER" \
    "$OPENWEBUI_URL/api/v1/system/health" || true)"

  if [[ "$status" == "200" ]]; then
    HEALTH_OK=true
    break
  fi

  status_cfg="$(curl -sS -o /dev/null -w "%{http_code}" \
    -H "$AUTH_HEADER" \
    "$OPENWEBUI_URL/api/config" || true)"

  if [[ "$status_cfg" == "200" ]]; then
    HEALTH_OK=true
    break
  fi

  warn "[LibreStorien] API non joignable (tentative $i/10). Nouvelle tentative dans 2 secondes..."
  sleep 2
done

if [[ "$HEALTH_OK" != true ]]; then
  die "Impossible de joindre l'API OpenWebUI. Vérifie que ton premier launcher tourne bien et que l'URL est correcte."
fi

success "[LibreStorien] API disponible."

########################################
# 5. Création ou réutilisation de la Connaissance
########################################

read -r -p "[LibreStorien] Donner un nom à la nouvelle Connaissance (appuie sur Entrée pour utiliser '$KNOW_NAME') : " USER_INPUT
KNOW_NAME="${USER_INPUT:-$KNOW_NAME}"

echo
info "[LibreStorien] Vérification de l'existence de la Connaissance '$KNOW_NAME'..."

# Récupérer la liste des connaissances existantes
knowledge_list_resp="$(curl -sS -H "$AUTH_HEADER" "$OPENWEBUI_URL/api/v1/knowledge/" || true)"

existing_ids=()
if [[ -n "$knowledge_list_resp" ]]; then
  # On extrait les connaissances dont le nom correspond exactement,
  # en gérant à la fois le cas tableau et le cas { "data": [ ... ] }
  mapfile -t existing_ids < <(
    echo "$knowledge_list_resp" \
      | jq -r --arg name "$KNOW_NAME" '
          if type == "array" then
            .[]? | select(.name == $name) | .id
          elif .data then
            .data[]? | select(.name == $name) | .id
          else
            empty
          end
        '
  )
fi

if (( ${#existing_ids[@]} > 0 )); then
  # Si on a trouvé au moins une connaissance avec ce nom, on prend la première
  KNOW_ID="${existing_ids[0]}"
  warn "[LibreStorien] Connaissance '$KNOW_NAME' déjà existante."
  info "[LibreStorien] Arrêt du script."
  exit 0
else
  info "[LibreStorien] Aucune Connaissance existante avec ce nom. Création..."

  create_payload="$(jq -n \
    --arg name "$KNOW_NAME" \
    --arg desc "$KNOW_DESC" \
    '{name: $name, description: $desc}')"

  resp="$(curl -sS -X POST "$OPENWEBUI_URL/api/v1/knowledge/create" \
    -H "$AUTH_HEADER" \
    -H "Content-Type: application/json" \
    -d "$create_payload")"

  KNOW_ID="$(echo "$resp" | jq -r '.id // .data.id // empty')"

  if [[ -z "$KNOW_ID" || "$KNOW_ID" == "null" ]]; then
    info "[LibreStorien] Réponse de l'API lors de la création de la Connaissance :"
    echo "$resp"
    die "Impossible de récupérer l'ID de la Connaissance."
  fi

  success "[LibreStorien] Connaissance créée avec ID : $KNOW_ID"
fi

########################################
# 7. Upload des fichiers dans la Connaissance
########################################

echo
info "[LibreStorien] Upload des fichiers PDF depuis '$DOCS_DIR' et attachement à la Connaissance..."

# Activer nullglob pour éviter que *.pdf se résolve littéralement en "*.pdf" si aucun fichier
shopt -s nullglob

pdf_files=("$DOCS_DIR"/*.pdf)

if (( ${#pdf_files[@]} == 0 )); then
  die "Aucun fichier .pdf trouvé dans $DOCS_DIR. Ajoute des PDF puis relance ce script."
fi

for FILE_PATH in "${pdf_files[@]}"; do
  if [[ ! -f "$FILE_PATH" ]]; then
    continue
  fi

  FILE_NAME="$(basename "$FILE_PATH")"
  info "[LibreStorien] -> Upload du fichier : $FILE_NAME"

  upload_resp="$(curl -sS -X POST "$OPENWEBUI_URL/api/v1/files/" \
    -H "$AUTH_HEADER" \
    -F "file=@${FILE_PATH}")"

  FILE_ID="$(echo "$upload_resp" | jq -r '.id // .data.id // empty')"

  if [[ -z "$FILE_ID" || "$FILE_ID" == "null" ]]; then
    info "[LibreStorien] Réponse de l'API lors de l'upload du fichier $FILE_NAME :"
    echo "$upload_resp"
    die "Impossible de récupérer l'ID du fichier."
  fi

  success "   Fichier uploadé avec ID : $FILE_ID"
  info "   Attachement du fichier à la Connaissance..."

  attach_payload="$(jq -n --arg file_id "$FILE_ID" '{file_id: $file_id}')"

  attach_resp="$(curl -sS -X POST "$OPENWEBUI_URL/api/v1/knowledge/$KNOW_ID/file/add" \
    -H "$AUTH_HEADER" \
    -H "Content-Type: application/json" \
    -d "$attach_payload")"

  attach_ok="$(echo "$attach_resp" | jq -r '.status // .message // empty' || true)"
  if [[ -n "$attach_ok" ]]; then
    echo "   Réponse API (attachement) : $attach_ok"
  fi

    info "   Vérification de la fin du traitement du fichier..."

  # Boucle d’attente active : on surveille l’apparition du FILE_ID dans file_ids
  for i in {1..5}; do
    check_resp="$(curl -sS -H "$AUTH_HEADER" "$OPENWEBUI_URL/api/v1/knowledge/$KNOW_ID")"

    # On vérifie si le FILE_ID est présent dans la liste des fichiers indexés
    is_indexed="$(echo "$check_resp" | jq -r --arg fid "$FILE_ID" '
      if .data and .data.file_ids then
        (.data.file_ids[] | select(. == $fid)) // empty
      else
        empty
      end
    ')"

    if [[ -n "$is_indexed" ]]; then
      success "   Le fichier est maintenant indexé."
      break
    fi

    warn "   Indexation en cours..."
    sleep 5
  done
done

# Désactiver nullglob si tu veux revenir au comportement par défaut
shopt -u nullglob

success "[LibreStorien] Tous les fichiers du dossier docs/ ont été traités."
info "[LibreStorien] L'API d'OpenWebUI ne permet pas encore d'automatiser la création du modèle basé sur la Connaissance."
warn "[LibreStorien] Merci de suivre le README associé pour l'étape suivante"