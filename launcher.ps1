#!/usr/bin/env pwsh
# launch_librestorien.ps1 - Traduction PowerShell de launcher.sh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

################################
# Couleurs console ANSI
################################
$RED   = "`e[0;31m"
$GREEN = "`e[0;32m"
$YELLOW= "`e[1;33m"
$CYAN  = "`e[0;36m"
$RESET = "`e[0m"

#############################
# Configuration du projet   #
#############################

# Dossier du projet (et de ce script)
$PROJECT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $PROJECT_DIR

# Dossier de la venv
$VENV_DIR = Join-Path $PROJECT_DIR ".venv"

# Port du serveur llama.cpp (llama-cpp-python[server])
$LLAMA_PORT = 10000

# Port d’OpenWebUI
$OPENWEBUI_PORT = 8080

# Modèle GGUF à utiliser
$MODEL_FILE = "phi-4-Q4_K_M.gguf" # <-- POSSIBILITE D'ADAPTER LE NOM DU FICHIER
$HF_URL = "https://huggingface.co/unsloth/phi-4-GGUF/resolve/main/$MODEL_FILE" # <-- POSSIBILITE D'ADAPTER LE NOM DU FICHIER

$MODEL_PATH = Join-Path $PROJECT_DIR "models/$MODEL_FILE"

# PIDs des services lancés par ce script
$LLAMA_PID = $null
$OPENWEBUI_PID = $null

##############################
# Fonctions utilitaires      #
##############################

# Fonctions d’affichage coloré
function info    { param([string]$msg) Write-Host "$CYAN$msg$RESET" }
function success { param([string]$msg) Write-Host "$GREEN$msg$RESET" }
function warn    { param([string]$msg) Write-Host "$YELLOW$msg$RESET" }
function error   { param([string]$msg) Write-Host "$RED$msg$RESET" -ForegroundColor Red }

# Fonction de mise à jour des dépendances Python
function update_python_deps {
  info "[LibreStorien] Mise à jour des dépendances Python (llama-cpp-python[server], open-webui)..."
  python -m pip install --upgrade "llama-cpp-python[server]" open-webui
}

# Fonction de nettoyage à la fin
function cleanup {
  info "[LibreStorien] Arrêt des services..."

  if ($LLAMA_PID) {
    try {
      Stop-Process -Id $LLAMA_PID -ErrorAction SilentlyContinue
      success "[LibreStorien] llama_cpp.server arrêté (PID $LLAMA_PID)."
    } catch {}
  }

  if ($OPENWEBUI_PID) {
    try {
      Stop-Process -Id $OPENWEBUI_PID -ErrorAction SilentlyContinue
      success "[LibreStorien] OpenWebUI arrêté (PID $OPENWEBUI_PID)."
    } catch {}
  }
}

# Équivalent trap EXIT INT TERM
Register-EngineEvent PowerShell.Exiting -Action { cleanup } | Out-Null

################################
# Vérification / installation de Python 3.11
################################

$PYTHON_BIN = "python3.11"

if (-not (Get-Command $PYTHON_BIN -ErrorAction SilentlyContinue)) {
    warn "[LibreStorien] python3.11 introuvable. Tentative d'installation..."

    # --- Ubuntu / Debian ---
    if (Get-Command apt -ErrorAction SilentlyContinue) {
        sudo apt update
        sudo apt install -y software-properties-common
        sudo add-apt-repository -y ppa:deadsnakes/ppa
        sudo apt update
        sudo apt install -y python3.11 python3.11-venv python3.11-distutils

    # --- Fedora ---
    } elseif (Get-Command dnf -ErrorAction SilentlyContinue) {
        sudo dnf install -y python3.11 python3.11-devel

    # --- Arch Linux ---
    } elseif (Get-Command pacman -ErrorAction SilentlyContinue) {
        sudo pacman -Sy --noconfirm python311

    # --- macOS (Homebrew) ---
    } elseif (Get-Command brew -ErrorAction SilentlyContinue) {
        brew install python@3.11
        brew link python@3.11 --force

    } else {
        error "[ERREUR] Impossible d'installer python3.11 automatiquement (OS non détecté)."
        info  "Installe python3.11 manuellement puis relance."
        exit 1
    }

    # Re-vérifier
    if (-not (Get-Command $PYTHON_BIN -ErrorAction SilentlyContinue)) {
        error "[ERREUR] python3.11 n'a pas pu être installé."
        exit 1
    }
}

