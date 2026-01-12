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
# Détection OS & Gestionnaire
##############################
PKG_MANAGER=""
INSTALL_CMD=""
UPDATE_CMD=""

if command -v apt >/dev/null 2>&1; then # Ubuntu / Debian
    PKG_MANAGER="apt"
    INSTALL_CMD="sudo apt install -y"
    UPDATE_CMD="sudo apt update"
elif command -v dnf >/dev/null 2>&1; then # Fedora
    PKG_MANAGER="dnf"
    INSTALL_CMD="sudo dnf install -y"
    UPDATE_CMD="sudo dnf check-update" # Souvent optionnel mais bon à avoir
elif command -v pacman >/dev/null 2>&1; then # Arch Linux
    PKG_MANAGER="pacman"
    INSTALL_CMD="sudo pacman -Sy --noconfirm"
    UPDATE_CMD="sudo pacman -Sy"
elif command -v brew >/dev/null 2>&1; then # MacOS
    PKG_MANAGER="brew"
    INSTALL_CMD="brew install"
    UPDATE_CMD="brew update"
fi

# Nouvelle version simplifiée de la fonction d'installation
install_sys_package() {
  local PKG_APT="${1:-}"
  local PKG_DNF="${2:-}"
  local PKG_PACMAN="${3:-}"
  local PKG_BREW="${4:-}"
  local PKG_TARGET=""

  case "$PKG_MANAGER" in
    apt)    PKG_TARGET="$PKG_APT" ;;
    dnf)    PKG_TARGET="$PKG_DNF" ;;
    pacman) PKG_TARGET="$PKG_PACMAN" ;;
    brew)   PKG_TARGET="$PKG_BREW" ;;
    *)      
        error "[ERREUR] Gestionnaire de paquets non supporté automatiquement."
        warn "Veuillez installer manuellement : $PKG_APT (ou équivalent)"
        return 1 
        ;;
  esac

  info "[SYSTEM] Détection de $PKG_MANAGER. Installation de : $PKG_TARGET"
  if [[ -n "$PKG_TARGET" ]]; then
      $INSTALL_CMD $PKG_TARGET
  fi
}

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
  elif [[ "${CMAKE_ARGS:-}" == *"-DGGML_VULKAN=on"* ]]; then
    CURRENT_MODE="vulkan"
  fi

  info "[DEPENDANCES] Mode détecté : $CURRENT_MODE (Précédent : ${LAST_MODE:-aucun})"

  # Si le mode a changé ou si c'est la première install
  if [[ "$CURRENT_MODE" != "$LAST_MODE" ]]; then
    warn "[CHANGEMENT] Configuration matérielle modifiée ($LAST_MODE -> $CURRENT_MODE). Réinstallation forcée..."
    
    # On force la réinstallation pour compiler avec les bons drapeaux (CMAKE_ARGS)
    # Note : --no-cache-dir est important pour éviter de reprendre un wheel précompilé pour la mauvaise architecture
    uv pip install --upgrade --force-reinstall --no-cache-dir "llama-cpp-python[server]"
    
    # Mise à jour du fichier témoin
    echo "$CURRENT_MODE" > "$MODE_FILE"
    success "[INSTALLATION] Installation terminée pour le mode : $CURRENT_MODE"

  else
    # Le mode est le même, on fait une mise à jour standard (rapide)
    info "[UPDATE] Vérification des mises à jour (Mode $CURRENT_MODE)..."
    uv pip install --upgrade "llama-cpp-python[server]"
  fi

  # OpenWebUI s'installe normalement (agnostique du GPU)
  uv pip install --upgrade open-webui
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
  
  # --- C. DÉTECTION VULKAN (WSL2 / Fallback AMD) ---
  # Si on est sous WSL2 (libd3d12.so présent) ou si vulkaninfo existe
  elif [[ -f "/usr/lib/wsl/lib/libd3d12.so" ]] || command -v vulkaninfo >/dev/null 2>&1; then
    info "[GPU] Support Vulkan détecté (WSL2 ou GPU générique)."
    
    # Installation des dépendances Vulkan si nécessaire
    if ! command -v vulkaninfo >/dev/null 2>&1 || ! command -v glslc >/dev/null 2>&1; then
        warn "[ATTENTION] Outils Vulkan manquants (vulkaninfo ou glslc)."
        info "[LibreStorien] Installation de vulkan-tools, libvulkan-dev, mesa-vulkan-drivers et glslc..."
        install_sys_package "vulkan-tools libvulkan-dev mesa-vulkan-drivers glslc" "vulkan-tools vulkan-loader-devel mesa-vulkan-drivers glslc" "vulkan-tools vulkan-headers mesa-vulkan-drivers shaderc"
    fi

    success "[SUCCÈS] Mode Vulkan activé."
    export CMAKE_ARGS="-DGGML_VULKAN=on"
    export FORCE_CMAKE=1
    return

  else
    # --- D. AUCUN GPU ---
    warn "[INFO] Aucun GPU compatible (Nvidia/AMD/Vulkan) détecté."
  fi

  # --- D. FALLBACK CPU ---
  info "[MODE] Configuration en mode CPU pur."
  unset CMAKE_ARGS
  unset FORCE_CMAKE
}

