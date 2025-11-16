# README – LibreStorien 2.0

Assistant Documentaire Montpellibre (Llama.cpp + OpenWebUI)

Ce projet fournit un environnement complet pour créer un assistant IA local, totalement autonome (sans API externe), capable de répondre exclusivement à partir des documents (RAG).

Il repose sur :

* **llama.cpp** -> exécution locale d’un modèle GGUF
* **OpenWebUI** -> interface utilisateur interactive
* **Un launcher automatique Linux/macOS**
* **Un script de configuration Knowledge/RAG**

L'objectif :
*Avoir un assistant administratif fiable, reproductible, flexible et strictement basé sur les documents PDF.*

---

# 1. Launcher automatique (OpenWebUI + llama.cpp)

Ce projet inclut un launcher complet qui permet de démarrer l’environnement simplement en executant le fichier `launcher.sh`. Ce fichier permet l'installation sur les distributions et plateformes suivantes :
- Ubuntu / Debian
- Fedora
- Arch Linux
- macOs (Homebrew)

Ce launcher a un objectif principal :

**démarrer automatiquement l’environnement IA libre et local LibreStorien** :

* Vérifie ou installe Python 3.11 (version compatible avec OpenWeb Ui)
* Crée la venv
* Installe `llama-cpp-python[server]` et `open-webui`
* Télécharge le modèle si nécessaire (phi-4-Q4_K_M.gguf par défaut)
* Lance le serveur llama.cpp [http://127.0.0.1:10000](http://127.0.0.1:10000)
* Lance OpenWebUI [http://127.0.0.1:8080](http://127.0.0.1:8080)
* Ouvre automatiquement l'UI dans le navigateur

### Services lancés

| Service          | Port      | Fonction                                          |
| ---------------- | --------- | ------------------------------------------------- |
| llama_cpp.server | **10000** | API OpenAI-compatible servie par le modèle GGUF   |
| OpenWebUI        | **8080**  | Interface utilisateur, gestion RAG, knowledge, UI |

### Lire les logs

* `log_llamacpp.txt` -> logs du modèle local
* `log_openwebui.txt` -> logs OpenWebUI

### Arrêt contrôlé

Le script capture `Ctrl+C` ou fermeture terminal ->
Il tue proprement les processus lancés et vide la RAM du modèle chargé.

---

# 2. Configuration Knowledge + Assistant LibreStorien

## Script d’installation : `creation_connaissance.sh`

Ce projet permet de configurer automatiquement un environnement RAG (« Retrieval Augmented Generation ») dans OpenWebUI afin de créer un assistant strictement basé sur les documents chargés.

Le script `creation_connaissance.sh` :

* crée ou réutilise une *Connaissance* OpenWebUI,
* upload et indexe automatiquement tous les fichiers PDF présents dans `/docs` (OpenWeb Ui ne prends pas encore en cahrge les fichiers .docx ou .odt),

---

## Prérequis

1. **Lancer le launcher principal** si non réalisé précédemment

2. **Créer votre compte admin OpenWebUI**
   (première connexion obligatoire)

3. Aller dans :
   **Réglages -> Compte -> Clés d’API -> JWT**
   Copier votre **JWT** (clé privée pour l’API).

4. Placer vos **fichiers PDF** dans le dossier :

   ```
   /docs
   ```

---

## Ce que le script réalise automatiquement

### 1. Vérification des dépendances

* `curl`
* `jq`

Si une dépendance manque, le script tente automatiquement de l’installer.

### 2. Vérification du dossier `/docs`

* S’il n’existe pas -> il est créé.
* S’il est vide -> le script s’arrête avec un message invitant l'utilisateur à déposer ses documents dans le nouveau dossier créé.

### 3. Demande du JWT

Le script l’utilise pour authentifier toutes les requêtes API.

### 4. Vérification de l’API

Le script vérifie la disponibilité de :

* `/api/v1/system/health`
* `/api/config`

### 5. Création ou réutilisation de la *Connaissance*

Nom interne par défaut (possibilité de changer dans le script) :

```
Documents Montpellibre
```

Le script :

* vérifie si la Connaissance existe déjà,
* sinon la crée automatiquement.

### 6. Upload et indexation automatique des PDF

#### Attention, les fichier `.docx`et `.odt` ne sont pas pris en compte

Pour chaque fichier PDF dans `/docs` :

* upload via `/api/v1/files/`
* attachement à la connaissance via `/api/v1/knowledge/{id}/file/add`
* génération automatique des embeddings
* indexation dans la base vectorielle

---

### Ce que le script ne peut pas faire automatiquement

La version actuelle d’OpenWebUI ne supporte pas encore la création de modèles custom via :

```
POST /api/models/create
```

-> L’API renvoie systématiquement `405 Method Not Allowed`.

Donc, la création du modèle custom LibreStorien doit être faite manuellement dans l’interface.

---

## Création manuelle du modèle custom LibreStorien

Voici la procédure complète.

### 1. Ouvrir OpenWebUI
[http://127.0.0.1:8080](http://127.0.0.1:8080)

### 2. Aller dans :

**Espace de Travail -> Modèles -> New Model**

### 3. Remplir les champs suivants :

---

- #### Nom du modèle

Choisir un nom

- #### Base du modèle

Choisir le modèle déjà chargé depuis le menu déroulant

- #### Description

Ajouter une description (par exemple) :

```
Assistant administratif basé sur la connaissance 'Documents Montpellibre'
```

- #### System Prompt

Copier-coller le prompt affiché par le script.

Voici la version complète :

```
Tu es LibreStorien, un assistant administratif spécialisé pour l'association Montpellibre.
Tes réponses doivent être basées exclusivement en français et portant sur les documents indexés dans la Connaissance attachée (statuts, rapports, PV d’AG, AAP, etc.).

RÈGLES STRICTES :
- Si l’information ne se trouve pas explicitement dans les documents fournis, réponds exactement : "Je ne sais pas. Cette information ne semble pas être dans les documents."
- Ne fais AUCUNE supposition, extrapolation ou ajout de contexte externe (pas de recherches web, pas d’historique implicite).
- Si une question est ambiguë, demande une clarification en restant dans le cadre des documents.
- Quand tu cites un élément, reformule-le de manière claire et structurée, mais sans inventer de contenu.

Ta priorité absolue est la fidélité aux documents, pas la créativité.
```

- ### Connaissances

Sélectionner la Connaissance "Documents Montpellibre" préalablement chargée.

- ### Capacités

Décocher ou cocher les outils souhaités.
Par exemple, dans ce contexte il faut éviter :
- Recherche Web
- Génération d'images
- Interpreteur de code

---

# Utilisation

1. Aller dans **Conversations**
2. Créer une nouvelle conversation
3. Sélectionner le modèle avec le nom préalablement choisi

LibreStorien est prêt à être interrogé.

# Optionel - Création automatique d’un raccourci d’application (.desktop) Linux

Ce script permet de générer automatiquement un raccourci d'application Linux pour lancer LibreStorien (ou tout autre script).
Il crée :

* un fichier `.desktop` dans :
  `~/.local/share/applications/`
* un raccourci exécutable directement sur le bureau
* une entrée visible dans le menu des applications

Cela permet de lancer l'assistant IA comme une application native, sans passer par le terminal.

---

## 1. Fonction du script

Le script :

1. détecte automatiquement le dossier dans lequel il se trouve
2. localise le script de lancement `launcher.sh`
3. optionnellement, utilise une icône `icon.jpeg` si elle est présente
4. demande à l’utilisateur le nom de l’application
5. génère un fichier `.desktop` correctement formaté
6. copie ce raccourci sur le bureau
7. rend le tout exécutable

---

## 2. Pré-requis

Placer dans le **même dossier** :

```
creation_raccourci.sh
launcher.sh
icon.jpeg   (optionnel)
```

Ensuite rendre le script exécutable :

```bash
chmod +x creation_raccourci.sh
```

---

## 3. Utilisation

Lancer simplement :

```bash
./creation_raccourci.sh
```

Le script :

1. Demande un nom d’application (ex. : `LibreChat`, `LibreStorien`, etc.)
2. Créer automatiquement :

```
~/.local/share/applications/<nom>.desktop
~/Desktop/<nom>.desktop  (ou ~/Bureau selon la langue)
```

---

## 4. Contenu généré du fichier .desktop

Le script génère automatiquement un fichier du type :

```
[Desktop Entry]
Type=Application
Version=1.0
Name=<nom>
Comment=Lancer <nom>
Exec=/chemin/vers/launcher.sh
Icon=/chemin/vers/icon.jpeg
Terminal=true
Categories=Utility;Development;
```

Il est exécutable et reconnu par les environnements de bureau :

* KDE Plasma
* GNOME
* XFCE
* Cinnamon
* Mate
* Deepin

---

## 5. Exécution sécurisée

Le script :

* n’écrase pas de fichier `.desktop` système
* copie uniquement dans les emplacements utilisateur
* respecte les conventions Freedesktop

---

## 6. Suppression du raccourci

Pour supprimer le raccourci d’application :

```bash
rm ~/.local/share/applications/<nom>.desktop
rm ~/Desktop/<nom>.desktop
```
