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
#MODEL_FILE="phi-4-Q4_K_M.gguf" # <-- POSSIBILITE D'ADAPTER LE NOM DU FICHIER
#HF_URL="https://huggingface.co/unsloth/phi-4-GGUF/resolve/main/${MODEL_FILE}" # <-- POSSIBILITE D'ADAPTER LE NOM DU FICHIER

# Modèle Llama 3.1 8B (Version optimisée)
MODEL_FILE="Meta-Llama-3.1-8B-Instruct-Q5_K_M.gguf"
HF_URL="https://huggingface.co/bartowski/Meta-Llama-3.1-8B-Instruct-GGUF/resolve/main/${MODEL_FILE}"

MODEL_PATH="models/${MODEL_FILE}" 

# PIDs des services lancés par ce script
LLAMA_PID=""
OPENWEBUI_PID=""

##############################
# Fonctions utilitaires      #
##############################

# Fonctions d’affichage coloré
info()    { echo -e "${CYAN}$*${RESET}"; }
success() { echo -e "${GREEN}$*${RESET}"; }
warn()    { echo -e "${YELLOW}$*${RESET}"; }
error()   { echo -e "${RED}$*${RESET}" >&2; }

# Fonction de mise à jour des dépendances
update_python_deps() {
  info "[LibreStorien] Vérification des librairies Python..."

  # Chemin du fichier témoin qui prouve qu'on a déjà installé en mode CUDA
  CUDA_MARKER="$VENV_DIR/.cuda_installed"

  # CAS 1 : On est en mode GPU (Nvidia détecté)
  if [[ -n "${FORCE_CMAKE:-}" ]]; then
    
    # Si le marker n'existe pas, c'est la première fois ou on vient du mode CPU
    if [[ ! -f "$CUDA_MARKER" ]]; then
       info "[INSTALLATION GPU] Première installation avec support CUDA (Cela va prendre quelques minutes)..."
       # On force la réinstallation pour compiler
       python -m pip install --upgrade --force-reinstall --no-cache-dir "llama-cpp-python[server]"
       # On crée le fichier témoin
       touch "$CUDA_MARKER"
    else
       # Le marker existe, on fait juste une mise à jour standard (rapide si rien de neuf)
       info "[UPDATE GPU] Vérification des mises à jour (rapide)..."
       python -m pip install --upgrade "llama-cpp-python[server]"
    fi

  # CAS 2 : On est en mode CPU
  else
    # Si le marker existe, c'est qu'on avait CUDA avant, il faut nettoyer pour repasser en CPU
    if [[ -f "$CUDA_MARKER" ]]; then
       warn "[CHANGEMENT] Passage du mode GPU vers CPU détecté. Réinstallation..."
       python -m pip install --upgrade --force-reinstall "llama-cpp-python[server]"
       rm "$CUDA_MARKER"
    else
       # Installation CPU classique
       python -m pip install --upgrade "llama-cpp-python[server]"
    fi
  fi

  # OpenWebUI s'installe normalement
  python -m pip install --upgrade open-webui
}

