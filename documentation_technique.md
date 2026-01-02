# Documentation Technique - LibreStorien 2.0

- **Version du document :** 1.0
- **Cible :** Développeurs, DevOps, Administrateurs Système
- **Objet :** Architecture, maintenance et fonctionnement interne de la solution "LibreStorien" (Assistant RAG Local).

## 1. Vue d'ensemble de l'Architecture

LibreStorien est une solution d'IA générative locale ("On-Premise") axée sur le RAG (Retrieval-Augmented Generation). Elle est conçue pour être agnostique du système hôte (Linux/macOS/WSL2) et gère automatiquement l'approvisionnement des ressources matérielles (CPU/GPU).

### 1.1 Stack Technologique

* **Orchestration :** Scripts Bash (`launcher.sh`, `creation_raccourci.sh`).
* **Gestionnaire de paquets Python :** `uv` (astral.sh) pour la rapidité et la gestion des venv.
* **Runtime Python :** Python 3.11 (Hard requirement pour compatibilité OpenWebUI à date).
* **Moteur d'inférence (Backend) :** `llama-cpp-python[server]` (Binding Python pour llama.cpp).
* **Interface & RAG (Frontend/Middleware) :** `OpenWebUI`.
* **Stockage Vectoriel :** ChromaDB (embarqué dans OpenWebUI).

### 1.2 Flux de communication

1.  **Utilisateur** -> Navigateur Web -> **OpenWebUI** (Port `8080`).
2.  **OpenWebUI** -> API Call (Format OpenAI) -> **llama_cpp.server** (Port `10000`).
3.  **llama_cpp.server** -> Inférence sur fichier GGUF -> **Hardware** (CUDA/ROCm/Vulkan/CPU).

## 2. Analyse du Script de Lancement (`launcher.sh`)

Le fichier `launcher.sh` est le point d'entrée critique. Il agit comme un gestionnaire de configuration (CM) léger et un superviseur de processus.

### 2.1 Séquence d'initialisation

1.  **Détection de l'OS et du Gestionnaire de Paquets :** Supporte `apt`, `dnf`, `pacman`, `brew`.
2.  **Bootstrapping Python :** Vérifie la présence de `python3.11`. Si absent, tente l'installation via le gestionnaire de paquets système (gestion des PPA pour Ubuntu).
3.  **Installation de `uv` :** Télécharge le binaire `uv` si non présent pour gérer les dépendances Python plus rapidement que pip.
4.  **Environnement Virtuel :** Création/Activation de `.venv` à la racine du projet.
5.  **Détection Matérielle & Compilation JIT :** C'est la partie la plus complexe (voir section 3).
6.  **Gestion du Modèle :** Téléchargement automatique du fichier GGUF si absent via `curl`/`wget`.
7.  **Lancement des Daemons :**
    * `llama_cpp.server` en background.
    * `open-webui serve` en background.
8.  **Supervision :** Capture des signaux `trap` (EXIT, INT, TERM) pour tuer les processus enfants (`kill_service`) à la fermeture.

### 2.2 Variables d'Environnement Critiques

Le script injecte des variables d'environnement dynamiques avant le lancement des processus Python :

| Variable | Valeur (Exemple) | Description |
| :--- | :--- | :--- |
| `CMAKE_ARGS` | `-DGGML_CUDA=on` | Force les flags de compilation pour `llama-cpp-python`. |
| `FORCE_CMAKE` | `1` | Oblige `pip`/`uv` à recompiler le wheel binaire. |
| `HSA_OVERRIDE_GFX_VERSION` | `10.3.0` | **Spécifique AMD.** Permet le support des cartes Radeon Consumer (RX 6000/7000) sur ROCm. |
| `MESA_LOADER_DRIVER_OVERRIDE` | `dzn` | **Spécifique WSL2.** Force l'usage de Mesa Dozen (Vulkan over D3D12). |

## 3. Gestion de l'Accélération Matérielle (GPU)

Le script implémente une logique de détection et de *Self-Healing* (auto-réparation) des dépendances GPU.

### 3.1 Logique de détection (`configure_gpu_support`)

Le script vérifie séquentiellement :

1.  **NVIDIA (Priorité 1) :**
    * Check : `nvidia-smi`.
    * Action : Vérifie `nvcc`. Si absent, installe le CUDA Toolkit. Définit `CMAKE_ARGS="-DGGML_CUDA=on"`.
2.  **AMD ROCm (Priorité 2) :**
    * Check : `rocm-smi` ou `rocminfo`.
    * Action : Vérifie `hipcc`. Si absent, installe `rocm-hip-sdk`. Définit `CMAKE_ARGS="-DGGML_HIPBLAS=on"`.
    * *Note Technique :* Désactivation forcée de Flash Attention sur AMD pour stabilité.
3.  **Vulkan / WSL2 (Priorité 3) :**
    * Check : Présence de `libd3d12.so` (WSL) ou `vulkaninfo`.
    * Action : Installe les shaders et headers Vulkan. Définit `CMAKE_ARGS="-DGGML_VULKAN=on"`.
