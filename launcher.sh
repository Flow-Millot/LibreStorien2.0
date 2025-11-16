#!/usr/bin/env bash
set -euo pipefail

#############################
# Configuration du projet   #
#############################

# Dossier du projet (et de ce script)
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Dossier de la venv
VENV_DIR="$PROJECT_DIR/.venv"

# Port du serveur llama.cpp (llama-cpp-python[server])
LLAMA_PORT=10000

# Port d’OpenWebUI
OPENWEBUI_PORT=8080

# Modèle GGUF à utiliser
MODEL_FILE="phi-4-Q4_K_M.gguf" # <-- POSSIBILITE D'ADAPTER LE NOM DU FICHIER
HF_URL="https://huggingface.co/unsloth/phi-4-GGUF/resolve/main/${MODEL_FILE}" # <-- POSSIBILITE D'ADAPTER LE NOM DU FICHIER

MODEL_PATH="models/${MODEL_FILE}" 

# PIDs des services lancés par ce script
LLAMA_PID=""
OPENWEBUI_PID=""

##############################
# Fonctions utilitaires      #
##############################

# Fonction de nettoyage à la fin
cleanup() {
  echo "[LibreStorien] Arrêt des services..."

  if [[ -n "${LLAMA_PID:-}" ]]; then
    if kill "$LLAMA_PID" >/dev/null 2>&1; then
      echo "[LibreStorien] llama_cpp.server arrêté (PID $LLAMA_PID)."
    fi
  fi

  if [[ -n "${OPENWEBUI_PID:-}" ]]; then
    if kill "$OPENWEBUI_PID" >/dev/null 2>&1; then
      echo "[LibreStorien] OpenWebUI arrêté (PID $OPENWEBUI_PID)."
    fi
  fi
}
# Nettoyage quand le script se termine ou lors d'un Ctrl+C
trap cleanup EXIT INT TERM

################################
# Vérification / installation de Python 3.11
################################

PYTHON_BIN="python3.11"

if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
    echo "[LibreStorien] python3.11 introuvable. Tentative d'installation..."

    # --- Ubuntu / Debian ---
    if command -v apt >/dev/null 2>&1; then
        sudo apt update
        sudo apt install -y software-properties-common
        sudo add-apt-repository -y ppa:deadsnakes/ppa
        sudo apt update
        sudo apt install -y python3.11 python3.11-venv python3.11-distutils

    # --- Fedora ---
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y python3.11 python3.11-devel

    # --- Arch Linux ---
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -Sy --noconfirm python311

    # --- macOS (Homebrew) ---
    elif command -v brew >/dev/null 2>&1; then
        brew install python@3.11
        brew link python@3.11 --force

    else
        echo "[ERREUR] Impossible d'installer python3.11 automatiquement (OS non détecté)."
        echo "Installe python3.11 manuellement puis relance."
        exit 1
    fi

    # Re-vérifier
    if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
        echo "[ERREUR] python3.11 n'a pas pu être installé."
        exit 1
    fi
fi

echo "[LibreStorien] python3.11 disponible : $(which python3.11)"

################################
# 1. Création / activation venv #
################################

if [[ ! -d "$VENV_DIR" ]]; then
  echo "[LibreStorien] Création de la venv Python avec $PYTHON_BIN..."
  "$PYTHON_BIN" -m venv "$VENV_DIR"
  source "$VENV_DIR/bin/activate"
  python -m pip install --upgrade pip

  echo "[LibreStorien] Installation des dépendances..."
  python -m pip install "llama-cpp-python[server]" open-webui
else
  echo "[LibreStorien] Activation de la venv existante..."
  source "$VENV_DIR/bin/activate"

  # Vérif rapide que les paquets sont là (sinon installation)
  if ! python -c "import llama_cpp" >/dev/null 2>&1; then
    echo "[LibreStorien] Installation de llama-cpp-python[server]..."
    python -m pip install "llama-cpp-python[server]"
  fi

  if ! command -v open-webui >/dev/null 2>&1; then
    echo "[LibreStorien] Installation de open-webui..."
    python -m pip install open-webui
  fi
fi

########################################
# 2. Lancer le serveur llama.cpp       #
########################################

