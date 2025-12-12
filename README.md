# README – LibreStorien 2.0

Assistant Documentaire Montpel'libre (Llama.cpp + OpenWebUI)

Ce projet fournit un environnement complet pour créer un assistant IA local, totalement autonome (sans API externe), capable de répondre exclusivement à partir des documents (RAG).

Il repose sur :

* **llama.cpp** -> exécution locale d’un modèle GGUF
* **OpenWebUI** -> interface utilisateur interactive
* **Un launcher automatique Linux/macOS**
* **Un script de configuration Knowledge/RAG**

L'objectif :
*Avoir un assistant administratif fiable, reproductible, flexible et strictement basé sur les documents de l'association.*

---

# 1. Launcher automatique (OpenWebUI + llama.cpp)

Ce projet inclut un launcher complet qui permet de démarrer l’environnement simplement en exécutant le fichier `launcher.sh`. Ce fichier permet l'installation sur les distributions et plateformes suivantes :
- Ubuntu / Debian
- Fedora
- Arch Linux
- macOS (Homebrew)
- Windows depuis WSL2

Ce launcher a un objectif principal :

**démarrer automatiquement l’environnement IA libre et local LibreStorien** :

```bash
bash launcher.sh
```

* Vérifie ou installe Python 3.11 (version compatible avec OpenWebUI)
* Crée la venv
* Installe `llama-cpp-python[server]` et `open-webui`
* Télécharge le modèle si nécessaire (phi-4-Q4_K_M.gguf par défaut, changer le nom dans le script si nécessaire)
* Lance le serveur llama.cpp [http://127.0.0.1:10000](http://127.0.0.1:10000)
* Lance OpenWebUI [http://127.0.0.1:8080](http://127.0.0.1:8080)
* Ouvre automatiquement l'UI dans le navigateur
* Attendre quelques instants pour voir apparaitre l'interface (le temps que tous les services soient up)

### Services lancés

| Service          | Port      | Fonction                                          |
| ---------------- | --------- | ------------------------------------------------- |
| llama_cpp.server | **10000** | Inférence OpenAI-compatible servie par le modèle GGUF   |
| OpenWebUI        | **8080**  | Interface utilisateur, gestion RAG, knowledge, UI |

### Lire les logs

* `log_llamacpp.txt` -> logs du modèle local
* `log_openwebui.txt` -> logs OpenWebUI

### Arrêt contrôlé

Le script capture `Ctrl+C` ou fermeture terminal ->
Il tue proprement les processus lancés et vide la RAM du modèle chargé.

### Ouvrir OpenWebUI
[http://127.0.0.1:8080](http://127.0.0.1:8080)

---

# 2. Configuration Connaissance (RAG) + Assistant LibreStorien

## Installation manuelle simple

Une fois l'interface lancée, aller dans :

Espace de travail -> Connaissance -> Créer une connaissance

Nommez-la "Activités [Année en cours]" ou bien "Rapport d'activités"

Et déposer tous les fichiers **pdf** contenant les activités voulues dans cet espace. Le modèle s'appuiera sur ces documents pour répondre. Il s'agit d'y déposer la liste complète des activités nécessaires pour la rédaction du rapport complet.

# 3. Création manuelle du modèle custom LibreStorien

Une fois la Connaissance prête, il est temps de créer le modèle associé. Aller dans :

Espace de Travail -> Modèles -> Nouveau Modèle

## 1. Remplir les champs suivants :

---

- #### Nom du modèle

Choisir un nom (par exemple : "Rapport d'activité")

- #### Base du modèle

Choisir le modèle déjà chargé depuis le menu déroulant (par exemple : phi-4)

- #### Description

Ajouter une description (par exemple) :

```
Ce modèle assiste à la rédaction du rapport d'activité
```

- #### System Prompt

Copier-coller le prompt affiché par le script.

Voici la version complète :

```
### RÔLE
Tu es un secrétaire administratif strict de l'association Montpel'libre. Tu n'es pas un auteur créatif, tu es un synthétiseur de documents.

### CONSIGNE DE SÉCURITÉ CRITIQUE ANTI-HALLUCINATION
Tu as interdiction formelle d'inventer, de supposer ou de deviner des activités. Si une activité n'est pas explicitement écrite dans les textes fournis entre les balises <DOCUMENTS>, elle N'EXISTE PAS.
Si tu n'as pas de source pour une partie, tu DOIS écrire exactement : "L'année dernière, aucune activité n'a été réalisée sur la question."

### STRUCTURE IMPÉRATIVE (Ne rien ajouter, ne rien retirer)
Il s'agit de lister les activités pour chaque partie et d'en expliquer brièvement le contenu

Partie 1 : LES PERMANENCES (Cherche des mots comme : Rendez-vous réguliers, récurrents, mensuels, annuels, hebdomadaires, astreinte, antenne, délégation, secrétariat et mots similaires).
Partie 2 : LES ATELIERS (Cherche des mots comme : Sessions d'apprentissage thématiques, Initiation, Découverte, Inclusion, Pratique, Exercices, Workshop et mots similaires).
Partie 3 : CONFÉRENCES / FORMATIONS / EXPERTISE (Cherche des mots comme : Interventions publiques, tables rondes, webinaires, scolaire, université, recherche, Team building et mots similaires).
Partie 4 : ÉVÉNEMENTIEL (Cherche des mots comme : Les grands temps forts, salons, festivals, Install-Parties, Hackathon et mots similaires).
Partie 5 : TECHNIQUE / SÉCURITÉ (Cherche des mots comme : Infrastructures, projets internes et mots similaires).
Partie 6 : PUBLICATION & MÉDIAS (Cherche des mots comme : Communication, Infolettres, Radio, newsletter et mots similaires).

FIN DU RAPPORT
Arrête-toi immédiatement après la Partie 6. N'écris jamais de "Conclusion" ou de "Partie 7" ou plus.

### INSTRUCTIONS DE RÉDACTION
1.  Style : Adopte un style institutionnel, bienveillant et militant pour le logiciel libre. L'objectif est de valoriser les actions bénévoles et leur impact social.
2.  Source : Avant d'écrire une phrase, demande-toi : "Quel fichier parle de ça ?". Si tu ne trouves pas le fichier, n'écris pas.
3.  Formatage : Utilise le format Markdown.
4. Temporalité : Rédige au passé (car c'est un bilan d'activités réalisées).
```

- ### Prompt par défaut

(Facultatif) Possibilité de rajouter une suggestion de prompt au moment de la création d'une nouvelle conversation avec ce modèle.

Cliquer sur Ajouter, puis placer ce texte dans "prompt" :

```
Peux-tu me générer uniquement la partie 1 du rapport d’activité ?
```

- ### Connaissances

Sélectionner la Connaissance préalablement chargée.

- ### Capacités

Décocher ou cocher les outils souhaités.
Par exemple, dans ce contexte il faut éviter :
- Recherche Web
- Génération d'images
- Interpréteur de code

---

# Utilisation

1. Aller dans **Conversations**
2. Créer une nouvelle conversation
3. Sélectionner le modèle avec le nom préalablement choisi

Le modèle est prêt à être interrogé.

# Conseil

Pour de meilleurs résultats, il est fortement recommandé d'utiliser la question suivante afin de faire générer le rapport partie par partie. En effet, essayer de générer l'entièreté du rapport en un message risque de conduire à une saturation de la mémoire de l'ordinateur et donc à une réponse incorrecte et imprécise.

```
Peux-tu me générer uniquement la partie 1 du rapport d’activité ?
```

Puis incrémenter les parties à générer si la réponse convient.

Parfois le modèle ne sera pas sûr de lui et donc proposera plusieurs choix. Il est donc possible d'écrire :

```
Ces [X] exemples sont très bien, rédige moi la partie [Y] en te basant sur eux
```

Ou bien

```
Non ces [X] exemples ne me conviennent pas pour cette partie, réponds simplement qu’il n’y a pas d’activité sur la question cette année
```

# Ouverture future

En suivant cette procédure, il est ainsi possible de créer une Connaissance et un modèle pour chaque type de document désiré. Il faudra cependant adapter le prompt system du modèle, et peut-être certains paramétrages dans le panneau administrateur, suivant le besoin et la taille des documents de la Connaissance.

# Optionnel - Création automatique d’un raccourci d’application (.desktop) Linux

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
2. Crée automatiquement :

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