4.  **CPU (Fallback) :**
    * Si rien n'est trouvé, aucune compilation spécifique n'est faite.

### 3.2 Mécanisme de changement de configuration

Le script maintient un fichier d'état : `.venv/.installed_mode`.
Au lancement, il compare le mode détecté (ex: `cuda`) avec le dernier mode installé.
* **Si différence :** Force la réinstallation complète (`--force-reinstall --no-cache-dir`) de `llama-cpp-python` pour recompiler les binaires partagés (.so/.dll) avec les bons liens dynamiques.

## 4. Configuration des Services

### 4.1 Serveur d'Inférence (Llama.cpp)

Lancé via `python -m llama_cpp.server`.
* **Port :** 10000
* **Contexte (`n_ctx`) :** 16384 tokens.
* **Offloading GPU (`n_gpu_layers`) :** `-1` (Tout sur le GPU). *À ajuster si OOM (Out Of Memory).*
* **Flash Attention :** Activé par défaut (`--flash_attn true`) sauf sur AMD/Vulkan.

### 4.2 OpenWebUI & Configuration RAG

OpenWebUI est configuré via variables d'environnement au lancement. Le pipeline RAG est hardcodé pour utiliser des modèles spécifiques performants en français.

**Configuration RAG (Environment Variables) :**

```bash
ENABLE_OLLAMA_API="False"           # On utilise le backend OpenAI (llama-cpp)
OPENAI_API_BASE_URL="[http://127.0.0.1:10000/v1](http://127.0.0.1:10000/v1)"

# Embedding (Vectorisation)
RAG_EMBEDDING_MODEL="OrdalieTech/Solon-embeddings-base-0.1" # Modèle FR performant

# Chunking
CHUNK_SIZE="500"
CHUNK_OVERLAP="50"

# Retrieval & Reranking
RAG_TOP_K="99"                      # Récupère large
RAG_RERANKING_ENGINE="sentence_transformers"
RAG_RERANKING_MODEL="BAAI/bge-reranker-v2-m3" # Trie les résultats par pertinence
RAG_TOP_K_RERANKER="89"             # Garde les meilleurs après rerank
```

## 5. Modèles utilisés

Les modèles sont définis dans les variables en tête de script `launcher.sh`.

1. **LLM Principal :** `phi-4-Q4_K_M.gguf`
* *Source :* HuggingFace (unsloth/phi-4-GGUF).
* *Raison :* Bon compromis performance/VRAM (4-bit quantization).


2. **Modèle Embedding :** `OrdalieTech/Solon-embeddings-base-0.1`
* Téléchargé automatiquement par OpenWebUI au premier run RAG.


3. **Modèle Reranker :** `BAAI/bge-reranker-v2-m3`
* Téléchargé automatiquement par OpenWebUI.

## 6. Intégration Système (Desktop)

Le script `creation_raccourci.sh` permet l'intégration dans les environnements de bureau Linux (GNOME/KDE).

* Génère un fichier `.desktop` conforme aux spécifications XDG.
* Emplacement : `~/.local/share/applications/` et copie sur `~/Desktop` ou `~/Bureau`.
* Note : Utilise des chemins absolus résolus dynamiquement (`pwd`) pour éviter les erreurs de PATH.

## 7. Maintenance et Évolution

### Mise à jour de l'application

Le script `launcher.sh` exécute `update_python_deps` à chaque lancement.

* Il met à jour `open-webui` vers la dernière version stable disponible sur PyPI.
* Il ne met à jour `llama-cpp-python` que si la configuration matérielle change ou si une mise à jour est explicitement demandée.

### Changer de Modèle LLM

Modifier les variables suivantes dans `launcher.sh` :

```bash
MODEL_FILE="nouveau-modele-Q4_K_M.gguf"
HF_URL="[https://huggingface.co/auteur/repo/resolve/main/$](https://huggingface.co/auteur/repo/resolve/main/$){MODEL_FILE}"

```

*Si le nom du fichier change, le script téléchargera automatiquement le nouveau modèle.*

### Troubleshooting Courant (Dev)

* **Erreur `nvcc not found` alors que CUDA est installé :** Le script tente de l'installer, mais sur certains OS, le PATH n'est pas mis à jour sans relancer la session. Vérifier `/usr/local/cuda/bin`.
* **Crash AMD (Segfault) :** Souvent lié à Flash Attention. Vérifier que `FLASH_ATTN_FLAG` est vide dans la section AMD du `launcher.sh`.
* **Boucle de réinstallation :** Si le fichier `.venv/.installed_mode` contient des caractères corrompus ou si les arguments CMake changent constamment, supprimer le dossier `.venv` pour repartir propre.
* **Conflit de ports :** Si les ports 10000 ou 8080 sont occupés, modifier les variables `LLAMA_PORT` et `OPENWEBUI_PORT` en début de script.
