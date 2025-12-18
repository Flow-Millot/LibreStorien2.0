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
MODEL_FILE="phi-4-Q4_K_M.gguf" # <-- POSSIBILITE D'ADAPTER LE NOM DU FICHIER
HF_URL="https://huggingface.co/unsloth/phi-4-GGUF/resolve/main/${MODEL_FILE}" # <-- POSSIBILITE D'ADAPTER LE NOM DU FICHIER

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

# Fonction globale pour installer des paquets système selon la distribution
# Usage: install_sys_package "nom_apt" "nom_dnf" "nom_pacman"
install_sys_package() {
  local PKG_APT="$1"
  local PKG_DNF="$2"
  local PKG_PACMAN="$3"

  if command -v apt >/dev/null 2>&1; then
    # Debian / Ubuntu / Mint
    info "[SYSTEM] Détection de apt. Installation de : $PKG_APT"
    sudo apt update && sudo apt install -y "$PKG_APT"

  elif command -v dnf >/dev/null 2>&1; then
    # Fedora / RHEL
    info "[SYSTEM] Détection de dnf. Installation de : $PKG_DNF"
    sudo dnf install -y "$PKG_DNF"

  elif command -v pacman >/dev/null 2>&1; then
    # Arch Linux / Manjaro
    info "[SYSTEM] Détection de pacman. Installation de : $PKG_PACMAN"
    sudo pacman -Sy --noconfirm "$PKG_PACMAN"

  else
    error "[ERREUR] Gestionnaire de paquets non supporté automatiquement."
    warn "Veuillez installer manuellement : $PKG_APT (ou équivalent)"
    return 1
  fi
}

# Fonction de mise à jour des dépendances
update_python_deps() {
  info "[LibreStorien] Vérification des librairies Python..."

  # Fichier témoin contenant le mode de la dernière installation (ex: "cuda", "rocm", "cpu")
  MODE_FILE="$VENV_DIR/.installed_mode"
  LAST_MODE=""
  
  if [[ -f "$MODE_FILE" ]]; then
    LAST_MODE=$(cat "$MODE_FILE")
  fi

  # Déterminer le mode actuel basé sur la détection faite dans configure_gpu_support
  CURRENT_MODE="cpu"
  if [[ "${CMAKE_ARGS:-}" == *"-DGGML_CUDA=on"* ]]; then
    CURRENT_MODE="cuda"
  elif [[ "${CMAKE_ARGS:-}" == *"-DGGML_HIPBLAS=on"* ]]; then
    CURRENT_MODE="rocm"
  fi

  info "[DEPENDANCES] Mode détecté : $CURRENT_MODE (Précédent : ${LAST_MODE:-aucun})"

  # Si le mode a changé ou si c'est la première install
  if [[ "$CURRENT_MODE" != "$LAST_MODE" ]]; then
    warn "[CHANGEMENT] Configuration matérielle modifiée ($LAST_MODE -> $CURRENT_MODE). Réinstallation forcée..."
    
    # On force la réinstallation pour compiler avec les bons drapeaux (CMAKE_ARGS)
    # Note : --no-cache-dir est important pour éviter de reprendre un wheel précompilé pour la mauvaise architecture
    python -m pip install --upgrade --force-reinstall --no-cache-dir "llama-cpp-python[server]"
    
    # Mise à jour du fichier témoin
    echo "$CURRENT_MODE" > "$MODE_FILE"
    success "[INSTALLATION] Installation terminée pour le mode : $CURRENT_MODE"

  else
    # Le mode est le même, on fait une mise à jour standard (rapide)
    info "[UPDATE] Vérification des mises à jour (Mode $CURRENT_MODE)..."
    python -m pip install --upgrade "llama-cpp-python[server]"
  fi

  # OpenWebUI s'installe normalement (agnostique du GPU)
  python -m pip install --upgrade open-webui
}