if [[ ! -f "$MODEL_PATH" ]]; then
  echo "[LibreStorien] Modèle introuvable localement, téléchargement depuis Hugging Face..."
  mkdir -p "$(dirname "$MODEL_PATH")"

  DL_TOOL=""

  if command -v curl >/dev/null 2>&1; then
    DL_TOOL="curl"
  elif command -v wget >/dev/null 2>&1; then
    DL_TOOL="wget"
  else
    echo "[LibreStorien] Ni curl ni wget détecté, tentative d'installation..."

    if command -v apt >/dev/null 2>&1; then
      sudo apt update
      sudo apt install -y curl
      DL_TOOL="curl"
    elif command -v dnf >/dev/null 2>&1; then
      sudo dnf install -y curl
      DL_TOOL="curl"
    elif command -v pacman >/dev/null 2>&1; then
      sudo pacman -Sy --noconfirm curl
      DL_TOOL="curl"
    elif command -v brew >/dev/null 2>&1; then
      brew install curl
      DL_TOOL="curl"
    else
      echo "[ERREUR] Impossible d'installer curl/wget automatiquement. Installer l’un des deux puis relancer."
      exit 1
    fi
  fi

  echo "[LibreStorien] Téléchargement du modèle depuis : $HF_URL"
  if [[ "$DL_TOOL" == "curl" ]]; then
    curl -L "$HF_URL" -o "$MODEL_PATH"
  else
    wget -O "$MODEL_PATH" "$HF_URL"
  fi

  if [[ ! -f "$MODEL_PATH" ]]; then
    echo "[ERREUR] Échec du téléchargement du modèle depuis $HF_URL"
    exit 1
  fi

  echo "[LibreStorien] Modèle téléchargé : $MODEL_PATH"
fi

# On vérifie si un serveur llama.cpp tourne déjà sur le port défini
if pgrep -f "llama_cpp.server" >/dev/null 2>&1; then
  echo "[LibreStorien] llama_cpp.server est déjà en cours d’exécution."
else
    echo "[LibreStorien] Lancement de llama_cpp.server..."
    cd "$PROJECT_DIR"
    python -m llama_cpp.server \
        --model "$MODEL_PATH" \
        --host 127.0.0.1 \
        --port "$LLAMA_PORT" \
        --n_gpu_layers 999 \
        --n_ctx 8192 \
        > "$PROJECT_DIR/log_llamacpp.txt" 2>&1 &

    LLAMA_PID=$!
    echo "[LibreStorien] llama_cpp.server lancé (PID $LLAMA_PID)."
    sleep 3
fi

########################################
# 3. Lancer OpenWebUI                  #
########################################

# Vérifie si OpenWebUI tourne déjà
if pgrep -f "open-webui" >/dev/null 2>&1; then
  echo "[LibreStorien] OpenWebUI est déjà en cours d’exécution."
else
    echo "[LibreStorien] Lancement de OpenWebUI..."
    
    ENABLE_OPENAI_API="True" \
    ENABLE_OLLAMA_API="False" \
    ENABLE_PERSISTENT_CONFIG="False" \
    ENABLE_WEB_SEARCH="False" \
    OPENAI_API_BASE_URL="http://127.0.0.1:${LLAMA_PORT}/v1" \
    open-webui serve \
        --host 0.0.0.0 \
        --port "$OPENWEBUI_PORT" \
        > "$PROJECT_DIR/log_openwebui.txt" 2>&1 &

    OPENWEBUI_PID=$!
    echo "[LibreStorien] OpenWebUI lancé (PID $OPENWEBUI_PID)."
    sleep 5
fi

########################################
# 4. Ouvrir le navigateur              #
########################################

URL="http://localhost:${OPENWEBUI_PORT}"

echo "[LibreStorien] Ouverture de $URL dans le navigateur..."

# Détection de la plateforme
OS_NAME="$(uname -s)"

case "$OS_NAME" in
  Linux)
    if command -v xdg-open >/dev/null 2>&1; then
      xdg-open "$URL" >/dev/null 2>&1 &
    else
      echo "[LibreStorien] xdg-open non trouvé. Ouvrir manuellement : $URL"
    fi
    ;;
  Darwin)
    # macOS
    if command -v open >/dev/null 2>&1; then
      open "$URL" >/dev/null 2>&1 &
    else
      echo "[LibreStorien] La commande 'open' est introuvable. Ouvrir manuellement : $URL"
    fi
    ;;
  *)
    echo "[LibreStorien] OS non reconnu ($OS_NAME). Ouvrir manuellement : $URL"
    ;;
esac

echo "[LibreStorien] Lancement terminé."

# Si on a lancé au moins un des services, on attend qu'ils se terminent
if [[ -n "${LLAMA_PID:-}" || -n "${OPENWEBUI_PID:-}" ]]; then
  echo "[LibreStorien] Les services s'arrêteront lors de la fermeture cette fenêtre ou grâce à Ctrl+C."
  # On attend les process lancés (ceci garde le script vivant)
  wait ${LLAMA_PID:-} ${OPENWEBUI_PID:-} 2>/dev/null || true
else
  echo "[LibreStorien] Les services étaient déjà en cours d’exécution avant ce script."
  echo "[LibreStorien] Ce lanceur ne les arrêtera pas automatiquement."
fi