$pythonPath = (Get-Command $PYTHON_BIN).Source
info "[LibreStorien] python3.11 disponible : $pythonPath"

################################
# 1. Création / activation venv #
################################

if (-not (Test-Path $VENV_DIR)) {
  info "[LibreStorien] Création de la venv Python avec $PYTHON_BIN..."
  & $PYTHON_BIN -m venv $VENV_DIR
}

info "[LibreStorien] Activation de la venv existante..."

# Activation de la venv (chemins différents Windows / Unix)
if ($IsWindows) {
    $activateScript = Join-Path $VENV_DIR "Scripts\Activate.ps1"
} else {
    $activateScript = Join-Path $VENV_DIR "bin/Activate.ps1"
}

if (-not (Test-Path $activateScript)) {
    error "[ERREUR] Script d'activation introuvable : $activateScript"
    exit 1
}

. $activateScript

info "[LibreStorien] Mise à jour de pip..."
python -m pip install --upgrade pip

# Mise à jour systématique des libs utilisées
update_python_deps

########################################
# 2. Lancer le serveur llama.cpp       #
########################################

if (-not (Test-Path $MODEL_PATH)) {
  warn "[LibreStorien] Modèle introuvable localement, téléchargement depuis Hugging Face..."
  $modelDir = Split-Path $MODEL_PATH -Parent
  if (-not (Test-Path $modelDir)) {
    New-Item -ItemType Directory -Path $modelDir | Out-Null
  }

  $DL_TOOL = $null

  if (Get-Command curl -ErrorAction SilentlyContinue) {
    $DL_TOOL = "curl"
  } elseif (Get-Command wget -ErrorAction SilentlyContinue) {
    $DL_TOOL = "wget"
  } else {
    warn "[LibreStorien] Ni curl ni wget détecté, tentative d'installation..."

    if (Get-Command apt -ErrorAction SilentlyContinue) {
      sudo apt update
      sudo apt install -y curl
      $DL_TOOL = "curl"
    } elseif (Get-Command dnf -ErrorAction SilentlyContinue) {
      sudo dnf install -y curl
      $DL_TOOL = "curl"
    } elseif (Get-Command pacman -ErrorAction SilentlyContinue) {
      sudo pacman -Sy --noconfirm curl
      $DL_TOOL = "curl"
    } elseif (Get-Command brew -ErrorAction SilentlyContinue) {
      brew install curl
      $DL_TOOL = "curl"
    } else {
      error "[ERREUR] Impossible d'installer curl/wget automatiquement. Installer l’un des deux puis relancer."
      exit 1
    }
  }

  info "[LibreStorien] Téléchargement du modèle depuis : $HF_URL"
  if ($DL_TOOL -eq "curl") {
    & curl -L $HF_URL -o $MODEL_PATH
  } else {
    & wget -O $MODEL_PATH $HF_URL
  }

  if (-not (Test-Path $MODEL_PATH)) {
    error "[ERREUR] Échec du téléchargement du modèle depuis $HF_URL"
    exit 1
  }

  info "[LibreStorien] Modèle téléchargé : $MODEL_PATH"
}

# On vérifie si un serveur llama.cpp tourne déjà sur le port défini
function Test-LlamaRunning {
    if ($IsWindows) {
        # Windows : test du port via Test-NetConnection si dispo
        if (Get-Command Test-NetConnection -ErrorAction SilentlyContinue) {
            $r = Test-NetConnection -ComputerName "127.0.0.1" -Port $LLAMA_PORT -WarningAction SilentlyContinue
            return ($r.TcpTestSucceeded)
        } else {
            return $false
        }
    } else {
        # Unix : on essaie un curl rapide sur l'API
        try {
            & curl -sSf "http://127.0.0.1:$LLAMA_PORT/v1/models" 1>$null 2>$null
            return $true
        } catch {
            return $false
        }
    }
}