# Fonction de téléchargement agnostique (curl ou wget)
download_file() {
  local URL="$1"
  local DEST="$2"

  if command -v curl >/dev/null 2>&1; then
    curl -L "$URL" -o "$DEST"
  elif command -v wget >/dev/null 2>&1; then
    wget -O "$DEST" "$URL"
  else
    warn "[LibreStorien] Ni curl ni wget détecté, tentative d'installation..."
    install_sys_package "curl" "curl" "curl" "curl"
    # Récursion : on réessaie après installation
    if command -v curl >/dev/null 2>&1; then
        curl -L "$URL" -o "$DEST"
    else
        error "[ERREUR] Impossible de télécharger (outils manquants)."
        return 1
    fi
  fi
}

# Fonction de nettoyage à la fin
kill_service() {
    local PID="$1"
    local NAME="$2"
    if [[ -n "$PID" ]] && kill -0 "$PID" 2>/dev/null; then
        kill "$PID" >/dev/null 2>&1
        success "[LibreStorien] $NAME arrêté (PID $PID)."
    fi
}

cleanup() {
  info "[LibreStorien] Arrêt des services..."
  kill_service "${LLAMA_PID:-}" "llama_cpp.server"
  kill_service "${OPENWEBUI_PID:-}" "OpenWebUI"
}
# Nettoyage quand le script se termine ou lors d'un Ctrl+C
trap cleanup EXIT INT TERM

################################
# Vérification / installation de Python 3.11
################################

PYTHON_BIN="python3.11"

if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
    warn "[LibreStorien] python3.11 introuvable. Tentative d'installation..."

    case "$PKG_MANAGER" in
        apt)
            $UPDATE_CMD
            $INSTALL_CMD software-properties-common
            sudo add-apt-repository -y ppa:deadsnakes/ppa
            $UPDATE_CMD
            $INSTALL_CMD python3.11 python3.11-venv python3.11-distutils
            ;;
        dnf)
            $INSTALL_CMD python3.11 python3.11-devel
            ;;
        pacman)
            $INSTALL_CMD python311
            ;;
        brew)
            $INSTALL_CMD python@3.11
            brew link python@3.11 --force
            ;;
        *)
            error "[ERREUR] Impossible d'installer python3.11 automatiquement (OS non détecté)."
            warn "Installe python3.11 manuellement puis relance."
            exit 1
            ;;
    esac

    # Re-vérifier
    if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
        error "[ERREUR] python3.11 n'a pas pu être installé."
        exit 1
    fi
fi

info "[LibreStorien] python3.11 disponible : $(which python3.11)"

################################
# Installation de uv           #
################################

# Vérification de la présence de uv
if ! command -v uv >/dev/null 2>&1; then
    info "[LibreStorien] uv introuvable. Tentative d'installation via le script officiel..."

    # Utilisation du script d'installation auto-hébergé par Astral
    if command -v curl >/dev/null 2>&1; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- https://astral.sh/uv/install.sh | sh
    else
        error "[ERREUR] Ni curl ni wget n'est disponible pour installer uv."
        exit 1
    fi

    # Ajout immédiat au PATH pour la session en cours (emplacement par défaut du script)
    # uv s'installe généralement dans ~/.local/bin ou ~/.cargo/bin
    export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

    # Vérification finale
    if ! command -v uv >/dev/null 2>&1; then
        error "[ERREUR] L'installation de uv a échoué ou le binaire n'est pas dans le PATH."
        exit 1
    fi
    success "[LibreStorien] uv a été installé avec succès."
else
    info "[LibreStorien] uv est déjà installé : $(which uv)"
fi

##############################################
# Dépendances système pour llama-cpp (Ubuntu)
##############################################

info "[LibreStorien] Vérification des dépendances système pour llama-cpp (build-essential, cmake, python3.11-dev)..."

install_sys_package \
  "build-essential cmake python3.11-dev" \
  "gcc-c++ cmake python3.11-devel" \
  "base-devel cmake" \
  "cmake"

################################
# 1. Création / activation venv #
################################

if [[ ! -d "$VENV_DIR" ]]; then
  info "[LibreStorien] Création de la venv Python avec uv ($PYTHON_BIN)..."
  uv venv "$VENV_DIR" --python "$PYTHON_BIN"
