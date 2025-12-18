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

Nommez-la "Activités [Année en cours]"

Et déposer le fichier **activites.md** contenant toutes les activités formatées de l'année 2025 dans cet espace. Le modèle s'appuiera sur le contenu de ce document pour répondre.

Voici le format des activités pour aider le modèle à sélectionner les bons sujets :

```
#Activité : Rendez-vous L'apéro des quatre libertés
**Type :** Rencontre
**Date :** Jeudi 17 avril 2025 de 19h00 à 21h00
**Lieu :** Atelier des Pigistes, 171 bis, rue Frimaire, 34000 Montpellier
**Description :** Rencontre autour des travaux de l’April, FSF, FSFE et La Quadrature Du Net.
```

## 3. Création manuelle du modèle custom LibreStorien

Une fois la Connaissance prête, il est temps de créer le modèle associé. Aller dans :

Espace de Travail -> Modèles -> Nouveau Modèle

### 1. Remplir les champs suivants :

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

- ### Prompt par défaut

(Fortement conseillé) Possibilité de rajouter une suggestion de prompt au moment de la création d'une nouvelle conversation avec ce modèle.

Cliquer sur Ajouter, puis placer ce texte dans "prompt" :

```
Liste exhaustivement toutes les activités dont le Type contient le mot "Permanence".
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

# Utilisation pour le Rapport d'activité

1. Aller dans **Conversations**
2. Créer une nouvelle conversation
3. Sélectionner le modèle avec le nom préalablement choisi

Le modèle est prêt à être interrogé.

# Guide d'utilisation

Les activités ont chacune un Type associé, dont voici la liste complète :

* **Atelier** (ex: Atel'libre, Groupia, Blender, PAO)
* **Conférence** (ex: JdLL, RAFLL journées d'étude, RMS, Conférences thématiques)
* **Événementiel** (ex: Fête de la Science, Libre en Fête, Matos Gratos, Opération Mayotte)
* **Festival** (ex: Le printemps du climat, Semaine Culturelle des afriques)
* **Hackathon** (ex: HOTOSM, Fintech Mauritanie)
* **Install-Party** (ex: Jerripartie, Installe Partie Linux, Installe Partie Mayotte)
* **Permanence** (ex: Linuxerie, Wikipermanence)
* **Radio** (ex: Émissions FM-Plus "Temps Libre", "Entrée Libre")
* **Rencontre** (ex: Apéros, Pique-niques, HérOSM, Framapermanence)
* **Réunion Interne** (ex: AG, Réunions d'organisation RAFLL/CLO)
* **Salon** (ex: Stand JdLL, Antigone des Assos)
* **Stage** (ex: Stage Jeux vidéo Gdevelop)
* **Technique** (ex: Booster Camps)

La stratégie va donc être de demander au modèle de rédiger et faire la liste de toutes les activités par type.

Pour de meilleurs résultats, il est fortement recommandé d'utiliser la question suivante afin de faire générer le rapport partie par partie. En effet, essayer de générer l'entièreté du rapport en un message risque de conduire à une saturation de la mémoire de l'ordinateur et donc à une réponse incorrecte et imprécise.

```
Liste exhaustivement toutes les activités dont le Type contient le mot "Permanence".
```

Puis refaire la même opération en changeant simplement le type.

# Ouverture

En suivant cette procédure, il est ainsi possible de créer une Connaissance et un modèle pour chaque type de document désiré. Il faudra cependant adapter le prompt system du modèle, et peut-être certains paramétrages dans le panneau administrateur, suivant le besoin et la taille des documents de la Connaissance.

De plus, il est tout à fait possible de sélectionner le modèle de base chargé par défaut dans l'interface et de lui poser directement des questions sur un document qu'on aura joint avec le prompt (ex : questionner un document Appel d'Offres pour connaitre les informations qu'il contient).

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
