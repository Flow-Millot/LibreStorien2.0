# Documentation Technique & Guide de Déploiement - LibreStorien 2.0

* **Version du document :** 2.0 (Unifié)
* **Cible :** Développeurs, DevOps, Administrateurs Système
* **Objet :** Architecture, déploiement, configuration RAG et maintenance de l'Assistant Local.

## 1. Vue d'ensemble et Architecture

LibreStorien est une solution d'IA générative locale ("On-Premise") axée sur le RAG (Retrieval-Augmented Generation). Elle est conçue pour être agnostique du système hôte (Linux/macOS/WSL2) et gère automatiquement l'approvisionnement des ressources matérielles (CPU/GPU).

L'objectif est de fournir un assistant administratif fiable, reproductible, flexible et strictement basé sur les documents de l'association (ex: Rapports d'activités).

### 1.1 Stack Technologique

* **Orchestration :** Scripts Bash (`launcher.sh`, `creation_raccourci.sh`).
* **Gestionnaire de paquets Python :** `uv` (astral.sh) pour la rapidité et la gestion des venv.
* **Runtime Python :** Python 3.11 (Hard requirement pour compatibilité OpenWebUI à date).
* **Moteur d'inférence (Backend) :** `llama-cpp-python[server]` (Binding Python pour llama.cpp).
* **Interface & RAG (Frontend/Middleware) :** `OpenWebUI`.
* **Stockage Vectoriel :** ChromaDB (embarqué dans OpenWebUI).

### 1.2 Flux de communication

1. **Utilisateur** -> Navigateur Web -> **OpenWebUI** (Port `8080`).
2. **OpenWebUI** -> API Call (Format OpenAI) -> **llama_cpp.server** (Port `10000`).
3. **llama_cpp.server** -> Inférence sur fichier GGUF -> **Hardware** (CUDA/ROCm/Vulkan/CPU).

## 2. Prérequis Système

Le projet nécessite des ressources matérielles conséquentes pour fonctionner de manière fluide.

### 2.1 Configuration Matérielle

| Composant | Configuration Minimale (Lent) | Configuration Recommandée (Fluide) |
| --- | --- | --- |
| **Processeur (CPU)** | Récent (AMD Ryzen 5 / Intel i5 / puce M2 Apple) | Récent (AMD Ryzen 7 / Intel i7 / puce M4 Apple) |
| **Mémoire Vive (RAM)** | 16 Go DDR4 | 32 Go DDR4/DDR5 |
| **Carte Graphique (GPU)** | Aucune (pour puce M4 seulement) ou AMD avec 12 Go VRAM | Nvidia RTX avec 16 Go VRAM |
| **Stockage** | 10 Go d'espace libre | 10 Go d'espace libre |

> **Note sur la VRAM :** Le projet est optimisé pour utiliser environ **12 Go de mémoire vidéo (VRAM)**. En dessous (ex: 6/8 Go), le système fera de l'offloading partiel sur le CPU, ralentissant la génération.

### 2.2 Prérequis Logiciels

* **OS :** Linux (Ubuntu/Debian/Fedora/Arch), macOS (Homebrew) ou Windows via WSL2.
* **Drivers GPU :**
* *Nvidia :* Drivers CUDA 12+ installés.
* *AMD :* ROCm (détecté par le script).


* **Réseau :** Connexion Internet requise uniquement au premier lancement (téléchargement des modèles).

## 3. Installation et Lancement (`launcher.sh`)

Le fichier `launcher.sh` est le point d'entrée critique. Il agit comme un gestionnaire de configuration (CM) léger et un superviseur de processus.

### 3.1 Utilisation standard

Pour démarrer l'environnement :

```bash
bash launcher.sh
```

**Avertissement Premier Lancement :**
Soyez patient. Le système télécharge automatiquement plusieurs modèles volumineux (LLM + Embedding + Reranker).
*Temps estimé :* 2 à 10 minutes. Ne fermez pas le terminal.

### 3.2 Analyse technique du script (Under the hood)

Le script effectue la séquence d'initialisation suivante :

1. **Détection OS/Pkg Manager :** Supporte `apt`, `dnf`, `pacman`, `brew`.
2. **Bootstrapping Python :** Vérifie `python3.11`. Installe si absent (gestion des PPA pour Ubuntu).
3. **Installation de `uv` :** Télécharge le binaire `uv` pour gérer les dépendances.
4. **Environnement Virtuel :** Création/Activation de `.venv`.
5. **Détection Matérielle & Compilation JIT :** Analyse le GPU et compile `llama-cpp` avec les bons flags (voir Section 4).
6. **Gestion des Modèles :** Téléchargement via `curl`/`wget` si les fichiers GGUF sont absents.
7. **Lancement des Daemons :**
* `llama_cpp.server` (Port 10000) en background.
* `open-webui serve` (Port 8080) en background.


8. **Supervision :** Capture des signaux `trap` (EXIT, INT, TERM) pour tuer proprement les processus enfants (`kill_service`) et vider la VRAM.

### 3.3 Variables d'Environnement Critiques (Injection)

Le script injecte des variables dynamiques avant le runtime Python :

| Variable | Valeur (Exemple) | Description |
| --- | --- | --- |
| `CMAKE_ARGS` | `-DGGML_CUDA=on` | Force les flags de compilation pour `llama-cpp-python`. |
| `FORCE_CMAKE` | `1` | Oblige `pip`/`uv` à recompiler le wheel binaire. |
| `HSA_OVERRIDE_GFX_VERSION` | `10.3.0` | **AMD Specific.** Support des cartes Radeon Consumer (RX 6000/7000) sur ROCm. |
| `MESA_LOADER_DRIVER_OVERRIDE` | `dzn` | **WSL2 Specific.** Force l'usage de Mesa Dozen (Vulkan over D3D12). |

## 4. Gestion de l'Accélération Matérielle (GPU)

Le script implémente une logique de détection et de *Self-Healing* (auto-réparation) des dépendances GPU.

### 4.1 Logique de détection (`configure_gpu_support`)

1. **NVIDIA (Priorité 1) :**
* Check : `nvidia-smi`.
* Action : Vérifie `nvcc`. Si absent, installe CUDA Toolkit. Set `CMAKE_ARGS="-DGGML_CUDA=on"`.


2. **AMD ROCm (Priorité 2) :**
* Check : `rocm-smi` ou `rocminfo`.
* Action : Vérifie `hipcc`. Si absent, installe `rocm-hip-sdk`. Set `CMAKE_ARGS="-DGGML_HIPBLAS=on"`.
* *Note :* Désactivation forcée de Flash Attention sur AMD pour stabilité.


3. **Vulkan / WSL2 (Priorité 3) :**
* Check : Présence de `libd3d12.so` (WSL) ou `vulkaninfo`.
* Action : Installe shaders/headers Vulkan. Set `CMAKE_ARGS="-DGGML_VULKAN=on"`.


4. **CPU (Fallback) :** Aucune compilation spécifique.

### 4.2 Mécanisme de changement de configuration

Le script maintient un fichier d'état `.venv/.installed_mode`. Au lancement, il compare le mode détecté (ex: `cuda`) avec le dernier mode installé.

* **Si différence :** Force la réinstallation complète (`--force-reinstall --no-cache-dir`) de `llama-cpp-python` pour recompiler les binaires partagés.

## 5. Configuration des Services & Modèles

### 5.1 Serveur d'Inférence (Llama.cpp)

Lancé via `python -m llama_cpp.server`.

* **Port :** 10000
* **Contexte (`n_ctx`) :** 16384 tokens.
* **Offloading GPU (`n_gpu_layers`) :** `-1` (Tout sur le GPU). *À ajuster si OOM.*
* **Flash Attention :** Activé par défaut (`--flash_attn true`) sauf sur AMD/Vulkan.

### 5.2 OpenWebUI & Configuration RAG

OpenWebUI est configuré via variables d'environnement. Le pipeline RAG est hardcodé pour utiliser des modèles spécifiques :

```bash
ENABLE_OLLAMA_API="False"           # Backend OpenAI (llama-cpp)
OPENAI_API_BASE_URL="http://127.0.0.1:10000/v1"

# Embedding (Vectorisation)
RAG_EMBEDDING_MODEL="OrdalieTech/Solon-embeddings-base-0.1"

# Chunking
CHUNK_SIZE="500"
CHUNK_OVERLAP="50"

# Retrieval & Reranking
RAG_TOP_K="99"                      # Récupère large
RAG_RERANKING_ENGINE="sentence_transformers"
RAG_RERANKING_MODEL="BAAI/bge-reranker-v2-m3" # Trie par pertinence
RAG_TOP_K_RERANKER="89"             # Garde les meilleurs après rerank

```

### 5.3 Modèles utilisés

Définis dans les variables en tête de script `launcher.sh` :

1. **LLM Principal :** `phi-4-Q4_K_M.gguf` (HuggingFace unsloth/phi-4-GGUF).
2. **Modèle Embedding :** `OrdalieTech/Solon-embeddings-base-0.1`.
3. **Modèle Reranker :** `BAAI/bge-reranker-v2-m3`.

## 6. Guide Opérationnel : RAG et Assistant

Une fois l'interface accessible sur [http://127.0.0.1:8080](http://127.0.0.1:8080), suivez ces étapes pour configurer l'assistant documentaire.

### 6.1 Configuration de la Connaissance (Knowledge)

1. Aller dans **Espace de travail > Connaissance > Créer une connaissance**.
2. Nommer : "Activités [Année en cours]".
3. Déposer le fichier déjà prêt Markdown (`activites/activites.md` à la racine du projet).

**Format requis du fichier source pour le RAG :**

```markdown
#Activité : Rendez-vous L'apéro des quatre libertés
**Type :** Rencontre
**Date :** Jeudi 17 avril 2025 de 19h00 à 21h00
**Lieu :** Atelier des Pigistes, 171 bis, rue Frimaire, 34000 Montpellier
**Description :** Rencontre autour des travaux de l’April, FSF, FSFE...

```

### 6.2 Création du Modèle Custom

Aller dans **Espace de Travail > Modèles > Nouveau Modèle**.

* **Nom :** Rapport d'activité.
* **Base du modèle :** Sélectionner le modèle chargé (ex: phi-4).
* **Connaissances :** Sélectionner la base créée ci-dessus.
* **Capacités :** Décocher "Recherche Web", "Génération d'images", "Interpréteur de code".
* **System Prompt (Copier-coller) :**

```text
### RÔLE & OBJECTIF
Tu es le secrétaire de l'association Montpel'libre. TA SEULE MISSION : Lire le document fourni en source et extraire les activités réelles pour remplir le rapport ci-dessous. NE JAMAIS afficher les consignes ou le modèle vide. Affiche UNIQUEMENT le résultat rempli.

### MISSION
Ta mission est de lister EXHAUSTIVEMENT toutes les activités correspondant à la demande, sans en oublier aucune.

### CONSIGNE DE SÉCURITÉ (ANTI-HALLUCINATION)
1. Si aucune activité ne correspond au type demandé, écris UNIQUEMENT : "Aucune activité de ce type n'a été recensée."
2. N'invente jamais d'information.
3. Si le champ **Type :** de l'activité ne contient pas le mot-clé demandé, tu DOIS L'IGNORER TOTALEMENT.
4. Si le mot-clé demandé apparait ailleurs que dans le champ **Type :**, tu DOIS L'IGNORER TOTALEMENT.

### FORMAT DE RESTITUTION
Pour chaque activité valide trouvée, génère une puce :
* **[Titre exact de l'activité]** : [Développe en quelques phrases la description].

### FIN DU RAPPORT
Arrête-toi immédiatement après la Partie 6. N'écris jamais de "Conclusion" ou de "Partie 7" ou plus.

### TON ET STYLE
Adopte un ton institutionnel, neutre mais valorisant pour le bénévolat. Utilise le passé car il s'agit d'activités passées.
```

### 6.3 Utilisation (Prompting)

Pour éviter la saturation mémoire, générez le rapport par type d'activité.
Types disponibles : *Atelier, Conférence, Événementiel, Festival, Hackathon, Install-Party, Permanence, Radio, Rencontre, Réunion Interne, Salon, Stage, Technique*.

**Exemple de prompt :**

```text
Liste exhaustivement toutes les activités dont le Type contient le mot "Permanence".

```

## 7. Intégration Desktop

Le script `creation_raccourci.sh` permet l'intégration dans les environnements de bureau Linux (GNOME/KDE/XFCE).

* **Usage :** `./creation_raccourci.sh` (dans le même dossier que `launcher.sh`).
* **Fonctionnement :** Génère un fichier `.desktop` conforme XDG avec chemins absolus dynamiques.
* **Emplacement :** `~/.local/share/applications/` et copie sur le Bureau.

## 8. Maintenance et Troubleshooting

### 8.1 Mise à jour de l'application

Le `launcher.sh` exécute `update_python_deps` à chaque lancement :

* Met à jour `open-webui` (dernière version stable PyPI).
* Ne met à jour `llama-cpp-python` que si la config matérielle change ou sur demande explicite.

### 8.2 Changer de Modèle LLM

Modifier les variables dans `launcher.sh` :

```bash
MODEL_FILE="nouveau-modele-Q4_K_M.gguf"
HF_URL="https://huggingface.co/auteur/repo/resolve/main/${MODEL_FILE}"

```

*Le script téléchargera automatiquement le nouveau modèle au prochain lancement.*

### 8.3 Problèmes Courants

* **Erreur `nvcc not found` :** Vérifier le PATH (souvent `/usr/local/cuda/bin`).
* **Crash AMD (Segfault) :** Vérifier que Flash Attention est bien désactivé pour AMD dans le script.
* **Boucle de réinstallation :** Supprimer le dossier `.venv` pour forcer une réinstallation propre.
* **Conflit de ports :** Si 10000 ou 8080 occupés, modifier `LLAMA_PORT` et `OPENWEBUI_PORT` dans le script.

## 9. Retour et Amélioration

[Lien vers le questionnaire de satisfaction LibreStorien 2.0](https://framaforms.org/questionnaire-de-satisfaction-librestorien20-1765287993)