# Fonction de détection, installation et configuration GPU (Nvidia/CUDA)
configure_gpu_support() {
  info "[LibreStorien] Vérification de la configuration GPU..."

  # 1. Vérification matérielle : Est-ce qu'une carte Nvidia est physiquement là ?
  if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1; then
    
    # 2. Vérification logicielle : Est-ce que le compilateur CUDA (nvcc) est présent ?
    if ! command -v nvcc >/dev/null 2>&1; then
      warn "[ATTENTION] GPU Nvidia détecté, mais le 'CUDA Toolkit' (nvcc) est introuvable."
      info "[LibreStorien] Tentative d'installation automatique du CUDA Toolkit..."

      # --- Tentative d'installation selon l'OS ---
      if command -v apt >/dev/null 2>&1; then
        # Ubuntu / Debian / Mint
        sudo apt update
        # nvidia-cuda-toolkit est le paquet standard sur Debian/Ubuntu
        sudo apt install -y nvidia-cuda-toolkit gcc g++

      elif command -v dnf >/dev/null 2>&1; then
        # Fedora / RHEL
        # Note : Sur Fedora, cela suppose que les repos proprios sont activés
        sudo dnf install -y cudatoolkit

      elif command -v pacman >/dev/null 2>&1; then
        # Arch Linux / Manjaro
        sudo pacman -Sy --noconfirm cuda

      else
        error "[ERREUR] Impossible d'installer le CUDA Toolkit automatiquement (OS non géré)."
        warn "Installez manuellement le toolkit cuda pour votre distribution."
      fi
    fi

    # 3. Vérification finale et Activation
    if command -v nvcc >/dev/null 2>&1; then
      # Récupération de la version pour le log
      CUDA_VERSION=$(nvcc --version | grep "release" | sed 's/.*release //; s/,.*//')
      success "[SUCCÈS] GPU Nvidia actif et CUDA Toolkit détecté (v$CUDA_VERSION)."
      success "[MODE] Activation de la compilation GPU (CUDA)."
      
      # Variables persistantes pour pip : forcent la compilation GPU
      export CMAKE_ARGS="-DGGML_CUDA=on"
      export FORCE_CMAKE=1
    else
      error "[ECHEC] Le CUDA Toolkit n'a pas pu être installé ou trouvé."
      warn "[MODE] Fallback : Le script va continuer en mode CPU (plus lent)."
      
      # Nettoyage des variables pour éviter un crash de compilation
      unset CMAKE_ARGS
      unset FORCE_CMAKE
    fi
    
  else
    # Pas de GPU Nvidia détecté
    warn "[INFO] Aucun GPU Nvidia actif détecté."
    info "[MODE] Installation en mode CPU."
    
    unset CMAKE_ARGS
    unset FORCE_CMAKE
  fi
}

