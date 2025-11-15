# README – LibreStorien 2.0

Assistant Documentaire Montpellibre (Llama.cpp + OpenWebUI)

Ce projet fournit un environnement complet pour créer un **assistant IA local**, totalement autonome (sans API externe), capable de répondre **exclusivement** à partir des documents officiels de l’association Montpellibre.

Il repose sur :

* **llama.cpp** → exécution locale d’un modèle GGUF
* **OpenWebUI** → interface utilisateur interactive
* **Un launcher automatique Linux/macOS**
* **Un script de configuration Knowledge/RAG**

L'objectif :
*Avoir un assistant fiable, reproductible, et strictement basé sur vos documents PDF.*

---

# 1. Launcher automatique (OpenWebUI + llama.cpp)

Ce projet inclut un launcher complet qui permet de démarrer l’environnement **en un seul clic**.

Ce launcher a un objectif principal :

**démarrer automatiquement l’environnement IA libre et local LibreStorien** :

* Vérifie ou installe Python 3.11
* Crée la venv
* Installe `llama-cpp-python[server]` et `open-webui`
* Télécharge le modèle si nécessaire
* Lance le serveur **llama.cpp**
* Lance **OpenWebUI** (connecté en OpenAI-compatible sur le port 10000)
* Ouvre automatiquement l'UI dans le navigateur

### Services lancés

| Service          | Port      | Fonction                                          |
| ---------------- | --------- | ------------------------------------------------- |
| llama_cpp.server | **10000** | API OpenAI-compatible servie par le modèle GGUF   |
| OpenWebUI        | **8080**  | Interface utilisateur, gestion RAG, knowledge, UI |

### Lire les logs

* `log_llamacpp.txt` → logs du modèle local
* `log_openwebui.txt` → logs OpenWebUI

### Arrêt contrôlé

Le script capture `Ctrl+C` ou fermeture terminal →
Il tue proprement les processus lancés.

---

# 2. Configuration Knowledge + Assistant LibreStorien

## Prérequis

Avant tout, vous devez :

1. **Lancer le launcher principal** si non réalisé précédemment
   Ce launcher démarre automatiquement :

   * la venv Python,
   * le serveur `llama_cpp.server`,
   * OpenWebUI,
   * et ouvre l’interface : [http://127.0.0.1:8080](http://127.0.0.1:8080)

2. **Créer votre compte admin OpenWebUI**
   (première connexion obligatoire)

3. Aller dans :
   **Réglages → Compte → Clés d’API → JWT**
   Copier votre **JWT** (clé privée pour l’API).

4. Placer vos **fichiers PDF** dans le dossier :

   ```
   /docs
   ```

---

# Script d’installation : `setup_knowledge_model.sh`

Ce projet permet de configurer automatiquement un environnement RAG (« Retrieval Augmented Generation ») dans **OpenWebUI** afin de créer un assistant strictement basé sur les documents officiels de l’association Montpellibre.

Le script `setup_knowledge_model.sh` :

* crée ou réutilise une *Connaissance* OpenWebUI,
* upload et indexe automatiquement tous les fichiers PDF présents dans `/docs`,

---

# Prérequis

Avant tout, vous devez :

1. **Lancer le launcher principal**
   Ce launcher démarre automatiquement :

   * la venv Python,
   * le serveur `llama_cpp.server`,
   * OpenWebUI,
   * et ouvre l’interface : [http://127.0.0.1:8080](http://127.0.0.1:8080)

2. **Créer votre compte admin OpenWebUI**
   (première connexion obligatoire)

3. Aller dans :
   **Réglages → Compte → Clés d’API → JWT**
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

* S’il n’existe pas → il est créé.
* S’il est vide → le script s’arrête avec un message utile.

### 3. Demande du JWT

Le script l’utilise pour authentifier toutes les requêtes API.

### 4. Vérification de l’API

Le script vérifie la disponibilité de :

* `/api/v1/system/health`
* `/api/config`

### 5. Création ou réutilisation de la *Connaissance* Montpellibre

Nom interne :

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

# Ce que le script **ne peut pas** faire automatiquement

Votre version d’OpenWebUI **ne supporte pas** la création de modèles custom via :

```
POST /api/models/create
```

→ L’API renvoie systématiquement `405 Method Not Allowed`.

Donc, la **création du modèle custom LibreStorien** doit être faite **manuellement dans l’interface**.

Il va falloir rentrer manuellement :

* le prompt système complet,
* le nom recommandé du modèle,
* les champs exacts à remplir.

---

# Création manuelle du modèle custom LibreStorien

Voici la procédure complète.

## 1. Ouvrir OpenWebUI
[http://127.0.0.1:8080](http://127.0.0.1:8080)

## 2. Aller dans :

**Espace de Travail → Modèles → New Model**

## 3. Remplir les champs suivants :

---

### **Nom du modèle**

Choississez un nom

---

### **Base du modèle**

Choississez le modèle déjà chargé depuis le menu déroulant

---

### **Description**

Ajoutez une description (par exemple) :

```
Assistant administratif basé sur la connaissance 'Documents Montpellibre'
```

---

### **System Prompt**

Copiez-collez le prompt affiché par le script.

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

---

### **Connaissances**

Sélectionnez la Connaissance "Documents Montpellibre" préalablement chargée.

---

### **Capacités**

Décochez ou cochez les outils que vous souhaitez.
Par exemple, dans ce contexte il faut éviter :
- Recherche Web
- Génération d'images
- Interpreteur de code

---

Enregistrez - c'est prêt !

# Utilisation

1. Allez dans **Conversations**
2. Créez une nouvelle conversation
3. Sélectionnez le modèle avec le nom préalablement choisi

Vous pouvez maintenant interroger LibreStorien.