if (Test-LlamaRunning) {
  info "[LibreStorien] llama_cpp.server est déjà en cours d’exécution."
} else {
    info "[LibreStorien] Lancement de llama_cpp.server..."
    Set-Location $PROJECT_DIR

    $llamaArgs = @(
        "-m", "llama_cpp.server",
        "--model", $MODEL_PATH,
        "--host", "127.0.0.1",
        "--port", "$LLAMA_PORT",
        "--n_gpu_layers", "999",
        "--n_ctx", "8192"
    )

    $llamaLog = Join-Path $PROJECT_DIR "log_llamacpp.txt"

    $proc = Start-Process "python" -ArgumentList $llamaArgs `
        -RedirectStandardOutput $llamaLog `
        -RedirectStandardError  $llamaLog `
        -PassThru

    $LLAMA_PID = $proc.Id
    success "[LibreStorien] llama_cpp.server lancé (PID $LLAMA_PID)."
    Start-Sleep -Seconds 3
}

########################################
# 3. Lancer OpenWebUI                  #
########################################

function Test-OpenWebUIRunning {
    if ($IsWindows -and (Get-Command Test-NetConnection -ErrorAction SilentlyContinue)) {
        $r = Test-NetConnection -ComputerName "127.0.0.1" -Port $OPENWEBUI_PORT -WarningAction SilentlyContinue
        return ($r.TcpTestSucceeded)
    } else {
        try {
            & curl -sSf "http://127.0.0.1:$OPENWEBUI_PORT" 1>$null 2>$null
            return $true
        } catch {
            return $false
        }
    }
}

if (Test-OpenWebUIRunning) {
  info "[LibreStorien] OpenWebUI est déjà en cours d’exécution."
} else {
    info "[LibreStorien] Lancement de OpenWebUI..."

    $env:ENABLE_OPENAI_API       = "True"
    $env:ENABLE_OLLAMA_API       = "False"
    $env:ENABLE_PERSISTENT_CONFIG= "False"
    $env:ENABLE_WEB_SEARCH       = "False"
    $env:OPENAI_API_BASE_URL     = "http://127.0.0.1:${LLAMA_PORT}/v1"

    $webArgs = @(
        "serve",
        "--host", "0.0.0.0",
        "--port", "$OPENWEBUI_PORT"
    )

    $webLog = Join-Path $PROJECT_DIR "log_openwebui.txt"

    $procWeb = Start-Process "open-webui" -ArgumentList $webArgs `
        -RedirectStandardOutput $webLog `
        -RedirectStandardError  $webLog `
        -PassThru

    $OPENWEBUI_PID = $procWeb.Id
    success "[LibreStorien] OpenWebUI lancé (PID $OPENWEBUI_PID)."
    Start-Sleep -Seconds 5
}

########################################
# 4. Ouvrir le navigateur              #
########################################

$URL = "http://localhost:${OPENWEBUI_PORT}"

info "[LibreStorien] Ouverture de $URL dans le navigateur..."

if ($IsLinux) {
    if (Get-Command xdg-open -ErrorAction SilentlyContinue) {
      Start-Process xdg-open $URL | Out-Null
    } else {
      warn "[LibreStorien] xdg-open non trouvé. Ouvrir manuellement : $URL"
    }
} elseif ($IsMacOS) {
    if (Get-Command open -ErrorAction SilentlyContinue) {
      Start-Process open $URL | Out-Null
    } else {
      warn "[LibreStorien] La commande 'open' est introuvable. Ouvrir manuellement : $URL"
    }
} else {
    # Windows ou autre
    try {
        Start-Process $URL | Out-Null
    } catch {
        warn "[LibreStorien] OS non reconnu ou ouverture automatique impossible. Ouvrir manuellement : $URL"
    }
}

success "[LibreStorien] Lancement terminé."

# Si on a lancé au moins un des services, on attend qu'ils se terminent
if ($LLAMA_PID -or $OPENWEBUI_PID) {
  info "[LibreStorien] Les services s'arrêteront lors de la fermeture cette fenêtre ou grâce à Ctrl+C."
  # En PowerShell, on ne peut pas faire un wait multi-PID exactement comme en bash,
  # donc on boucle simplement tant qu'au moins un des deux PID existe.
  while ($true) {
    $llamaAlive = $false
    $webAlive   = $false

    if ($LLAMA_PID) {
      $llamaAlive = (Get-Process -Id $LLAMA_PID -ErrorAction SilentlyContinue) -ne $null
    }
    if ($OPENWEBUI_PID) {
      $webAlive = (Get-Process -Id $OPENWEBUI_PID -ErrorAction SilentlyContinue) -ne $null
    }

    if (-not ($llamaAlive -or $webAlive)) {
      break
    }

    Start-Sleep -Seconds 2
  }
} else {
  warn "[LibreStorien] Les services étaient déjà en cours d’exécution avant ce script."
  warn "[LibreStorien] Ce lanceur ne les arrêtera pas automatiquement."
}