# Fonction de nettoyage à la fin
cleanup() {
  info "[LibreStorien] Arrêt des services..."

  if [[ -n "${LLAMA_PID:-}" ]]; then
    if kill "$LLAMA_PID" >/dev/null 2>&1; then
      success "[LibreStorien] llama_cpp.server arrêté (PID $LLAMA_PID)."
    fi
  fi

  if [[ -n "${OPENWEBUI_PID:-}" ]]; then
    if kill "$OPENWEBUI_PID" >/dev/null 2>&1; then
      success "[LibreStorien] OpenWebUI arrêté (PID $OPENWEBUI_PID)."
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
    warn "[LibreStorien] python3.11 introuvable. Tentative d'installation..."

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
        error "[ERREUR] Impossible d'installer python3.11 automatiquement (OS non détecté)."
        warn "Installe python3.11 manuellement puis relance."
        exit 1
    fi

    # Re-vérifier
    if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
        error "[ERREUR] python3.11 n'a pas pu être installé."
        exit 1
    fi
fi

info "[LibreStorien] python3.11 disponible : $(which python3.11)"

##############################################
# Dépendances système pour llama-cpp (Ubuntu)
##############################################

if command -v apt >/dev/null 2>&1; then
  info "[LibreStorien] Vérification des dépendances système pour llama-cpp (build-essential, cmake, python3.11-dev)..."

  if ! dpkg -s build-essential cmake python3.11-dev >/dev/null 2>&1; then
    info "[LibreStorien] Installation des dépendances système nécessaires à llama-cpp..."
    sudo apt update
    sudo apt install -y build-essential cmake python3.11-dev
  else
    info "[LibreStorien] Dépendances système déjà installées."
  fi
fi

################################
# 1. Création / activation venv #
################################

if [[ ! -d "$VENV_DIR" ]]; then
  info "[LibreStorien] Création de la venv Python avec $PYTHON_BIN..."
  "$PYTHON_BIN" -m venv "$VENV_DIR"
fi

info "[LibreStorien] Activation de la venv existante..."
# shellcheck disable=SC1090
source "$VENV_DIR/bin/activate"

info "[LibreStorien] Mise à jour de pip..."
python -m pip install --upgrade pip

# Configuration GPU si possible
configure_gpu_support

# Mise à jour systématique des libs utilisées
update_python_deps

########################################
# 2. Lancer le serveur llama.cpp       #
########################################

# Dossier contenant les modèles (dérivé de MODEL_PATH)
MODELS_DIR="$(dirname "$MODEL_PATH")"

# S'assurer que le dossier des modèles existe
if [[ ! -d "$MODELS_DIR" ]]; then
  info "[LibreStorien] Dossier des modèles introuvable, création : $MODELS_DIR"
  mkdir -p "$MODELS_DIR"
fi

if [[ ! -f "$MODEL_PATH" ]]; then
  warn "[LibreStorien] Modèle introuvable localement, téléchargement depuis Hugging Face..."
  mkdir -p "$(dirname "$MODEL_PATH")"

  DL_TOOL=""

  if command -v curl >/dev/null 2>&1; then
    DL_TOOL="curl"
  elif command -v wget >/dev/null 2>&1; then
    DL_TOOL="wget"
  else
    warn "[LibreStorien] Ni curl ni wget détecté, tentative d'installation..."

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
      error "[ERREUR] Impossible d'installer curl/wget automatiquement. Installer l’un des deux puis relancer."
      exit 1
    fi
  fi

  info "[LibreStorien] Téléchargement du modèle depuis : $HF_URL"
  if [[ "$DL_TOOL" == "curl" ]]; then
    curl -L "$HF_URL" -o "$MODEL_PATH"
  else
    wget -O "$MODEL_PATH" "$HF_URL"
  fi

  if [[ ! -f "$MODEL_PATH" ]]; then
    error "[ERREUR] Échec du téléchargement du modèle depuis $HF_URL"
    exit 1
  fi

  info "[LibreStorien] Modèle téléchargé : $MODEL_PATH"
fi

# On vérifie si un serveur llama.cpp tourne déjà sur le port défini
if pgrep -f "llama_cpp.server" >/dev/null 2>&1; then
  info "[LibreStorien] llama_cpp.server est déjà en cours d’exécution."
else
    info "[LibreStorien] Lancement de llama_cpp.server..."
    cd "$PROJECT_DIR"
    
    # --n_gpu_layers -1 : Tente de tout mettre sur le GPU. 
    # Si ça crash, remplacez -1 par un nombre fixe (ex: 20 ou 30) 
    # pour laisser une partie du modèle sur le CPU.

    #--n_ctx 16384 \
    
    python -m llama_cpp.server \
        --model "$MODEL_PATH" \
        --host 127.0.0.1 \
        --port "$LLAMA_PORT" \
        --n_gpu_layers -1 \
        --flash_attn true \
        > "$PROJECT_DIR/log_llamacpp.txt" 2>&1 &

    LLAMA_PID=$!
    success "[LibreStorien] llama_cpp.server lancé (PID $LLAMA_PID)."
    sleep 3
fi

########################################
# 3. Lancer OpenWebUI                  #
########################################

# Vérifie si OpenWebUI tourne déjà
if pgrep -f "open-webui" >/dev/null 2>&1; then
  info "[LibreStorien] OpenWebUI est déjà en cours d’exécution."
else
    info "[LibreStorien] Lancement de OpenWebUI..."
    
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
    success "[LibreStorien] OpenWebUI lancé (PID $OPENWEBUI_PID)."
    sleep 5
fi

########################################
# 4. Ouvrir le navigateur              #
########################################

URL="http://localhost:${OPENWEBUI_PORT}"

info "[LibreStorien] Ouverture de $URL dans le navigateur..."

# Détection de la plateforme
OS_NAME="$(uname -s)"

case "$OS_NAME" in
  Linux)
    if command -v xdg-open >/dev/null 2>&1; then
      xdg-open "$URL" >/dev/null 2>&1 &
    else
      warn "[LibreStorien] xdg-open non trouvé. Ouvrir manuellement : $URL"
    fi
    ;;
  Darwin)
    # macOS
    if command -v open >/dev/null 2>&1; then
      open "$URL" >/dev/null 2>&1 &
    else
      warn "[LibreStorien] La commande 'open' est introuvable. Ouvrir manuellement : $URL"
    fi
    ;;
  *)
    warn "[LibreStorien] OS non reconnu ($OS_NAME). Ouvrir manuellement : $URL"
    ;;
esac

success "[LibreStorien] Lancement terminé."

# Si on a lancé au moins un des services, on attend qu'ils se terminent
if [[ -n "${LLAMA_PID:-}" || -n "${OPENWEBUI_PID:-}" ]]; then
  info "[LibreStorien] Les services s'arrêteront lors de la fermeture cette fenêtre ou grâce à Ctrl+C."
  # On attend les process lancés (ceci garde le script vivant)
  wait ${LLAMA_PID:-} ${OPENWEBUI_PID:-} 2>/dev/null || true
else
  warn "[LibreStorien] Les services étaient déjà en cours d’exécution avant ce script."
  warn "[LibreStorien] Ce lanceur ne les arrêtera pas automatiquement."
fi