fi

info "[LibreStorien] Activation de la venv existante..."
# shellcheck disable=SC1090
source "$VENV_DIR/bin/activate"

# Configuration pour WSL2 (accès aux drivers Windows)
# On le fait après l'activation du venv pour être sûr
if [[ -d "/usr/lib/wsl/lib" ]]; then
    info "[CONFIG] WSL2 détecté. Ajout de /usr/lib/wsl/lib au LD_LIBRARY_PATH."
    export LD_LIBRARY_PATH="/usr/lib/wsl/lib:${LD_LIBRARY_PATH:-}"
fi

info "[LibreStorien] Mise à jour de uv..."
uv self update || true

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
  
  # Création du dossier si nécessaire
  mkdir -p "$(dirname "$MODEL_PATH")"

  info "[LibreStorien] Téléchargement du modèle depuis : $HF_URL"
  
  # Appel de notre nouvelle fonction simplifiée
  if ! download_file "$HF_URL" "$MODEL_PATH"; then
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
    
    elif [[ "${CMAKE_ARGS:-}" == *"-DGGML_VULKAN=on"* ]]; then
        info "[CONFIG] Configuration Vulkan détectée."
        FLASH_ATTN_FLAG=""
        warn "[CONFIG] Vulkan : Flash Attention désactivé."
        
        # DEBUG: Vérifier la visibilité du GPU
        info "[DEBUG] Vérification de l'accès GPU Vulkan..."
        
        # On construit le chemin de librairie incluant WSL
        LIB_PATH="/usr/lib/wsl/lib"
        if [[ -n "${LD_LIBRARY_PATH:-}" ]]; then
            LIB_PATH="$LIB_PATH:$LD_LIBRARY_PATH"
        fi
        
        # Vérification de la présence du driver dzn (Microsoft Dozen) - UNIQUEMENT POUR WSL2
        if [[ -f "/usr/lib/wsl/lib/libd3d12.so" ]]; then
            if ! ls /usr/share/vulkan/icd.d/*dzn*.json >/dev/null 2>&1; then
                warn "[ATTENTION] Driver Vulkan 'dzn' (Microsoft Dozen) introuvable."
                warn "Ce driver est nécessaire pour l'accélération GPU sous WSL2."
                
                # Tentative d'installation automatique si apt est dispo
                if command -v apt-add-repository >/dev/null 2>&1; then
                     info "[LibreStorien] Ajout du PPA kisak-mesa et mise à jour des drivers..."
                     sudo add-apt-repository -y ppa:kisak/kisak-mesa
                     sudo apt update
                     sudo apt install -y mesa-vulkan-drivers
                else
                     error "Veuillez installer 'mesa-vulkan-drivers' depuis un PPA compatible (ex: kisak-mesa)."
                fi
            fi

            # Force l'utilisation du driver Mesa "Dozen" (dzn) qui traduit Vulkan -> D3D12 (WSL2)
            export MESA_LOADER_DRIVER_OVERRIDE=dzn
            info "[CONFIG] Force MESA_LOADER_DRIVER_OVERRIDE=dzn pour WSL2."
        fi
        
        # Test rapide de détection GPU
        if env LD_LIBRARY_PATH="$LIB_PATH" vulkaninfo --summary > /dev/null 2>&1; then
             success "[SUCCÈS] GPU Vulkan détecté."
        else
             warn "[ATTENTION] vulkaninfo a échoué, mais on tente le lancement quand même."
        fi
    fi
    info "[LibreStorien] Lancement de llama_cpp.server..."
    cd "$PROJECT_DIR"
    
    # --n_gpu_layers -1 : Tente de tout mettre sur le GPU. 
    # Si ça crash, remplacez -1 par un nombre fixe (ex: 20 ou 30) 
    # pour laisser une partie du modèle sur le CPU.

    #--n_ctx 16384 \
    
    # Construction du LD_LIBRARY_PATH final pour le serveur
    SERVER_LIB_PATH="/usr/lib/wsl/lib"
    if [[ -n "${LD_LIBRARY_PATH:-}" ]]; then
        SERVER_LIB_PATH="$SERVER_LIB_PATH:$LD_LIBRARY_PATH"
    fi

    # Force LD_LIBRARY_PATH pour la commande python au cas où
    env LD_LIBRARY_PATH="$SERVER_LIB_PATH" python -m llama_cpp.server \
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
    RAG_EMBEDDING_MODEL="OrdalieTech/Solon-embeddings-base-0.1" \
    CHUNK_SIZE="200" \
    CHUNK_OVERLAP="50" \
    RAG_TOP_K="89" \
    RAG_TOP_K_RERANKER="79" \
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