# Fonction de détection, installation et configuration GPU (Nvidia/CUDA ou AMD/ROCm)
configure_gpu_support() {
  info "[LibreStorien] Analyse du matériel graphique..."

  # --- A. DÉTECTION NVIDIA ---
  if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1; then
    info "[GPU] Carte Nvidia détectée."
    
    # Si nvcc n'est pas là, on utilise la fonction globale pour l'installer
    if ! command -v nvcc >/dev/null 2>&1; then
      warn "[ATTENTION] GPU Nvidia présent mais 'nvcc' introuvable."
      info "[LibreStorien] Tentative d'installation du CUDA Toolkit..."
      
      # Appel de la fonction globale : install_sys_package "nom_ubuntu" "nom_fedora" "nom_arch"
      # Note : gcc et g++ sont souvent requis avec cuda
      install_sys_package "nvidia-cuda-toolkit gcc g++" "cudatoolkit" "cuda"
    fi

    # Vérification finale après tentative d'installation
    if command -v nvcc >/dev/null 2>&1; then
      CUDA_VERSION=$(nvcc --version | grep "release" | sed 's/.*release //; s/,.*//')
      success "[SUCCÈS] Mode Nvidia CUDA activé (v$CUDA_VERSION)."
      export CMAKE_ARGS="-DGGML_CUDA=on"
      export FORCE_CMAKE=1
      return
    else
      error "[ECHEC] nvcc manquant malgré la tentative. Fallback CPU."
    fi

  # --- B. DÉTECTION AMD (ROCm) ---
  # On cherche rocm-smi ou rocminfo
  elif (command -v rocm-smi >/dev/null 2>&1) || (command -v rocminfo >/dev/null 2>&1); then
    info "[GPU] Carte AMD (ROCm) détectée."

    # Ajout du path standard ROCm si présent
    if [[ -d "/opt/rocm/bin" && ":$PATH:" != *":/opt/rocm/bin:"* ]]; then
        export PATH="/opt/rocm/bin:$PATH"
    fi

    # Si hipcc n'est pas là, on tente l'installation
    if ! command -v hipcc >/dev/null 2>&1; then
      warn "[ATTENTION] GPU AMD détecté mais compilateur 'hipcc' introuvable."
      info "[LibreStorien] Tentative d'installation du SDK ROCm..."
      
      # Note pour AMD : Les paquets dépendent fortement de l'ajout préalable des dépôts AMD (amdgpu-install).
      # On tente quand même les noms standards.
      install_sys_package "rocm-hip-sdk" "rocm-hip-sdk" "rocm-hip-sdk"
    fi

    if command -v hipcc >/dev/null 2>&1; then
      HIP_VERSION=$(hipcc --version | grep "HIP version" | cut -d: -f2 | xargs)
      success "[SUCCÈS] Mode AMD ROCm activé (HIP v$HIP_VERSION)."
      
      export CMAKE_ARGS="-DGGML_HIPBLAS=on"
      export CC=$(which clang)
      export CXX=$(which clang++)
      export FORCE_CMAKE=1
      return
    else
      error "[ECHEC] 'hipcc' introuvable. Impossible de compiler pour AMD."
      warn "Conseil : Assurez-vous d'avoir suivi le guide d'installation ROCm officiel (https://rocm.docs.amd.com/)"
      warn "Fallback CPU."
    fi
  
  else
    # --- C. AUCUN GPU ---
    warn "[INFO] Aucun GPU compatible (Nvidia/AMD) détecté."
  fi

  # --- D. FALLBACK CPU ---
  info "[MODE] Configuration en mode CPU pur."
  unset CMAKE_ARGS
  unset FORCE_CMAKE
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

  if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
    warn "[LibreStorien] Ni curl ni wget détecté, tentative d'installation..."
    install_sys_package "curl" "curl" "curl"
    DL_TOOL="curl"
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

    # Par défaut (CPU ou Nvidia), on active Flash Attention
    FLASH_ATTN_FLAG="--flash_attn true"

    # Si on est en mode AMD (ROCm) détecté précédemment
    if [[ "${CMAKE_ARGS:-}" == *"-DGGML_HIPBLAS=on"* ]]; then
        info "[CONFIG] Configuration spécifique AMD détectée."
        
        # 1. Désactiver Flash Attention (souvent instable sur ROCm)
        FLASH_ATTN_FLAG="" 
        warn "[CONFIG] AMD : Flash Attention désactivé pour la stabilité."

        # 2. Fix pour les cartes "Consumer" (RX 6000/7000, etc.)
        # ROCm ne supporte officiellement que les cartes Pro. 
        # Cette variable force la compatibilité pour beaucoup de cartes RDNA2/3.
        export HSA_OVERRIDE_GFX_VERSION=10.3.0
        info "[CONFIG] AMD : HSA_OVERRIDE_GFX_VERSION=10.3.0 appliqué (Support RX 6000/7000)."
    fi
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
        --n_ctx 16384 \
        $FLASH_ATTN_FLAG \
        > "$PROJECT_DIR/log_llamacpp.txt" 2>&1 &

    LLAMA_PID=$!

    sleep 3
    success "[LibreStorien] llama_cpp.server lancé (PID $LLAMA_PID)."

fi

########################################
# 3. Lancer OpenWebUI                  #
########################################

# Vérifie si OpenWebUI tourne déjà
if pgrep -f "open-webui" >/dev/null 2>&1; then
  info "[LibreStorien] OpenWebUI est déjà en cours d’exécution."
else
    info "[LibreStorien] Lancement de OpenWebUI..."
    export HF_HUB_DOWNLOAD_TIMEOUT=120

    # RAG_EMBEDDING_MODEL="BAAI/bge-m3" \
    
    ENABLE_OPENAI_API="True" \
    ENABLE_OLLAMA_API="False" \
    ENABLE_PERSISTENT_CONFIG="False" \
    ENABLE_WEB_SEARCH="False" \
    OPENAI_API_BASE_URL="http://127.0.0.1:${LLAMA_PORT}/v1" \
    MODEL_TEMPERATURE="0.1" \
    RAG_EMBEDDING_MODEL="OrdalieTech/Solon-embeddings-large-0.1" \
    CHUNK_SIZE="500" \
    CHUNK_OVERLAP="50" \
    RAG_TOP_K="99" \
    RAG_TOP_K_RERANKER="89" \
    RAG_RELEVANCE_THRESHOLD="0" \
    RAG_RERANKING_ENGINE="sentence_transformers" \
    RAG_RERANKING_MODEL="BAAI/bge-reranker-v2-m3" \
    ENABLE_RAG_HYBRID_SEARCH="True" \
    open-webui serve \
        --host 0.0.0.0 \
        --port "$OPENWEBUI_PORT" \
        > "$PROJECT_DIR/log_openwebui.txt" 2>&1 &

    OPENWEBUI_PID=$!
    sleep 5
    success "[LibreStorien] OpenWebUI lancé (PID $OPENWEBUI_PID)."
    
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
  warn "[LibreStorien] Veuillez attendre quelques minutes le temps que OpenWeb UI installe l'embedding model et le reranker au premier lancement."
  info "[LibreStorien] Logs : log_llamacpp.txt et log_openwebui.txt"
  # On attend les process lancés (ceci garde le script vivant)
  wait ${LLAMA_PID:-} ${OPENWEBUI_PID:-} 2>/dev/null || true
else
  warn "[LibreStorien] Les services étaient déjà en cours d’exécution avant ce script."
  warn "[LibreStorien] Ce lanceur ne les arrêtera pas automatiquement."
fi
