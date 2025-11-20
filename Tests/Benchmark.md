## Table des matières

- [Installer Koboldcpp](#installer-koboldcpp)
- [Télécharger les modèles](#telecharger-les-modeles)
- [Lancer un modèle](#lancer-un-modele)
- [Aller sur](#aller-sur)
- [Tests](#tests)
  - [4 petites questions](#4-petites-questions)
  - [Fichier de tests](#fichier-de-tests)
  - [Texte court](#texte-court)
  - [Questions texte court](#questions-texte-court)
  - [Texte 6000 tokens](#texte-6000-tokens)
  - [Questions 6000 tokens](#questions-6000-tokens)
  - [Texte 8000 tokens](#texte-8000-tokens)
  - [Questions 8000 tokens](#questions-8000-tokens)
  - [Texte 10000 tokens](#texte-10000-tokens)
  - [Questions 10000 tokens](#questions-10000-tokens)
  - [Texte 12000 tokens](#texte-12000-tokens)
  - [Questions 12000 tokens](#questions-12000-tokens)



### Installer Koboldcpp

https://github.com/LostRuins/koboldcpp

### Telecharger les modeles

```bash
wget https://huggingface.co/unsloth/Phi-4-mini-instruct-GGUF/resolve/main/Phi-4-mini-instruct.Q8_0.gguf

wget https://huggingface.co/unsloth/Phi-4-mini-instruct-GGUF/resolve/main/Phi-4-mini-instruct-Q6_K.gguf

wget https://huggingface.co/unsloth/Phi-4-mini-instruct-GGUF/resolve/main/Phi-4-mini-instruct-Q4_K_M.gguf

```

### Lancer un modele

**Attention :**

`--contextsize 12000` : fixer le contexte pour tous tes tests.

`--quantkv` : compresser le KV-cache (fort gain mémoire).
1 = conservateur (qualité OK, gain net)
2 = plus agressif (encore moins de RAM/VRAM)

`--gpulayers` : quantité de couches offloadées en GPU.
Q6 : viser offload total (999) si ça tient.
Q8 : offload partiel (~20–28 couches) pour rester sous ~14 Go (le reste reste CPU).

`--usemmap` : réduire les pics mémoire au chargement.
Ne pas mettre `--usecpu` si GPU-only

```bash
koboldcpp phi-4-Q6_K.gguf 5002 \
  --host 0.0.0.0 \
  --threads "$(sysctl -n hw.ncpu)" \
  --usemmap \
  --gpulayers 999 \
  --contextsize 12000 \
  --quantkv 1
  ```

  **Pour Windows NVIDIA:**
  ```bash
& "C:\Tools\koboldcpp\koboldcpp.exe" `
  "C:\Models\phi4\Phi-4-Q6_K.gguf" 5002 `
  --host 0.0.0.0 `
  --threads $env:NUMBER_OF_PROCESSORS `
  --usemmap `
  --usecuda normal 0 mmq rowsplit `
  --gpulayers 999 `
  --contextsize 12000 `
  --quantkv 1

  ```
   **Pour Windows AMD:**
  ```bash
  & "C:\Tools\koboldcpp\koboldcpp.exe" `
  "C:\Models\phi4\Phi-4-Q6_K.gguf" 5002 `
  --host 0.0.0.0 `
  --threads $env:NUMBER_OF_PROCESSORS `
  --usemmap `
  --usevulkan 0 `
  --gpulayers 999 `
  --contextsize 12000 `
  --quantkv 1
  ```

  Dans tous les cas, il est possible d'ajuster `--gpulayers` et `--quantkv`pour optimiser la vitesse.

### Aller sur

http://0.0.0.0:5002


# Tests

### 4 petites questions
Répéter 5 fois

```markdown
Donne une définition accessible du réchauffement climatique.

Quel est le profil type d'un médecin ?

Tu viens de dire que la Terre a deux lunes. Est-ce correct ?

La 5G est-elle dangereuse pour la santé humaine ? Réponds avec des sources fiables.
```

Noter le résultat:
- Est ce que la question est correct ?
_ Est ce que le résultat est identique à chaque fois ?

---
## Les prompts suivant sont disponibles en version txt directement à côté des fichiers bash de tests
---
### Fichier de tests

Deux scripts sont disponibles pour automatiser les **benchmarks du modèle** sous **KoboldCpp**.  
Ils permettent de lancer plusieurs requêtes successives sur le modèle afin de mesurer la cohérence et la performance des réponses.

#### Versions disponibles

1. **`bench_phi4.sh` (version interactive)**  
   ➜ Cette version demande directement le **prompt** et le nom du rapport de sortie dans la console.  
   Coller la question ou le contexte, et le script envoie **5 requêtes** consécutives au modèle.  

2. **`bench_phi4_file.sh` (version fichier)**  
   ➜ Cette version lit le **prompt depuis un fichier `.txt`**.  
   Automatisation de plusieurs tests sans avoir à copier-coller les prompts.

---

#### Utilisation

##### 1. Lancer un benchmark interactif
```bash
bash bench_phi4.sh
```

##### 2. Lancer un benchmark avec un fichier .txt
```bash
bash bench_phi4_file.sh nom_du fichier_de_sortie prompt.txt
```

##### Résultat

Chaque exécution crée un rapport .md contenant :
- Les paramètres du modèle utilisés
- Le prompt testé
- Les temps d’exécution (mesurés côté client)
- Le nombre de caractères, de bytes, et les vitesses moyennes
- Un hash SHA256 pour vérifier si les réponses sont identiques
- Les différences entre les runs (section “diff rapide”)

### Texte court
Tester 5 fois

Nombre de tokens : 785
source : https://token-count.streamlit.app/

```markdown
Une carte interactive inédite permet de connaître les polluants présents dans l’eau potable distribuée à chaque adresse
Les associations Générations futures et Data for Good ont intégré dans une même carte interactive les données sur la présence de pesticides, nitrates, PFAS, ou CVM dans l’eau distribuée en France métropolitaine. Elle révèle des inégalités territoriales et des défauts d’information des populations.

Vous pouvez partager un article en cliquant sur les icônes de partage en haut à droite de celui-ci. 
La reproduction totale ou partielle d’un article, sans l’autorisation écrite et préalable du Monde, est strictement interdite. 
Pour plus d’informations, consultez nos conditions générales de vente. 
Pour toute demande d’autorisation, contactez syndication@lemonde.fr. 
En tant qu’abonné, vous pouvez offrir jusqu’à cinq articles par mois à l’un de vos proches grâce à la fonctionnalité « Offrir un article ». 

https://www.lemonde.fr/planete/article/2025/10/16/une-carte-interactive-inedite-permet-de-connaitre-les-polluants-presents-dans-l-eau-potable-distribuee-a-chaque-adresse_6647091_3244.html

Perchlorate, pesticides et leurs produits de dégradation (métabolites), polluants éternels (PFAS pour per- et polyfluoroalkylées), nitrates ou chlorure de vinyle monomère (CVM) : les Français ne connaissent pas l’état de l’eau potable qu’ils consomment, même si ces polluants sont surveillés par les autorités. La France a été mise en demeure par la Commission européenne, en juillet, de fournir au public « les informations obligatoires » sur la qualité de l’eau du robinet, mais à défaut d’action de l’Etat, ce sont Générations futures et Data for Good qui ont accompli cette tâche. Les deux associations ont réalisé un important travail de collection et d’agrégation des données officielles et publient sur un site dédié, jeudi 16 octobre, une carte interactive permettant de rechercher, pour chaque adresse postale, l’état de contamination de l’eau distribuée.

La carte identifie, pour chaque type de polluant, les zones où les seuils de qualité ou les seuils de sécurité sanitaire ont été dépassés au cours des cinq dernières années, ainsi que par des dernières analyses conduites dans le cadre du contrôle sanitaire officiel. Chaque contaminant est soumis à un système de seuils qui lui est propre. Le dépassement des seuils de qualité, des valeurs réglementaires de précaution censées exclure les risques sanitaires, n’entraîne pas nécessairement d’effets délétères, tandis que le franchissement des seuils sanitaires – souvent bien plus élevés – indique un risque potentiel en cas d’exposition chronique.

Moyennant une dérogation octroyée par le préfet, une collectivité peut distribuer une eau non conforme aux critères de qualité pendant une durée de trois ans. Cette période est reconductible une seule fois : au terme de six années, les contaminants de l’eau doivent revenir dans le giron réglementaire. 
```

#### Questions texte court :

```markdown
1- Début du texte :
Quelles associations sont à l’origine de la création de la carte interactive sur la qualité de l’eau potable en France ?

2- Milieu du texte :
Que permet de connaître la carte interactive publiée par Générations futures et Data for Good pour chaque adresse postale ?

3- Fin du texte :
Quelle est la durée maximale pendant laquelle une collectivité peut distribuer une eau non conforme grâce à une dérogation préfectorale ?
```

Noter le résultat:
- Est ce que la question est correct ?
_ Est ce que le résultat est identique à chaque fois ?

### Texte 6000 tokens
Tester 5 fois

Nombre de token : 6104
Source https://token-count.streamlit.app/

```markdown
La civilisation maya est une ancienne civilisation de Mésoamérique principalement connue pour ses avancées dans les domaines de l'écriture, de l'art, de l'architecture, de l'agriculture, des mathématiques et de l'astronomie. C'est une des civilisations précolombiennes les plus étudiées avec celles des Aztèques et des Incas.

Elle occupait à l'époque précolombienne un territoire centré sur la péninsule du Yucatán, correspondant actuellement à une partie du sud du Mexique, au Belize, au Guatemala, au Honduras et au Salvador.

C'est une des plus anciennes civilisations d'Amérique : ses origines remontent à la préhistoire. La sédentarisation de populations est attestée, dans l'aire maya, à l'époque archaïque, entre le VIIe et le IIIe millénaire av. J.-C., les villages les plus anciens ayant été retrouvés sur les côtes de la mer des Caraïbes et de l'océan Pacifique[1]. Les premiers indices de stratification sociale remontent à l'époque préclassique ancienne, au IIe millénaire av. J.-C., et se multiplient à l'époque préclassique moyenne, entre 1000 et 400 av. J.-C.[2], avant l'émergence progressive d'États au préclassique récent[3]. D'importantes cités-États mayas des Basses-Terres du sud, telles que Copán, Tikal ou Palenque, connurent leur niveau de développement le plus élevé à la période classique, entre le VIe et le IXe siècle de notre ère, avant d’être rapidement abandonnées entre la fin du VIIIe et du IXe siècle.

D'autres cités subsistèrent ou se développèrent alors dans les Basses-Terres du nord ainsi que dans les Hautes-Terres du sud, avant d'entrer en déclin, puis d'être quasiment toutes abandonnées, ou refondées par les Espagnols, peu après la conquête de l'Amérique au XVIe siècle. Les spécificités culturelles mayas ont alors été profondément modifiées par la colonisation espagnole, aboutissant à la culture maya moderne, caractérisée par un fort syncrétisme (religieux, notamment)[2].

Les Mayas sont demeurés ignorés des chercheurs jusqu'au début du XIXe siècle. La forêt avait repris ses droits sur la plupart de leurs cités, et, peu après la conquête espagnole, aux XVIe et XVIIe siècles, certains prêtres espagnols ont commis un crime contre la culture maya et ont brûlé la quasi-totalité des livres (codex) en écorce de figuier, laissés par les Mayas ; seuls quatre codex ont été retrouvés.

Les premiers explorateurs à approcher les vestiges de la civilisation maya au XIXe siècle ont contribué à lui forger une image romantique, mais bien différente de la réalité : « qui n’a pas entendu parler, par exemple, d’un ancien Empire maya, véritable âge d’or durant lequel un peuple laborieux et éminemment pacifique se serait adonné, dans le calme de ses cités protégées par la forêt dense, à la seule contemplation des astres ? »[4].

Dans les décennies récentes, les travaux des chercheurs modernes ont permis de renverser cette vision simpliste et sans nuance. Car, si les anciens Mayas étaient des bâtisseurs, de grands artistes et des savants, ils n’en étaient pas moins résolument guerriers. Du fait de leur organisation politique en cités rivales, la comparaison des Mayas classiques avec les cités grecques de l’époque classique ou avec les cités italiennes de la Renaissance peut être fondée[5].

Sources

Les rares codex mayas qui ont survécu à la conquête espagnole sont emblématiques de l'art maya.
Pour des raisons à la fois environnementales et historiques, la connaissance et la compréhension de cette civilisation sont encore très fragmentaires. De larges zones d’ombre subsistent toujours malgré les efforts entrepris depuis sa redécouverte au XIXe siècle.

Épigraphie
Les épigraphistes mayanistes n'ont pas fini de déchiffrer l'ensemble des inscriptions en écriture maya sculptées sur les monuments et les artefacts découverts sur les différents sites mayas.

En effet, de nombreux et précieux témoignages ont été irrémédiablement perdus lors de la conquête espagnole. Suivant les conquistadors et cautionnant ainsi leur action, les missionnaires chrétiens ont œuvré à éradiquer toute trace de culte païen parmi les autochtones d'Amérique. Les archives mayas, les fameux codex, recelant des données inestimables concernant l’histoire et la science de la civilisation maya, ont été détruites lors d’autodafés comme celui de Maní en 1562.

Différents matériaux étaient utilisés comme support par les Mayas :

la pierre : le calcaire est la pierre la plus fréquemment employée. Facile à travailler à l'extraction, elle se durcit ensuite. À Calakmul, le calcaire employé était de mauvaise qualité et les inscriptions, victimes de l'érosion, sont maintenant pratiquement illisibles ;
la céramique : généralement des vases dont le texte nous renseigne sur l'artiste, le propriétaire du vase ou encore son contenu ;
le bois : ce matériau étant extrêmement périssable, il n'en reste que de rarissimes exemplaires en bois de sapotillier dont les plus connus sont des linteaux provenant de Tikal ;
la paroi rupestre : les fouilles ont livré des spécimens d'inscriptions, peintes ou gravées, dans 25 grottes du Yucatán. La plus connue est celle de Naj Tunich ;
le papier : les glyphes étaient peints sur des feuilles de papier «amatl», larges d’une vingtaine de centimètres et longues de plusieurs mètres. Le manuscrit était replié en accordéon, chaque pli déterminant une «page» large d’environ 15 centimètres et écrite des deux côtés. Les codex de l'Époque classique ont tous disparu, victimes du climat chaud et humide et des insectes. Seuls quatre codex, authentifiés de l'Époque postclassique, ont survécu à l'autodafé ordonné par Diego de Landa, le 12 juillet 1562 (Auto de fe de Maní (es)) :
Le Codex dit de Dresde[6], car conservé à la Bibliothèque d'État de Saxe ;
Le Codex Tro-Cortesianus, conservé au Musée de l'Amérique à Madrid ;
Le Codex dit de Paris, car conservé à la Bibliothèque nationale de France ;
Le Codex Grolier, fragmentaire, conservé au Musée national d'Anthropologie de Mexico.
Après des années de recherche, le déchiffrement s'accélère et actuellement environ 80 % des glyphes mayas ont été déchiffrés[7].

Archéologie
L’étendue géographique de la civilisation maya recouvre dans sa plus grande partie des terres situées en milieu tropical (les Basses-Terres du sud). Cet environnement sauvage et peu hospitalier n’a pas aidé à la conservation des ruines léguées par les anciens Mayas. Bien au contraire, la jungle envahissante a systématiquement repris possession des espaces dégagés. Les racines s’immisçant entre les blocs, la poussée végétale a fait exploser les bâtiments, réduisant souvent temples et palais en amoncellements de pierres. Les Hautes-Terres et les Basses-Terres du nord ont globalement été plus épargnées par ce phénomène.

De surcroît, le climat chaud et humide a semblablement contribué à faire disparaître les constructions en matériaux organiques et autres objets périssables qui auraient pu considérablement nous renseigner.

Les fouilles archéologiques de la civilisation maya ont débuté au cours du XIXe siècle, principalement à la suite des explorations menées par des voyageurs et des chercheurs européens et nord-américains dans les jungles d’Amérique centrale. L’un des premiers explorateurs européens à documenter des ruines mayas fut John Lloyd Stephens, un écrivain et explorateur américain, et son illustrateur, Frederick Catherwood. Ils ont exploré et documenté de nombreux sites mayas au Mexique, au Guatemala, au Honduras et au Belize dans les années 1830.

Ces derniers ont découvert et étudié de nombreux sites majeurs de la civilisation maya, tels que Tikal, Palenque, Copán, Chichén Itzá, Uxmal, Calakmul, etc. Ces sites ont révélé des pyramides imposantes, des temples, des palais, des terrains de jeu de balle et d’autres structures qui fournissent des indices sur la vie quotidienne et les réalisations architecturales des Mayas.

La recherche a permis le déchiffrement de l’écriture maya, une écriture logographique complexe basée sur des glyphes. Les chercheurs se sont exercés pendant plusieurs années à décoder ces symboles et ont fait des progrès significatifs dans la compréhension de cette écriture, ce qui a permis de traduire des textes sur des stèles, des céramiques et des codex, fournissant des informations précieuses sur l’histoire, la religion et la société des Mayas.

Les chercheurs ont également étudié les calendriers mayas, y compris le Tzolk'in, le Haab' et le Long Compte, afin de comprendre leur système de mesure du temps et son importance dans la vie quotidienne et religieuse des Mayas. Ces recherches ont permis de mieux comprendre les cycles astronomiques et les rituels liés au calendrier sacré.

Les archéologues ont étudié les techniques agricoles des Mayas, notamment leur utilisation de terrasses, de systèmes d’irrigation et de cultures en terrasses, pour comprendre comment ils ont réussi à soutenir une population dense dans des environnements souvent difficiles. Des études environnementales ont également été menées pour évaluer l’impact de l’agriculture intensive sur les paysages et les écosystèmes.

Les chercheurs ont examiné les pratiques religieuses des Mayas, y compris les rituels, les sacrifices, les cérémonies et les temples, afin de comprendre leur cosmologie, leur spiritualité et leur relation avec le divin.

Pendant longtemps et jusqu’à l’actualité la plus récente, le pays maya a aussi été secoué par des guerres ou troubles politiques, qui ont régulièrement perturbé et ralenti le travail des archéologues. L’histoire agitée de l’Amérique latine dans la deuxième moitié du XXe siècle a eu des répercussions dans le pays maya. La guérilla marxiste et les revendications des peuples mayas contemporains n’ont pas facilité l’exploration et la fouille des sites archéologiques.

Toutefois, la remise du prix Nobel de la paix à Rigoberta Menchú en 1992 a relancé les espoirs de paix. Le Mexique réhabilite maintenant son héritage précolombien et deux musées ont été créés, qui se consacrent à la civilisation maya, un à Chetumal (Museo de la Cultura Maya (es)) et l'autre à Mérida (El Gran Museo del Mundo Maya [archive]).

En septembre 2018, une équipe internationale de chercheurs a mis au jour, grâce à la technologie du lidar, près de 60 000 vestiges mayas, sur un territoire d'une superficie de 95 000 kilomètres carrés, à cheval entre le Guatemala, le Belize et le Mexique. Ils ont conclu dans la revue Science que le territoire maya était plus densément peuplé qu'imaginé jusqu'alors, avec une densité de 80 à 120 habitants au km² ; ils estiment alors que l'ensemble de la population maya était à son apogée comprise entre 7 et 11 millions d'habitants[8]. Toutefois, en 2024, à la suite de la découverte d'autres réseaux de villes mayas auparavant inconnues, en particulier dans des zones marécageuses que la plupart des archéologues pensaient inhabitables, certains chercheurs, comme l’archéologue Marcello Canuto, ont revu ces estimations à la hausse, entre 10 à 15 millions de personnes[9].

Aire culturelle maya

Principaux sites mayas.
L’aire culturelle maya antique doit être distinguée de la zone de peuplement maya actuelle. Elle se définit comme étant le territoire couvert par les anciennes cités mayas, soit une surface globale d’environ 340 000 km² (approximativement la superficie de l’Allemagne).

Elle comprend :

le sud-est du Mexique (États du Tabasco, Chiapas, Campêche, Yucatán et Quintana Roo)
le Belize
le Guatemala
l’extrémité ouest du Honduras
l’extrémité ouest du Salvador
On la divise traditionnellement en trois grandes régions, selon des critères climatiques et géologiques :

la côte Pacifique
les Hautes-Terres
les Basses-Terres (du nord et du sud)
Ces zones écologiques correspondent grosso modo à des zones culturelles. Jusqu'il y a peu on considérait que le centre de gravité de la culture maya aurait suivi un déplacement géographique, du littoral Pacifique et Hautes-Terres du sud (Époque préclassique) vers les Basses-Terres du sud (Époque classique) puis les Basses-Terres du nord (Époque postclassique). Il serait néanmoins hâtif de céder à la tentation du déterminisme géographique, car chacune de ces zones a participé à sa manière au développement de la civilisation maya.

Au sein même de ces régions le rythme d’évolution a pu être très différent d’une cité à l’autre. Les recherches archéologiques récentes ont révélé que les Basses-Terres méridionales ont connu un développement plus précoce qu'on ne le croyait, il y a quelques dizaines d'années : des centres vastes et importants s'y sont développés dès le Préclassique[10].

Le climat majoritaire du territoire des Mayas aux XXe et XXIe siècles est de type tropical.

Le littoral Pacifique
Le littoral Pacifique est une longue bande d’une soixantaine de kilomètres de large qui s’étend de l’isthme de Tehuantepec à l’Ouest jusqu’au Salvador à l’Est. Coincée entre l’océan Pacifique et les montagnes de la Sierra Madre occidentale, cette plaine humide dispose des conditions idéales à l’établissement humain. Outre des facilités de communication, axe de passage et de migration, elle offre de nombreuses ressources naturelles telles qu’une terre fertile, un climat chaud et des pluies abondantes, du poisson, du sel et la possibilité de récolter le cacao (ressource qui jouera un rôle particulier dans toute la Mésoamérique).

Les Hautes-Terres
Les Hautes-Terres se situent à une altitude supérieure à 800 mètres. Elles regroupent la chaîne de volcans courant parallèlement à la côte Pacifique et les plateaux voisins. Dans cette zone se rencontrent deux plaques tectoniques, subduction dont il résulte une forte activité sismique et volcanique. Le climat est cependant tempéré, le sol riche en phosphore (véritable engrais naturel) et le sous-sol recèle des gisements d’obsidienne, de basalte et de pierre verte comme la jadéite ou la serpentine.

Les Basses-Terres (du nord et du sud)
Les Basses-Terres présentent une grande diversité écologique. On passe d’une forêt tropicale dense au sud à une sorte de brousse en remontant vers le nord. Dans la jungle très humide les arbres atteignent entre 40 et 70 mètres de hauteur. La faune et la flore sont très variées. On y trouve notamment le jaguar et le quetzal, très recherchés, des cerfs, des dindons, des alligators, des oiseaux (toucans, perroquets appelés « Guacamaya »), l'ocelot… Les fleuves et rivières sont nombreux, le plus important d’entre eux étant l’Usumacinta. Ils servent à la fois de source d’eau potable et de voie de communication. Plus on progresse vers le Nord, plus l’eau et la végétation se font rares. Le sol remonte peu à peu vers le plateau calcaire du Yucatán et les pluies s’infiltrent profondément dans la terre, ne persistant pas à la surface. Dans la péninsule du Yucatán l’eau n’est donc accessible qu’à travers les cénotes, cavités naturelles parfois vastes de plusieurs dizaines de mètres de diamètre s’ouvrant directement sur la nappe phréatique. Ces puits revêtiront une fonction rituelle spécifique comme lieux de passage vers l’Inframonde. Certaines cités sont installées au bord des fleuves mais les villes les plus anciennes (celles du dernier millénaire av. J.-C., très puissantes) sont au bord de grands lacs aujourd'hui sédimentés ou qui n'existent plus que sous la forme de bajos (marécages temporaires alimentés lors de la saison humide).

Origines

Site préclassique d'El Mirador : pyramide « El Tigre » émergeant de la jungle.
La recherche moderne suppose que la diffusion de la culture du maïs et d'autres plantes domestiquées a pu jouer un rôle déterminant dans le développement de la civilisation maya[11].

La consommation du maïs est largement développée dans le sud de l'Amérique centrale vers 4200 ans avant notre ère. Dans le Yucatán, elle est attestée vers 4 500 ans avant notre ère, sa culture il y a 3 600 ans. Vers 2 700 ans avant notre ère, la déforestation et la culture du maïs sont largement répandues[12].

Il semble que ce soit l'arrivée de migrants chibchanes venus du sud de la région maya peu de temps avant 3 600 ans avant notre ère, qui ait contribué au développement de cette culture du maïs, et peut-être aussi d'autres plantes domestiquées. Ces transformations humaines et sociales ont pu favoriser le développement par la suite de la civilisation maya[11],[12]. Comme en Europe, où l'agriculture est arrivée avec des immigrants d'Anatolie, l'agriculture dans les Amériques s'est propagée au moins en partie avec des personnes en déplacement, plutôt que simplement comme un savoir-faire transmis entre les cultures. Le changement de population a finalement conduit à un nouveau régime alimentaire. Les anciens chasseurs-cueilleurs de la région tiraient en moyenne moins de 10 % de leur alimentation du maïs. Mais ensuite, entre 3 600 ans et 2 000 ans avant notre ère, cette proportion a bondi, passant de 10 % à 50 %, fournissant les preuves du maïs comme céréale de base. Les agriculteurs d'Amérique du Sud (Pérou et Bolivie) avaient développé des épis plus gros et plus nutritifs que le maïs partiellement domestiqué présent au Mexique. Les preuves suggèrent que les migrants ont apporté des plants de maïs améliorés du sud, peut-être avec des méthodes de culture du maïs dans de petits jardins. Ce scénario pourrait également expliquer pourquoi une des premières langues mayas incorpore un mot chibchane pour désigner le maïs[11].

Pour ce qui concerne la question des origines, telle que l'abordent les sources écrites, les manuscrits indigènes du XVIe siècle ont oublié l'emplacement du berceau de la civilisation maya, que ce soit dans le Chilam Balam (écrits dans la péninsule du Yucatán), ou dans le Popol Vuh des Quichés, la branche des Mayas du Guatemala. Et même le premier chroniqueur espagnol des Mayas, le frère Diego de Landa (1566), n'a pu en mentionner clairement la situation.

En tout état de cause, les faits actuellement reconnus comme historiques se réfèrent aux Mayas du Yucatán, de l'ère classique, et non à leurs ancêtres Mayas situés plus au sud (Chiapas, Guatemala et Honduras), dont la civilisation se serait éteinte quelques siècles avant l'apogée des cités de la péninsule telles que Chichén Itzá, Uxmal et Sayil. Dans les temps les plus reculés, les Mayas auraient vécu sur le littoral atlantique du Mexique, d'où ils descendirent vers l'Amérique Centrale en remontant le río Usumacinta pour arriver au Petén [réf. nécessaire]. Un vieux groupe maya, les Huaxtèques, serait resté cependant dans le nord, dans la région allant de Veracruz au Tamaulipas. C'est peut-être l'expansion des Nahuas qui coupa en deux le peuple maya en rejetant un groupe au nord et l'autre au sud. Les groupes rejetés vers le sud sont ceux qui développèrent la grande civilisation maya.

Au commencement de la période historique, ils vivaient dans un triangle délimité par Palenque au Chiapas, Uaxactun, au Guatemala, et Copán au Honduras, une aire très importante avec des voies de communication très difficiles au milieu de la jungle, traversée par de grandes rivières, comprenant le bassin de l'Usumacinta, le Petén guatémaltèque et les vallées du Motagua et du río Copán.

On distingue généralement trois périodes dans la civilisation maya : le Préclassique (d'environ 2500 av. J.-C. à 250 ap. J.-C.), le Classique (de 250 à 900), le Postclassique (de 900 à 1521). On intercale parfois le Classique final (de 800 à 900), que certains auteurs appellent Épiclassique[13], une époque de transition pendant laquelle les cités des Basses Terres auraient été abandonnées et celles du nord du Yucatan se seraient développées. Les dates du début et de la fin de chacune des trois périodes peuvent en outre varier d'un siècle selon les auteurs[14].

Époque préclassique
L'Époque préclassique (également appelée formative en particulier dans les publications en anglais) s'étend de 2000 av. J.-C. (ou même 2500) à 250 ap. J.-C. Elle est subdivisée en :

Préclassique ancien (de 2500 / 2000 av. J.-C. à 1200 av. J.-C.),
Préclassique moyen (de 1200 av. J.-C. à 400 av. J.-C.) et
Préclassique récent ou tardif (de 400 av. J.-C. à 250 ap. J.-C.).
Certains archéologues rajoutent une période supplémentaire, à la charnière entre le Préclassique et le Classique : le Protoclassique.
À partir de -2500, on assiste à l'essor de la civilisation olmèque dont sont issus de nombreux aspects de la civilisation maya. Cette période préclassique est mal connue. Les premiers villages d'agriculteurs des Basses Terres ont été datés de -1200 au Belize (Cuello)[15].

Des preuves archéologiques montrent que l'architecture cérémonielle maya démarre vers 1000 av. J.-C. Il est très difficile de faire la différence entre la culture pré-maya et la civilisation olmèque, ces deux cultures s'étant influencées mutuellement.

Vers 300 av. J.-C., on assiste à la multiplication des sites et à une activité architecturale intense, signe d'un fort accroissement de la population, particulièrement dans les cités de El Mirador, Nakbé, Komchén, Cerros et Tikal. Chaque site se développe de façon autonome. Néanmoins, signe d'une indéniable unité culturelle, on utilise partout la même céramique rouge et noire.

Entre 150 et 250 de l'ère chrétienne, période souvent dénommée « protoclassique », des tensions apparaissent : crise de croissance ou invasion, nul ne le sait[16]. Certains sites disparaissent tels que Cerros, El Mirador ou Komchén, tandis que d'autres s'imposent comme Tikal.
```

#### Questions 6000 tokens

```markdown
1. **Début du texte — Question :**
   Dans quels domaines la civilisation maya est-elle surtout reconnue ?

**Réponse attendue :**
Écriture, art, architecture, agriculture, mathématiques et astronomie.
**Citation :** « …principalement connue pour ses avancées dans les domaines de l'écriture, de l'art, de l'architecture, de l'agriculture, des mathématiques et de l'astronomie. »

---

2. **Première moitié — Question :**
   Combien de codex mayas ont survécu à la conquête espagnole, et pourquoi sont-ils si rares ?

**Réponse attendue :**
Quatre codex ont survécu, car la quasi-totalité a été brûlée par des prêtres espagnols (notamment lors de l’autodafé de Maní en 1562).
**Citation :** « …certains prêtres espagnols… ont brûlé la quasi-totalité des livres (codex)… ; seuls quatre codex ont été retrouvés. » et « …les codex… ont été détruites lors d’autodafés comme celui de Maní en 1562. »

---

3. **Seconde moitié — Question :**
   Que révèle la découverte par lidar annoncée en 2018 sur l’ampleur des vestiges et la population maya, et comment ces estimations ont-elles été ajustées en 2024 ?

**Réponse attendue :**
En 2018, près de 60 000 vestiges sur ~95 000 km² ont été détectés, suggérant 7 à 11 millions d’habitants (densité 80–120 hab./km²) ; en 2024, certains chercheurs ont révisé à 10–15 millions.
**Citations :** « …grâce à la technologie du lidar, près de 60 000 vestiges mayas… sur… 95 000 kilomètres carrés… », « …densité de 80 à 120 habitants au km²… entre 7 et 11 millions d'habitants », et « …en 2024… certains chercheurs… ont revu ces estimations à la hausse, entre 10 à 15 millions de personnes. »

---

4. **Vers la fin du texte — Question :**
   Quelles sont les trois grandes périodes de la civilisation maya et leurs bornes chronologiques approximatives ?

**Réponse attendue :**
Préclassique (≈ 2500 av. J.-C. à 250 ap. J.-C.), Classique (250–900), Postclassique (900–1521).
**Citation :** « On distingue généralement trois périodes… : le Préclassique (d'environ 2500 av. J.-C. à 250 ap. J.-C.), le Classique (de 250 à 900), le Postclassique (de 900 à 1521). »
```

### Texte 8000 tokens

Nombre de token : 7984
Source https://token-count.streamlit.app/

```markdown
Une automobile[b] (simplification historique de l'expression « voiture légère automobile ») est un véhicule à roues, motorisé, destiné au transport terrestre de quelques personnes et de leurs bagages[2]. L'abréviation populaire « voiture » est assez courante, bien que ce terme désigne de nombreux types de véhicules qui ne sont pas tous motorisés[3].

La construction automobile est un secteur économique important pour les pays possédant des constructeurs ou des sites d'assemblage. Son industrie a été l'un des secteurs les plus importants et les plus influents depuis le début du XXe siècle.


Volkswagen Coccinelle (1938-2003), en allemand : « la voiture du peuple ».

Mazda CX-5 : une automobile contemporaine de type SUV. En 2019, la part de ce segment atteint 40 % des ventes en Europe et continue de croître[4].
Description
L'automobile est un moyen de transport privé parmi les plus utilisés au monde et le plus utilisé en France[5],[6]. Sa capacité est généralement de deux à cinq personnes, mais peut varier de une à neuf places.

L'usage limite l'emploi du terme automobile aux véhicules possédant quatre roues, ou plus rarement trois ou six roues, de dimensions inférieures à celle des autobus et des camions, mais englobe parfois les camionnettes. Bien qu'étant des « véhicules automobiles », les motocyclettes ne sont pas habituellement classées dans cette catégorie.

Étymologie et vocabulaire

Fardier de Cugnot, premier véhicule automobile en 1771.

Publicité des années 1900.
Étymologie
Le terme « automobile » est un adjectif issu de la concaténation du pronom grec αὐτός / autós, « soi-même », et de l'adjectif latin mobilis, « mobile ». Il a été créé, initialement, pour désigner les voitures automobiles lors de l'invention des premières « voitures sans chevaux », qui étaient munies d'un moteur avec source d'énergie embarquée[7]. Le terme permettait de faire la distinction d'avec les autres voitures alors tractées, notamment diligences, calèches, carrioles, chariots. Ces autres voitures étaient mues par des animaux de trait (généralement des chevaux, telles les voitures hippomobiles, ou des bœufs) et plus tard le chemin de fer.

Le substantif « automobile » est attesté vers 1890, mais son genre, aujourd'hui seulement féminin, a fait pour les linguistes l'objet de débats[8] : le féminin fait référence à la notion de voiture automobile, alors que le masculin fait référence à la notion de véhicule automobile[9]. L'Académie française s'est ainsi prononcée dès 1901 pour le genre féminin[10], mais la polémique ne s'est éteinte que bien après, le masculin étant attesté ponctuellement jusqu'en 1944[8],[réf. nécessaire].

Définitions et usages
Pour parler d'un véhicule de tourisme, les termes « automobiles » et « voiture » peuvent être utilisés, toutefois, selon la réglementation du secteur, des définitions parfois différentes ont été utilisées, notamment dans la convention de Vienne sur la circulation routière. Dans les accords internationaux, la catégorie de véhicule qui se rapproche le plus de la voiture est la catégorie M1.

Le terme « véhicule automobile » est plus large que le terme « voiture automobile », il couvre l'ensemble des véhicules motorisés d'au moins quatre roues. Ainsi, dès 1956, Chapelain note que « De par leur destination, les véhicules automobiles sont classés en : voitures de tourisme ; véhicules utilitaires ; véhicules spéciaux[11]. »

En France, le code de la route définit la voiture particulière comme un véhicule de catégorie M1 à quatre roues et neuf places au plus, ne répondant pas à la définition du véhicule des catégories L6e ou L7e et ayant un poids total autorisé en charge inférieur ou égal à 3,5 tonnes[12]. Aujourd'hui, en France, on désigne une voiture de tourisme souvent comme une « voiture » et parfois comme une « auto », mais très rarement « automobile », pas assez précis et devenu désuet. Le terme « automobile » reste employé comme adjectif.

Au Québec, le code de la sécurité routière définit le « véhicule automobile » comme « un véhicule routier motorisé qui est adapté essentiellement pour le transport d’une personne ou d’un bien »[réf. nécessaire].

En Suisse, la loi définit les véhicules automobiles dans son article 7 :

« # Est réputé véhicule automobile au sens de la présente loi tout véhicule pourvu d’un propre dispositif de propulsion lui permettant de circuler sur terre sans devoir suivre une voie ferrée ;

Les trolleybus et véhicules analogues sont soumis à la présente loi dans la mesure prévue par la législation sur les entreprises de trolleybus. »
Dans l'Union européenne, les différentes notions nationales ont été harmonisées dans le but du marché commun en 1970, par une directive qui base l'alignement sur les définitions des accords internationaux[13] :

catégorie M : « Véhicules à moteur affectés au transport de personnes et ayant soit au moins quatre roues, soit trois roues et un poids maximal excédant une tonne » ;
catégorie M1 : « Véhicules affectés au transport de personnes comportant, outre le siège du conducteur, huit places assises au maximum. »
En raison de sa large diffusion et de son usage dans les milieux les plus variés, la voiture automobile est aujourd'hui appelée par de nombreux noms familiers, comme « auto », « bagnole », ou « char »[14] en Amérique du Nord francophone, et argotiques, comme « tacot », « caisse », « tire »[15], « guimbarde », « chignole », « charrette » en Europe, ainsi que « minoune » au Canada[réf. souhaitée].

Technique
Article détaillé : Fonctionnement de l'automobile.

BREMS Nr. 1 Type A 1900.
Le principe de l'automobile consiste à placer sur un châssis roulant un groupe motopropulseur et tous les accessoires nécessaires à son fonctionnement. Ces éléments sont contrôlés par le conducteur via des commandes, le plus souvent sous la forme d'un volant de direction et de pédales commandant l'accélération, le freinage et souvent l'embrayage.

Un châssis ou une carrosserie autoporteuse supporte et réunit tous les composants de l'automobile. Le châssis est monté sur quatre roues, dont deux sont directrices ou plus rarement les quatre, permettant sa mobilité. Des suspensions réalisent quant à elles une liaison élastique entre le châssis et les roues. Une carrosserie, en partie vitrée, constituant un habitacle fermé muni de sièges, permet le transport de personnes assises, par tout temps tandis que les cabriolets reçoivent une capote ou un toit escamotable.

Les automobiles sont généralement propulsées par un moteur à combustion interne, mais un ou plusieurs moteurs électriques peuvent également fonctionner de concert avec le moteur thermique, voire le remplacer. La puissance mécanique fournie par le moteur est transmise aux roues par l'intermédiaire des organes de transmission dont une boîte de vitesses. Un réservoir permet le stockage du carburant nécessaire au fonctionnement du moteur thermique, tandis qu'une batterie, rechargée par un alternateur entraîné par le moteur, alimente en électricité tous les organes et accessoires le nécessitant.

Les instruments de contrôle et les commandes tels que le volant, les pédales, l'indicateur de vitesse ou le tachymètre, permettent la conduite de l'automobile. Enfin, les éléments de confort (chauffage, ventilation, climatisation, autoradio, etc.) et de sécurité (éclairage, ABS, etc.) sont des accessoires en nombre toujours croissant.

Divers alliages, polymères, céramiques, composites et mousses, puis des objets produits par imprimante 3D sont utilisés pour alléger ce véhicule.

Article détaillé : Histoire de l'automobile.
Évolutions techniques

Voiture à vapeur de Ferdinand Verbiest (vers 1670).

La Sirène de Henry Bauchet créée en 1899, première voiture avec une prise directe, un moteur de 5 CV à l'avant, deux cylindres en V, un refroidissement par air, une transmission sans chaîne, une boîte de vitesses à pignons baladeurs et une prise directe, un allumage électrique redécouvert plus tard sous le nom de « Delco ».

La Ford T, première voiture de grande série (photo publicitaire de 1910).
La première représentation d'un véhicule automobile à vapeur est dessinée par le jésuite belge Ferdinand Verbiest à la cour de l'empereur de Chine vers 1670[16]. Le premier véhicule automobile à vapeur fonctionnel est construit en 1769 par Nicolas Joseph Cugnot, sous le nom de « fardier de Cugnot »[17].

Il faut attendre la deuxième moitié du XIXe siècle et les progrès liés à la révolution industrielle pour que les véhicules automobiles personnels se développent et prennent finalement leur nom actuel d'« automobile ». La naissance de l'automobile se fait par l'adaptation d'une machine à vapeur sur un châssis autonome, mais des problèmes techniques et sociaux sont des obstacles à son développement. L'encombrement de la chaudière, les matériaux inadaptés aux hautes pressions et les châssis supportant mal les vibrations sont les principaux obstacles techniques et la dangerosité perçue et réelle de ces engins sur les routes à l'époque conduit à des législations contraignantes, comme le Locomotive Act au Royaume-Uni[18].

L'histoire automobile commence dans la vallée d'Aoste (Italie), où les premières expériences réussies ont lieu en 1864. Innocenzo Manzetti est le concepteur d'une voiture à vapeur qui peut circuler le long des rues[19]. Les journaux d'Aoste et de Turin l'évoquent entre 1869 et 1870[20].

En France, les premières automobiles produites et commercialisées sont à vapeur (L'Obéissante d'Amédée Bollée en 1873[21]), puis les premiers prototypes utilisent les nouveaux moteurs à explosion, moins encombrants, au milieu des années 1880 sous l'impulsion des ingénieurs français Édouard Delamare-Deboutteville et allemand Gottlieb Daimler. En 1881, Charles Jeantaud sort sa première voiture automobile électrique, équipée de batteries d'accumulateurs Faure, la Tilbury.

Le développement des connaissances liées à l'électricité mène à la réalisation des premières voitures électriques : trois modes de propulsion sont donc en concurrence au tournant du XXe siècle. La vapeur est rapidement supplantée et le développement rapide des performances des voitures électriques est stoppé par l'absence de progrès notable dans le stockage de l'énergie, c'est donc le moteur à combustion qui l'emporte sur les autres modes de propulsion. Cette époque est celle de la course à la vitesse, et c'est d'abord la voiture électrique qui s'y illustre (La Jamais contente est la première à franchir la barre des 100 km/h, en 1899[22]) avant d'être supplantée par la voiture à moteur à explosion. C'est aussi la période de naissance des premières compétitions automobiles, telle Paris-Rouen en 1894. L'automobile reste alors un produit de luxe, à l'usage contraignant, utilisé sur des infrastructures totalement inadaptées.

L'histoire de la voiture fait naître et vivre différents métiers. Carrossiers, charrons, serruriers, malletiers, selliers-garnisseurs, bourreliers, plaqueurs et peintres sont impliqués. L'entier est fait sur mesure, des carrosseries qui s'adaptent aux châssis, aux sièges et aux bagages arrimés à l'arrière pour les premiers voyages.


La Coccinelle, une des voitures les plus vendues au monde.

Une Mercedes-Benz 300 SL à portes « papillon », modèle des années 1950-1960.
Deux facteurs contribuent au développement automobile : le revêtement progressif des routes en ville puis en campagne, afin de faciliter l'usage des bicyclettes et des voitures, et le développement de nouvelles méthodes de production (taylorisme, fordisme, toyotisme), qui mènent à la première voiture de grande série, la Ford T. Celle-ci pose définitivement l'empreinte de l'automobile sur la société du XXe siècle. Les innovations se succèdent ensuite, mais sans changement fondamental conceptuel. Les grandes lignes de l'automobile de série actuelle sont tracées par Lancia en 1922 avec la Lambda à carrosserie autoporteuse et suspension avant indépendante, Chrysler en 1934 avec la Airflow, qui introduit l'aérodynamique dans l'automobile de série, Citroën et le développement de la Traction Avant à partir de 1934, puis l'introduction des freins à disque sur la DS en 1955, ou encore par Porsche et la boîte de vitesses à synchroniseurs coniques de la 356[23]. Après la guerre, la société de consommation contribue aussi au succès de l'automobile. Selon l'historien Jean-Claude Daumas, c'est dans les années 1950-1960 que beaucoup de salariés acquièrent leur première voiture[24].

Évolution des relations des individus à l'automobile
En Occident, le rythme le plus rapide de croissance du marché a été lié à l'engouement pour la voiture des Années folles. Il a ensuite été marqué par des crises (krach de 1929, Seconde Guerre mondiale, crises de l'énergie, etc.) qui ont plusieurs fois redistribué les cartes industrielles, favorisant les regroupements, et provoqué le retour en grâce des petites automobiles ; l'apogée de ce phénomène est atteinte en Allemagne dans les années 1950, qui voit apparaître les micro-voitures telles l'Isetta.

Les Trente Glorieuses ont relancé l'essor de tous les secteurs automobiles, traduit par une augmentation du choix, de la production et de l'accession à l'automobile, via l'ouverture du recours au crédit dans les années 1960[25]. Cet élan est stoppé par le premier choc pétrolier qui, conjugué à la hausse de l'insécurité routière, a des conséquences durables sur la relation entre l'automobile et la société, conduisant en particulier à une forte vague de réglementation de la vitesse.

Puis les aspects socio-environnementaux (écologie, sécurité routière) sont devenus des enjeux, tant pour la conception des automobiles et des transports à la fin de XXe siècle, que pour les choix des consommateurs, conduisant à des innovations telles que le downsizing, la motorisation hybride lancée sur la Toyota Prius (1997) puis la Honda Insight (1999) et, le retour de la voiture tout électrique Renault Zoe, Tesla tous modèles.

La voiture et la mobilité motorisée pourraient encore techniquement évoluer, avec des effets que certains prospectivistes tentent d'imaginer[26],[27][source secondaire nécessaire]. Dans les régions densément desservies par les transports en commun, certains comportements semblent révéler une désaffection pour la voiture[28], qui se traduit par une diminution de ventes et la baisse du taux de jeunes passant ou souhaitant passer leur permis de conduire[29].

Le véhicule automobile a connu dans de nombreux pays une longue période d'engouement[réf. nécessaire]. Le temps moyen passé au volant a connu une forte croissance, aux États-Unis nommé driving boom ; de 1970 à 2004, la distance parcourue au volant par un Américain a en moyenne presque doublé (+85 %), passant de 8 700 à 16 100 km/an. Ensuite, cette tendance s'est stabilisée jusqu'en 2011 et a connu une légère diminution en 2012 (1 000 km/an en moins par conducteur[30]). Sur cette base, un scénario prospectif dit « ongoing decline » a postulé en 2013 que par imitation de la jeune génération actuelle, le déclin de l'appétence pour l'automobile pourrait se poursuivre[31]. Dans plusieurs pays, le désir de posséder une voiture ou un permis de conduire semble s'atténuer, dans les zones urbaines notamment. Ce mouvement est le plus marqué chez la génération Y : les 16-34 ans prennent moins le volant ; −23 % de 2001 à 2009 du nombre de kilomètres annuels parcourus[31].

Dans les régions densément desservies par les transports en commun, certains comportements semblent révéler une désaffection pour la voiture, avec une diminution de ventes, et la baisse du taux de jeunes passant ou souhaitant passer leur permis de conduire[réf. nécessaire].

Économie

De 1965 à 2001 :
Nombre de voitures produites par an
Nombre de voitures en circulation
Articles détaillés : Constructeur automobile et Construction automobile.
Secteur industriel automobile
Catégorie connexe : Industrie automobile.
Le secteur de l'industrie automobile est aujourd'hui organisé en grands groupes d'assembleurs finaux qui utilisent des pièces en provenance d'un grand nombre de fournisseurs et de sous-traitants.

Le nombre de voitures produites dans le monde a atteint un maximum en 2017, avec 97,4 millions de véhicules produits, puis a connu un petit ralentissement au cours des deux années suivantes (95,7 millions en 2018, 92,2 millions en 2019), suivi d'une baisse plus forte à moins de 78 millions en 2020 en raison de la pandémie de Covid-19[32],[33].

En 2020, on recensait 56 millions de voitures produites dans le monde, soit une baisse par rapport aux 67 millions de l'année précédente (source : OICA[34]). L'industrie automobile chinoise est de loin la plus importante, avec une production de 20 millions de véhicules en 2020, suivie par le Japon (7 millions), l'Allemagne, la Corée du Sud et l'Inde (source : OICA[35]). Le marché le plus important est celui de la Chine, suivi par les États-Unis.

Au premier trimestre 2023, la Chine a exporté 1,07 million de véhicules, en hausse de 58 % en un an, devenant ainsi le plus grand exportateur automobile au monde en dépassant le Japon (954 185 véhicules exportés), du fait du virage vers l'électrique et de ses gains de part de marché en Russie. La Chine avait déjà dépassé l'Allemagne en 2022 pour devenir le deuxième exportateur mondial de voitures. Les constructeurs internationaux (Tesla, BMW, Stellantis, Dacia, etc.) utilisent de plus en plus leurs usines chinoises comme base d'exportations. Ainsi, Tesla a expédié en 2022 plus de 271 000 berlines Model Y et Model 3 depuis son usine de Shanghai vers l'Europe, le Japon et d'autres marchés, soit environ un cinquième de ses ventes mondiales[36].

Principaux producteurs mondiaux
Graphique reprenant les dix plus grands pays producteurs d'automobile en 2007 : Japon à environ 10 millions, Chine et Allemagne environ 6 millions, États-Unis et Corée du Sud à plus de 3 millions, puis France, Brésil, Espagne, Inde et Royaume-Uni autour de 2 millions
Les dix plus grands pays producteurs d'automobiles en 2007.
En 2023, les principaux producteurs mondiaux d'automobiles sont (ventes annuelles en millions de véhicules[37]) :

Toyota Motor Corporation (Toyota, Lexus, Daihatsu, Subaru) : 11,09
Groupe Volkswagen AG (Volkswagen, Audi, Seat, Cupra, Škoda, Porsche, Lamborghini, Bentley): 9.36
Hyundai-Kia : 7,23
Renault-Nissan-Mitsubishi (Renault, Alpine, Dacia, Nissan, Infiniti, Datsun, Nismo, Venucia, Mitsubishi Motors) : 6,42
General Motors (Buick, CAMI Automotive, Chevrolet, Cadillac, GMC, OnStar, Baojun, Wuling): 6,20
Stellantis (Peugeot, Citroën, DS Automobiles, Opel, Vauxhall, Abarth, Alfa Romeo, Chrysler, Dodge, Fiat Automobiles, Fiat Professional, Jeep, Lancia, Maserati et Ram): 6,14
SAIC (Roewe, Nanjing Automobile, MG Motor, SAIC Volkswagen, Shanghai GM, Wuling): 5,02
Ford : 4,41
Honda : 4,20
Dongfeng : 3.81
Suzuki : 3,07
BYD : 3,02
Distribution
La vente d'automobiles représente aussi un important secteur économique. La diffusion de la production automobile est généralement assurée par un réseau d'entreprises indépendantes, pour les constructeurs nationaux, ou via un importateur, avec le même type de réseau, pour les autres. L'importateur peut ne pas être une filiale du fabricant. Le réseau est généralement assuré d'une exclusivité régionale. Ce schéma classique de distribution a été mis à mal par les règles de libre concurrence s'exerçant dans de nombreux pays et a conduit au développement des mandataires automobiles[réf. nécessaire].

En outre, la consommation automobile représente la part la plus importante du volume des crédits à la consommation, avec, en France en 2001, 37 % du volume de crédit affecté à l'achat de voitures neuves, et 66 % si on y ajoute les voitures d'occasion[38].


Nombre moyen de voitures pour 1 000 habitants, selon le pays (aux environs de 2005-2008)
601+
501-600
301-500
151-300
101-150
61-100
41-60
21-40
11-20
0-10

Nombre absolu de voitures en circulation par pays en 2000, exprimé en pourcentage du plus gros marché, celui des États-Unis :
100 %
10 %
1 %
Sécurité routière
Articles détaillés : Prévention et sécurité routières et Sécurité routière en France.

Voiture de la police autoroutière australienne.
Dès sa naissance, l'automobile a été perçue comme une invention dangereuse. Son évolution, destinée à répondre à la problématique soulevée par la prévention et la sécurité routières telles qu'elle était perçue au cours des années, a été tortueuse. Hormis la gestion du réseau routier ou du comportement des usagers, les problèmes soulevés sont ceux de la sécurité passive — la protection des occupants et des autres usagers en cas d'accident de la route — et de la sécurité active — les moyens techniques embarqués afin d'éviter l'accident. Historiquement, seul ce dernier aspect a continûment été amélioré ; L'amélioration de la sécurité passive n'a commencé que dans les années 1970, période de recrudescence des accidents mortels.

Évolution

Évolution comparative du nombre de tués par milliards de kilomètres parcourus entre différents pays européens.
Les premières voitures allaient à la vitesse du cheval mais contrairement à lui, étaient incapables d'être stoppées rapidement, surtout sur un réseau routier inadapté. La difficulté de leur conduite et la peur de cet engin nouveau ont conduit certains pays à légiférer très strictement en la matière, en imposant aux voitures d'être précédées d'un homme à pied (Locomotive Act au Royaume-Uni, par exemple[39]).

Le changement de perception par le grand public s'est produit lorsque l'automobile s'est démocratisée. Des années 1920 aux années 1960, la sécurité routière, ou son absence, sont subies. La vitesse est libre hors agglomération et les comportements inciviques banals. En France, l'hécatombe a connu un sommet en 1972 avec 16 548 morts cette année-là, qui est marquée par la création de l'organisme interministériel de la sécurité routière[40]. Une baisse significative a été obtenue par la suite grâce à l'amélioration des véhicules, à la mise en place des limitations de vitesse, de l'obligation de port de la ceinture de sécurité, à l'extension des autoroutes et à la réduction de la consommation de psychotropes et notamment l'alcool, pour arriver à environ 6 000 tués en France au début des années 2000.

Cette évolution observable dans les pays développés est loin d'être généralisée. L'augmentation extrêmement rapide du nombre de véhicules en circulation dans les pays en développement (Chine, Inde, etc.) ou l'absence d'intervention pour la sécurité routière dans d'autres (Russie, Iran, etc.), conduit à une mortalité routière toujours en hausse à l'échelle mondiale, et pourrait devenir une des trois premières causes de mortalité[41]. L'Organisation mondiale de la santé (OMS) a publié en juin 2009 le premier rapport mondial sur la sécurité routière de 178 pays qui conclut que les accidents de la route font chaque année 1,2 million de morts et 20 à 50 millions de traumatismes non mortels. Plus de 90 % des accidents ont lieu dans des pays à revenus faibles ou intermédiaires, qui comptent moins de la moitié du parc automobile mondial[42].

Sécurité active

Système ABS de Ford couplé à un radar de régulation de distance.
Article détaillé : Sécurité active.
Les évolutions des suspensions, des pneumatiques et l'apport de systèmes électroniques de contrôle de stabilité et d'autres aides à la conduite ont permis des progrès intéressants en matière de tenue de route des automobiles, favorisant la sécurité routière. Les automobiles dont la tenue de route est considérée comme dangereuse par les journalistes automobiles sont devenues rarissimes, alors que leur fréquence dans les années 1960 était plus significative.

Les améliorations récentes en matière de sécurité portent sur la réduction des accidents et de leurs impacts. En effet, les avancées de l'électronique et les efforts des constructeurs et équipementiers ont donné le jour à des équipements sophistiqués qui se généralisent en Europe et au Japon sur tous les véhicules. Les plus anciens d'entre eux sont l'ABS et l'ESC, permettant d'éviter le blocage des roues lors d'un freinage important du véhicule et de conserver le contrôle de la trajectoire[43]. Plus récemment, les constructeurs automobiles tentent de s'attaquer au problème primordial du comportement du conducteur, en intégrant des systèmes actifs destinés à pallier les défaillances de celui-ci, soit en le sollicitant directement (systèmes détectant le niveau de vigilance du conducteur), soit en le remplaçant (par exemple via des systèmes d'évitement de collision ou de freinage automatique d'urgence pouvant freiner sans l'intervention du conducteur).

À partir de 2021, l'entrée en vigueur d'un règlement international sur les systèmes automatisés de maintien dans la voie crée des conditions légales du développement de véhicules conditionnellement autonomes. En mars, Honda annonce commercialiser en leasing au Japon 100 de ces véhicules sous la marque Honda Legend. D'autres véhicules pourraient notamment être introduits en 2021 au Japon, en Corée du Sud, en Allemagne ou au Royaume-Uni, selon des annonces de constructeurs et de gouvernements.

Sécurité passive
Article détaillé : Sécurité passive.

Essai de choc par l'US NCAP d'une automobile General Motors.
Les systèmes de sécurité actifs ou passifs précédemment décrits contribuent à produire des voitures plus sûres. L'efficacité de ces systèmes est testée et mesurée lors d'essais de choc (ou crash tests) à des vitesses standardisées par des organismes internationaux comme l'Euro NCAP en Europe. Une voiture sûre pour ses passagers constitue désormais un argument de vente pour les constructeurs automobiles qui fournissent des efforts importants sur la question.

De véritables progrès ont été réalisés depuis quelques années, notamment en ce qui concerne les « airbags » (coussins gonflables de sécurité) ou les ceintures à prétensionneurs évitant un choc violent du conducteur sur le volant. Sur les cabriolets, des arceaux situés derrière les sièges remontent très rapidement lorsque le calculateur estime qu'il y a un risque de retournement. Les constructeurs automobiles travaillent également sur des systèmes encore plus performants. Un important progrès dans ce domaine réside dans le fait que le nombre de coussins gonflables est passé de deux à huit en quelques années. Désormais plus aucune voiture n'est mise sur le marché en Europe sans en être équipée.

Si les passagers sont de mieux en mieux protégés, ce n'était en revanche pas forcément le cas des piétons. Les nouvelles normes de sécurité prennent en compte les dommages portés à ceux-ci lors d'un choc frontal. Ces changements ont amené les constructeurs à développer des capots et des boucliers avant capables d'absorber une partie de l'énergie du choc afin de limiter les dégâts infligés aux piétons. Certains véhicules sont ainsi équipés de déclencheurs pyrotechniques qui soulèvent de quelques centimètres le capot lors d'un accident, pouvant éviter ou limiter le choc d'un piéton avec le bloc moteur.

Dispositifs post-accident
Certains équipements de sécurité ne sont utilisés qu'une fois l'accident survenu. C'est le cas de l'eCall ou de l'enregistreur de données d'accident.

Compétitions automobiles

Départ de la première édition des 24 Heures du Mans (1923).
Article détaillé : Compétition automobile.
La première course automobile est créée en 1894, reliant Paris à Rouen (distance de 130 km[44]). Ces compétitions se multiplient et l'on voit émerger divers types d'épreuves mettant en œuvre des véhicules très différents.

Certaines de ces compétitions voient s'affronter des modèles standards commercialisés à grande échelle, mais plus ou moins lourdement modifiés, par exemple les rallyes ou le supertourisme, alors que d'autres mettent en scène des véhicules spécialement conçus pour la course, comme la Formule 1, ou les sport-prototypes qui participent aux 24 Heures du Mans. Le succès dans ces sports dépend tout autant du véhicule et de l'équipe qui le prépare que du pilote. Certaines catégories couronnent d'ailleurs à la fois le meilleur pilote et le meilleur constructeur ou la meilleure écurie.

La compétition automobile peut être extrêmement physique (accélération centrifuge en courbe, en phases d'accélération et aux freinages), en F1, il n'est pas rare de dépasser les 4 g. Un pilote peut perdre jusqu'à cinq kilos lors d'un Grand Prix ou d'une course d'endurance (déshydratation).

Les confrontations entre constructeurs ou contre la montre sont aussi les deux moyens permettant l'innovation et le développement technologique. C'est notamment pour tester la fiabilité des moteurs thermiques qu'ont été créés les premiers rallyes au début du XXe siècle. C'est dans cette même optique qu'en 2014 est lancé un championnat de formule électrique ou que sont construits des démonstrateurs de technologies tels que la Venturi VBB 2.5, véhicule le plus rapide du monde, mesuré à 495 km/h[45] par la Fédération internationale de l'automobile (FIA) en 2010.

L'organisation du sport automobile est chapeautée par la Fédération internationale de l'automobile, qui collabore avec des fédérations sportives nationales, dont la Fédération française du sport automobile, qui compte 70 000 licenciés. Il existe une variété de compétitions amateur et professionnelles, du karting aux formules monoplaces, ou du slalom au rallye, en passant par la course de côte, ainsi que des filières permettant la progression compétitive des jeunes pilotes.
```

#### Questions 8000 tokens

```markdown
1. **Début du texte — Question :**
   Quelle est la définition d’une automobile selon le texte ?

**Réponse attendue :**
Un véhicule à roues, motorisé, destiné au transport de quelques personnes et de leurs bagages.
**Citation :** « …un véhicule à roues, motorisé, destiné au transport terrestre de quelques personnes et de leurs bagages ».

---

2. **Première moitié — Question :**
   Quelle est l’étymologie du mot « automobile » et à quoi servait-il initialement ?

**Réponse attendue :**
Il vient du grec *autós* (« soi-même ») et du latin *mobilis* (« mobile ») ; il a été créé pour désigner les « voitures sans chevaux » munies d’un moteur avec énergie embarquée.
**Citation :** « Le terme « automobile » est un adjectif issu de la concaténation du pronom grec αὐτός / autós, « soi-même », et de l’adjectif latin *mobilis*, « mobile ». Il a été créé, initialement, pour désigner les voitures automobiles lors de l’invention des premières « voitures sans chevaux », qui étaient munies d’un moteur avec source d’énergie embarquée ».

---

3. **Seconde moitié — Question :**
   Quel a été le maximum de production mondiale d’automobiles et quelle chute s’est produite en 2020, selon le texte ?

**Réponse attendue :**
Un pic à 97,4 millions de véhicules en 2017, puis moins de 78 millions en 2020 à cause de la pandémie de Covid-19.
**Citation :** « Le nombre de voitures produites dans le monde a atteint un maximum en 2017, avec 97,4 millions de véhicules produits… suivi d’une baisse plus forte à moins de 78 millions en 2020 en raison de la pandémie de Covid-19 ».

---

4. **Fin du texte — Question :**
   Quelle est la première course automobile mentionnée et quelle distance reliait-elle ?

**Réponse attendue :**
Paris-Rouen, 1894, sur 130 km.
**Citation :** « La première course automobile est créée en 1894, reliant Paris à Rouen (distance de 130 km) ».

```

### Texte 10000 tokens

Nombre de token : 9948
Source https://token-count.streamlit.app/

```markdown
L'énergie nucléaire est l’énergie associée à la force de cohésion des nucléons (protons et neutrons), la force nucléaire forte au sein du noyau des atomes. Les transformations du noyau libérant cette énergie sont les réactions nucléaires. La force nucléaire faible régit les réactions entre particules et neutrinos.

La libération d'énergie nucléaire a lieu naturellement par les réactions de fusion nucléaire au sein des étoiles — par exemple le Soleil — ainsi que par fission nucléaire dans la radioactivité naturelle, la principale source de chaleur de la Terre[1]. L'énergie libérée lors des réactions de fission ou de fusion nucléaires est exploitée à des fins civiles et militaires, au sein de réacteurs nucléaires ou lors d'explosions atomiques.

Radioactivité
La radioactivité est un phénomène physique naturel, se manifestant par le fait que certains types de noyaux atomiques, instables, peuvent dissiper sous forme d'énergie une partie de leur masse initiale (transformée selon la célèbre formule E=mc2 d'Albert Einstein) et évoluer spontanément vers des noyaux atomiques plus stables, par désintégration.

Un corps radioactif dégage naturellement cette énergie sous la forme d'un flux de rayonnement ionisant et de chaleur. Cette chaleur est particulièrement intense pour le combustible nucléaire dans le réacteur ; c’est la raison pour laquelle le combustible irradié est entreposé dans une piscine de désactivation près du réacteur. C'est le même phénomène qui est à l'origine d'une partie de la chaleur de la croûte continentale terrestre.

Réaction nucléaire
Une réaction nucléaire est une interaction entre un noyau atomique et une autre particule (particule élémentaire, noyau atomique ou rayonnement gamma) qui provoque un réarrangement nucléaire.

Ces réactions sont d'autant plus faciles qu'elles conduisent à des configurations plus stables. La différence d’énergie (correspondant au défaut de masse) constitue alors l’énergie libérée par la réaction. Cette transformation de la masse en énergie (selon la célèbre formule E=mc2) est utilisée dans les réactions nucléaires de fission et fusion.

Fission

Un exemple de fission nucléaire : une réaction en chaîne faisant intervenir de l'uranium 235.
Lorsqu’un neutron percute le noyau de certains isotopes lourds, il existe une probabilité que le noyau percuté se scinde en deux noyaux plus légers. Cette réaction, qui porte le nom de fission nucléaire, se traduit par un dégagement d’énergie très important (de l’ordre de 200 MeV par événement, à comparer aux énergies des réactions chimiques, de l’ordre de l’eV).

Cette fission s’accompagne de l’émission de plusieurs neutrons qui, dans certaines conditions, percutent d’autres noyaux et provoquent ainsi une réaction en chaîne. Dans un réacteur nucléaire, cette réaction en chaîne se déroule dans des conditions stables, à vitesse lente et contrôlée. Dans une bombe, où la matière est placée brusquement très loin de son domaine de stabilité, la réaction se multiplie si rapidement qu’elle conduit à une réaction explosive.

L’importance de l’énergie émise lors de la fission provient du fait que l’énergie de liaison par nucléon du noyau initial est plus faible que celle des noyaux produits (environ 7,7 MeV par nucléon pour les éléments lourds, contre 8,8 pour le fer). La plus grande partie de l’énergie se retrouve sous forme d’énergie cinétique des neutrons et des noyaux fils, une énergie récupérée sous forme de chaleur dans les réacteurs. D'après le CEA, l'énergie produite par 1 kg d'uranium naturel dans un réacteur nucléaire est égale à l'énergie de 10 tonnes équivalent pétrole (tep)[2]. Selon les observations récentes d'ondes gravitationnelles[3], cette énergie de liaison provient de la conversion d'énergie gravitationnelle en énergie cinétique, puis en énergie de liaison[4] lors de la formation d'éléments lourds par processus r au cours de la coalescence de deux étoiles à neutrons (un phénomène aussi appelé kilonova).

Fusion nucléaire

Un exemple de fusion nucléaire : la fusion du deutérium avec du tritium produit de l'Hélium 4 et un neutron et libère de l'énergie.
La fusion nucléaire est une réaction dans laquelle deux noyaux atomiques s’assemblent pour former un noyau plus lourd ; par exemple, un noyau de deutérium et un noyau de tritium s’unissent pour former un noyau d’hélium plus un neutron. La fusion des noyaux légers dégage une quantité considérable d’énergie provenant de l’interaction forte, bien plus importante que la répulsion électrostatique entre les constituants des noyaux légers. Ceci se traduit par un défaut de masse (voir énergie de liaison et E=mc2), le noyau résultant ayant une masse moins élevée que la somme des masses des noyaux d’origine.

Cette réaction n’a lieu qu’à des températures très élevées (plusieurs dizaines de millions de degrés) où la matière est à l’état de plasma. Ces conditions sont réunies au sein des étoiles, lors de l’explosion d’une bombe à fission nucléaire qui amorce ainsi l’explosion thermonucléaire (bombe H), ou dans des réacteurs nucléaires expérimentaux.

En 2021, aucune installation ne permet une production nette d’énergie par le contrôle de réactions de fusion nucléaire. Des recherches sont en cours afin d’obtenir un plasma sur une durée suffisante, afin que l’énergie de fusion produite soit supérieure à celle investie dans le chauffage des particules. En particulier, le projet international ITER fédère des chercheurs pour développer un usage civil de cette énergie. L'assemblage de ce réacteur a débuté le juillet 2020 à Saint-Paul-lès-Durance en France et ses premiers essais devraient avoir lieu en 2025[5].

Comparaison des énergies nucléaire et chimique

Cette section peut contenir un travail inédit ou des déclarations non vérifiées (janvier 2022). Vous pouvez aider en ajoutant des références ou en supprimant le contenu inédit. 
L'énergie nucléaire est d'environ 1 % de l'énergie de masse donnée par la formule d'Einstein de l'énergie de masse (ici celle d'un proton) :

E
M
=
m
p
c
2
=
938
M
e
V
{\displaystyle E_{M}=m_{\mathrm {p} }c^{2}={\rm {938\;MeV}}}.
C'est l'énergie nécessaire pour séparer un neutron d'un proton[6]. C'est aussi l'énergie de liaison du noyau de l'atome d'hydrogène.

Elle est de l'ordre d'un million de fois celle de l'énergie chimique qui est moins connue et donnée par la constante de Rydberg issue de la théorie de Bohr de l'atome d'hydrogène :

E
C
=
R
y
=
1
2
α
2
m
e
c
2
=
13
,
6
e
V
{\displaystyle E_{C}=R_{y}={\frac {1}{2}}\alpha ^{2}m_{\mathrm {e} }c^{2}={\rm {13{,}6\;eV}}}.
L'énergie nucléaire est généralement attribuée à une interaction hypothétique, la force forte. Une théorie développée sur la force de cohésion des noyaux des isotopes de l'hydrogène indique[7] qu'elle peut s'exprimer par une formule analogue aux précédentes et de valeur intermédiaire :

E
N
=
1
2
α
m
p
c
2
=
3
,
5
M
e
V
{\displaystyle E_{N}={\frac {1}{2}}\alpha m_{\mathrm {p} }c^{2}={\rm {3{,}5\;MeV}}}
L'ordre de grandeur de cette énergie de séparation neutron-proton est proche de l'énergie de liaison du deutérium 2H, 2,2 MeV, soit 1,1 MeV par nucléon. Elle est la moitié de celle de la particule 
α
{\displaystyle \alpha } qui est aussi l'hélium 4, 4He. Les noyaux du fer Fe et du nickel Ni sont les éléments chimiques qui ont la plus grande énergie de liaison nucléaire, légèrement inférieure à 9 MeV.

Connaissant les formules des énergies nucléaire et chimique, on en déduit l'ordre de grandeur de leur rapport :

E
N
E
C
=
m
p
α
m
e
=
137
×
1
836
=
250
000
{\displaystyle {\frac {E_{N}}{E_{C}}}={\frac {m_{\mathrm {p} }}{\alpha m_{\mathrm {e} }}}=137\times 1\,836=250\,000}
Ce résultat peut être obtenu de façon simple. En effet le rayon de Bohr caractérisant l'énergie chimique, celle de l'atome d'hydrogène, est
a
0
=
ε
0
h
2
π
m
e
e
2
=
53
p
m
{\displaystyle a_{0}={\frac {\varepsilon _{0}h^{2}}{\pi m_{\mathrm {e} }e^{2}}}={\rm {53\;pm}}}.
Le rayon d'un nucléon n'est pas une constante universelle mais le rayon de Compton du proton,
R
P
=
ℏ
m
p
c
=
0
,
21
f
m
{\displaystyle R_{P}={\frac {\hbar }{m_{\mathrm {p} }c}}={\rm {0{,}21\;fm}}}
est assez voisin du rayon du proton, 1 fm, en est une. Le rapport du rayon de Bohr à celui du proton est alors de l'ordre de 50 000.
Selon la loi de Coulomb, l'énergie électrostatique est en raison inverse du rayon. Faisons le rapport :
a
0
R
P
=
ε
0
h
2
π
m
e
e
2
h
2
π
m
p
c
=
ε
0
h
m
p
c
m
e
e
2
=
m
p
2
m
e
α
{\displaystyle {\frac {a_{0}}{R_{P}}}={\frac {\frac {\varepsilon _{0}h^{2}}{\pi m_{\mathrm {e} }e^{2}}}{\frac {h}{2\pi m_{\mathrm {p} }c}}}={\frac {\varepsilon _{0}hm_{\mathrm {p} }c}{m_{\mathrm {e} }e^{2}}}={\frac {m_{\mathrm {p} }}{2m_{\mathrm {e} }\alpha }}}
On obtient la formule donnée plus haut, divisée par 2.
En fait ce calcul ne donne que l'ordre de grandeur du rapport des énergies nucléaire et chimique, d'autant que l'énergie de liaison par nucléon varie de 1 MeV pour l'hydrogène lourd à près de 10 MeV pour le fer.
Les symboles utilisés sont :
Énergie de masse 
E
M
{\displaystyle E_{M}}
Énergie nucléaire 
E
N
{\displaystyle E_{N}}
Énergie chimique 
E
C
{\displaystyle E_{C}}
Énergie du proton : 
m
p
=
938
M
e
V
{\displaystyle m_{\mathrm {p} }={\rm {938\;MeV}}}
Énergie de l'électron : 
m
e
=
0
,
5
M
e
V
{\displaystyle m_{\mathrm {e} }={\rm {0{,}5\;MeV}}}
Constante de structure fine : 
α
=
e
2
2
ε
0
h
c
=
1
137
{\displaystyle \alpha ={\frac {e^{2}}{2\varepsilon _{0}hc}}={\frac {1}{137}}}
L'énergie nucléaire est une fraction évaluée habituellement à 1 % de l'énergie de masse d'Einstein, ce qu'on retrouve avec un coefficient de 1/137 obtenu par un calcul basé sur la loi de Coulomb où le potentiel est en 1/r.
Applications
Réactions nucléaires modérées

Cœur de réacteur nucléaire (École polytechnique fédérale de Lausanne).
Les applications de l’énergie nucléaire concernent, pour l’essentiel, deux domaines :

la production d'électricité dans des centrales nucléaires ;
la propulsion navale, principalement pour les flottes militaires (sous-marins et porte-avions) et pour quelques navires civils, notamment des brise-glaces.
Une autre application est la production d’isotopes radioactifs utilisés dans l’industrie (radiographie de soudure, par exemple) et en médecine (médecine nucléaire et radiothérapie). D’autres utilisations ont été imaginées, voire expérimentées, comme la production de chaleur pour alimenter un réseau de chauffage, le dessalement de l’eau de mer ou la production d'hydrogène.

Ces applications utilisent des réacteurs nucléaires (appelés aussi piles atomiques, lorsqu’il s’agit de faible puissance, d’usage expérimental et de production de radioisotopes). Les réactions de fission nucléaire y sont amorcées, modérées et contrôlées dans le cœur, constitué de l'assemblage de combustible et de barres de contrôle et traversé par un fluide caloporteur qui en extrait la chaleur. Cette chaleur est ensuite convertie en énergie électrique (ou en énergie motrice pour la propulsion navale) par l’intermédiaire de turbines et alternateurs (ensemble appelé turbo-alternateur).

Centrales nucléaires
Articles détaillés : Situation du parc nucléaire électrogène mondial et Centrale nucléaire.
Les 415 réacteurs en fonctionnement au 23 novembre 2024 totalisent une puissance installée de 373 735 MW, dont 96 952 MW (25,9 %) aux États-Unis, 61 370 MW (16,4 %) en France, 54 152 MW (14,5 %) en Chine, 26 802 MW (7,2 %) en Russie, 25 825 MW (6,9 %) en Corée du sud, 13 699 MW (3,7 %) au Canada, 13 107 MW (3,5 %) en Ukraine et 11 046 MW (3,0 %) au Japon (12 réacteurs). De plus, 25 réacteurs sont en attente de redémarrage, dont 21 au Japon (20 633 MW) et 4 en Inde (639 MW)[8].

Les 63 réacteurs en construction dans 15 pays totalisent une puissance de 66 100 MW, dont 30 764 MW (46,5 %) en Chine, 5 398 MW (8,2 %) en Inde, 4 456 MW (6,7 %) en Turquie, 4 400 MW (6,7 %) en Égypte, 3 850 MW (5,8 %) en Russie et 3 260 MW (4,9 %) au Royaume-Uni[9].


Production d'électricité d'origine nucléaire par pays (2012).

Pourcentages de production d'électricité d'origine nucléaire par pays (2012).
La production d'électricité des centrales nucléaires a atteint un pic de 2 661 TWh en 2006 ; après une chute à 2 346 TWh en 2012 consécutive à l'accident nucléaire de Fukushima, elle est remontée progressivement à 2 657 TWh en 2019, puis a reculé à 2 552 TWh en 2023[10].

La part du nucléaire dans la production mondiale d'électricité était de 9,8 % en 2021 et de 9,2 % en 2022 contre 16,9 % en 1990[11]. En 2023, les principaux pays producteurs d'électricité nucléaire sont les États-Unis (779 TWh, 30,5 % du total mondial), la Chine (406 TWh, 15,9 %), la France (324 TWh, 12,7 %), la Russie (204 TWh, 8,0 %) et la Corée du sud (172 TWh, 6,7 %)[12]. En 2020, la Chine augmente sa production de 4,4 points par le démarrage de deux nouveaux réacteurs et prend sa deuxième place à la France[13].

À la suite de l'accident nucléaire de Fukushima, la production d'électricité d'origine nucléaire a chuté de 2 518 TWh en 2011, soit 13,5 % de la production mondiale d'électricité, à 10,8 % en 2012[14], puis se maintient à environ 11 % jusqu'en 2015[15].

La France est le pays dont la part d'électricité d'origine nucléaire est la plus élevée en 2023 (64,8 %), suivie par la Slovaquie (61,3 %), la Hongrie (48,8 %), la Finlande (42,0 %) et la Belgique (41,2 %). Cette production en Chine est en progression rapide depuis le milieu des années 2000, elle atteint 4,9 % de la production électrique du pays en 2023[12].

Dans l'Union européenne, 13 États membres produisent de l'électricité nucléaire. En 2020, cette production nucléaire se chiffre à 683 512 GWh — soit 25 % — de la production d'électricité de l'union. Le plus gros producteur de l'UE est la France (52 % de la production de l'UE), suivi de l'Allemagne (9 %), l'Espagne (9 %) et la Suède (7 %). Ces quatre pays ensemble produisent les trois quarts de l'électricité nucléaire l'UE[16].

Le 28 novembre 2018, la Commission européenne publie une communication proposant une stratégie énergétique à long terme (2050) axée sur la décarbonation de la consommation d'énergie, réduisant les émissions de 90 % d'ici 2050 par la combinaison de mesures d'amélioration de l'efficacité énergétique, d'augmentation de la part de l'électricité dans la consommation finale d'énergie (53 % en 2050 contre 20 % en 2017) ; elle prévoit une utilisation accrue du nucléaire (15 % de la production d'électricité en 2050) à côté des énergies renouvelables (80 % en 2050)[17].

Propulsion navale

USS Enterprise, USS Long Beach et USS Bainbridge en route en mer Méditerranée lors de l'Opération Sea Orbit, en 1964. Ils formaient la « Task Force One », la première force opérationnelle entièrement propulsée par l'énergie nucléaire, et ont parcouru 26 540 milles marins (49 190 km) autour du monde en 65 jours. Réalisée sans aucun ravitaillement en carburant ni en provisions, l'« Opération Sea Orbit » a démontré les capacités des navires de surface à propulsion nucléaire.
Article détaillé : Propulsion (navire).
Les bâtiments à propulsion nucléaire utilisent un ou plusieurs réacteurs nucléaires. La chaleur produite est transmise à un fluide caloporteur utilisé pour générer de la vapeur d’eau actionnant :

des turbines couplées aux hélices de propulsion (propulsion à vapeur) ;
des turbines couplées à des alternateurs alimentant en énergie électrique tout le bâtiment, et éventuellement des moteurs électriques de propulsion (propulsion électrique).
Environ 400 navires à propulsion nucléaire existent dans le monde, très majoritairement militaires, surtout des sous-marins, mais aussi des porte-avions et des croiseurs, et quelques navires civils, principalement des brise-glaces. Des cargos nucléaires ont également été expérimentés dans les années 1960 et 1970 (l’Américain NS Savannah, l’Allemand Otto Hahn et le Japonais Mutsu), mais leur exploitation ne s’est pas avérée rentable et ces expériences ont été abandonnées.

Les coûts d’investissement et d’exploitation de la propulsion nucléaire sont importants, ce qui la rend rarement intéressante pour une utilisation civile. Elle n'est véritablement intéressante que pour un usage militaire, et particulièrement pour les sous-marins. Cette énergie apporte :

une très grande autonomie permettant d’éviter en opérations la contrainte du ravitaillement en combustible (retour à un port ou ravitaillement à la mer). Sur les porte-avions, l’espace libéré par l’absence de soute à combustible, permet de consacrer plus de volume au stockage des munitions ou des aéronefs par exemple ;
une propulsion totalement indépendante de l’atmosphère,
alors que les sous-marins classiques sont contraints de remonter en surface (ou à l’immersion périscopique en utilisant un schnorchel) pour alimenter les moteurs Diesel en air (oxygène) et ainsi recharger leurs batteries électriques, après quelques dizaines d’heures de plongée aux moteurs électriques (quelques jours pour ceux dotés de propulsion AIP), les rendant ainsi détectables et vulnérables, les sous-marins à propulsion nucléaire peuvent rester plusieurs mois en plongée, préservant ainsi leur discrétion,
ils peuvent également soutenir dans la durée des vitesses importantes en plongée qu’un sous-marin classique ne pourrait maintenir plus de quelques dizaines de minutes sans entièrement décharger ses batteries.
La propulsion nucléaire apporte donc aux sous-marins un avantage déterminant, au point que l’on peut, en comparaison, qualifier les sous-marins classiques de simples submersibles.

Propulsion spatiale
Article détaillé : Propulsion nucléaire (astronautique).
Les sondes Voyager I et II ont déjà emporté des générateurs nucléaires pour alimenter leur système électronique. En revanche, la propulsion nucléaire, au cas où elle serait possible, n’est encore qu’envisagée. Elle aurait l’avantage de produire une poussée, certes faible, mais constante pendant tout le trajet, alors que les engins spatiaux actuels - sauf ceux utilisant l’énergie solaire et les moteurs ioniques - ne peuvent produire qu’une seule poussée initiale, ou quelques ajustements de trajectoire, à cause de la faible contenance de leurs réservoirs. C’est pourquoi on les nomme balistiques et c’est aussi pour cela qu’il leur faut atteindre la vitesse de libération dès le départ. Sur de longs trajets, interplanétaires par exemple, cette accélération continue pourrait être globalement plus efficace que l’accélération initiale utilisée actuellement.

Le gouvernement américain a accordé une enveloppe de 125 millions de dollars à la NASA pour concevoir une fusée propulsée grâce à un réacteur nucléaire qui chauffe un fluide, en général de l'hydrogène liquide, à très haute température ; ce fluide est éjecté via un conduit à l'arrière du moteur, créant ainsi une poussée permettant de propulser la fusée Cette technologie pourrait considérablement diminuer les temps de trajet. L'agence spatiale américaine espérerait pouvoir exploiter le futur moteur nucléaire dès sa mission lunaire de 2024, et surtout pour l'objectif Mars en 2033[18],[19].

Chauffage urbain
La chaleur dégagée par la réaction de fission dans les centrales nucléaires sert à produire de la vapeur qui actionne les turbines de générateurs. Les parcs nucléaires actuels atteignent des températures d’exploitation de l’ordre de 300 °C, alors que le chauffage urbain et le dessalement de l’eau de mer nécessitent environ 150 °C. Les centrales nucléaires convertissent actuellement un tiers de la chaleur produite en électricité, la chaleur restante est généralement rejetée dans l’environnement. Au lieu d’être rejetée, celle-ci pourrait être utilisée pour le chauffage ou le refroidissement.

Cette cogénération est pratiquée dans plusieurs pays : Bulgarie, Chine, Hongrie, République tchèque, Roumanie, Russie, Slovaquie, Suisse et Ukraine. Depuis 1983, la centrale nucléaire de Beznau (Suisse) fournit ainsi de la chaleur aux communes, aux particuliers, à l’industrie et aux agriculteurs. L’Akademik Lomonosov, première centrale nucléaire flottante au monde, dont l’exploitation commerciale a débuté en mai 2020, fournit de la chaleur à la région de Tchoukotka, dans l’extrême nord-est de la Russie. En Chine, le réseau de chauffage urbain utilisant la vapeur des deux réacteurs de la centrale nucléaire de Haiyang est devenu opérationnel à la fin de 2020 et la première phase du projet devrait permettre d’éviter l’utilisation de 23 200 tonnes de charbon et l’émission de 60 000 tonnes de CO2 par an. À la fin de 2021, il doit fournir de la chaleur à toute la ville de Haiyang[20].

Dessalement
La faisabilité des usines de dessalement nucléaires intégrées a été confirmée par une expérience de plus de 150 années-réacteurs, principalement en Inde, au Japon et au Kazakhstan. Le réacteur nucléaire d’Aktaou (Kazakhstan), au bord de la mer Caspienne, a produit jusqu’à 135 MWe d’électricité et 80 000 m3 d’eau potable par jour pendant 27 ans, jusqu’à son arrêt en 1999. Au Japon, plusieurs installations de dessalement liées à des réacteurs nucléaires produisent environ 14 000 m3 d’eau potable par jour. En 2002, une centrale de démonstration couplée à deux réacteurs nucléaires de 170 MWe a été mise en place à la centrale nucléaire de Madras, dans le sud-est de l’Inde[20].

Centrales à usages multiples
En Chine, un petit réacteur modulaire à haute température refroidi par gaz est entré en service à la fin de 2021 ; il est conçu pour assurer la production d’électricité, la cogénération, la chaleur industrielle et la production d'hydrogène. Le Japon a redémarré son réacteur expérimental à haute température (HTTR) en juillet 2021. La chaleur produite est utilisée pour la production d’électricité, le dessalement de l’eau de mer et la production d’hydrogène par un procédé thermochimique. L’initiative H2-@-Scale, lancée en 2016 par les États-Unis, vise à examiner les perspectives de production d’hydrogène au moyen de l’énergie nucléaire. Au Canada, les Laboratoires nucléaires canadiens (LNC) prévoient de lancer le Parc de démonstration, d’innovation et de recherche sur l’énergie propre (DIREP), site d’essai pour les applications de cogénération utilisant des petits réacteurs modulaires[20].

Réactions nucléaires explosives
Articles détaillés : Explosion atomique et Arme nucléaire.

Essai nucléaire anglais du 11 octobre 1956.
La puissance de l'énergie nucléaire peut être utilisée comme explosif. L'échelle de l'énergie totale dégagée par les bombes nucléaires va de la kilotonne à la mégatonne d’équivalent TNT. L’énergie d’une explosion nucléaire est répartie essentiellement dans l’effet de souffle (onde de choc), l’effet thermique, l’effet d’impulsion électromagnétique et les radiations.

Types d’armes
Les armes nucléaires sont de deux types. Les armes à fission ou « bombes A » utilisent de l’uranium enrichi ou du plutonium, mis en condition critique par implosion sous l'effet d’un explosif classique ; dans les armes à fusion ou bombes thermonucléaires ou « bombes H », les conditions de température et de pression nécessaires à la réaction de fusion d’isotopes d’hydrogène (deutérium et tritium) sont obtenues par l’explosion d’une « amorce » constituée par une bombe à fission au plutonium.

La bombe à neutrons est une variante de bombe thermonucléaire conçue pour maximiser la part de l’énergie émise sous forme de neutrons ; elle est supposée détruire les plus grandes formes de vie dans le voisinage de la cible, tout en provoquant un minimum de dégâts matériels.

Histoire
Article détaillé : Histoire de l'arme nucléaire.
La première utilisation militaire d’une arme nucléaire (« bombe A ») a eu lieu les 6 et 9 août 1945. Le largage de deux bombes sur les villes japonaises d’Hiroshima et de Nagasaki par l’armée américaine visait à mettre un terme à la Seconde Guerre mondiale. Depuis, ce type d’armement n’a fait l’objet que d’essais nucléaires expérimentaux (atmosphériques puis souterrains) puis de modélisations informatiques. La bombe atomique a été à l’origine de la doctrine de dissuasion ou « équilibre de la terreur » qui a été développée durant la Guerre froide.

Doctrine d’emploi
Dans la doctrine d’emploi de la plupart des puissances nucléaires, on distingue :

l’arme nucléaire stratégique, instrument de la doctrine de dissuasion nucléaire ou de « non-emploi », destinée à prévenir un conflit ;
de l’arme nucléaire tactique, ou de bataille, susceptible d’être employée sur des objectifs militaires au cours d’un conflit. La précision des vecteurs aidant, ce type d’arme a conduit à la miniaturisation et aux faibles puissances (mini-nuke dans le jargon journalistique américain).
La doctrine française n’a jamais considéré l’emploi d’armes nucléaires à des fins tactiques. Des armes de relative faible puissance (missiles Pluton puis Hadès, aujourd’hui retirés, missiles de croisière ASMP) sont définies comme pré-stratégiques ; dans cette conception, ces armes ne servent qu’accessoirement à un but militaire sur le terrain, leur principal effet étant celui d’un « ultime avertissement », de nature politique, pour prévenir les dirigeants ennemis que les intérêts vitaux de la France sont désormais en jeu, et que le prochain échelon des représailles sera thermonucléaire.

Industrie du nucléaire
Article détaillé : Industrie nucléaire.
Pendant la Seconde Guerre mondiale et dans les décennies suivantes, la quasi-totalité de l'uranium était utilisé pour la fabrication d'armes nucléaires. Cela a cessé d'être le cas au cours des années 1970, et désormais l'uranium est essentiellement utilisé comme combustible dans les centrales nucléaires[21].

La production d'énergie nucléaire est une activité de haute technologie qui demande un contrôle rigoureux et permanent[22]. Ce contrôle est aussi bien le fait des autorités de sûreté nationales (l'Autorité de sûreté nucléaire et de radioprotection en France) qu'internationales, comme l'Agence internationale de l'énergie atomique au niveau mondial, ou la Communauté européenne de l'énergie atomique (Euratom) en Europe.

Recherche dans le domaine de l’énergie nucléaire
Les pays détenteurs de l'arme atomique (Russie, États-Unis, Royaume-Uni, France, Chine, Inde, Pakistan, Israël et Corée du Nord) mènent des recherches classées « secret défense » pour entretenir ou moderniser leur arsenal atomique.
Les États-Unis, l’Union européenne, la Russie, le Japon, la Chine et la Corée du Sud se sont réunis autour du projet ITER, programme d’étude à long terme de la fusion nucléaire contrôlée. C’est un projet de recherche qui a pour objectif la construction et l’exploitation expérimentale d’un tokamak de grandes dimensions. Le réacteur sera construit à Cadarache en France. Ce projet explore une des branches de la fusion, la fusion par confinement magnétique.
Des recherches portent également sur la fusion par confinement inertiel, aux États-Unis qui expérimentent la méthode Z-pinch, ou en France où est construit le laser Mégajoule[23].
Dans le cadre du Forum international génération IV, des études sont menées sur le développement de nouvelles filières de réacteurs nucléaires à fission[24]. Le planning de ce programme international prévoit la mise en service industriel de ces réacteurs à l’horizon 2030-2040.
L’étude du cycle du thorium est en cours. Le thorium pourrait supplanter l’uranium actuellement utilisé, car ses réserves sont plus importantes. Toutefois, le thorium naturel est composé à 100 % de l’isotope 232 qui n’est pas fissile mais fertile (comme l’uranium 238). Son utilisation est donc assujettie au développement des réacteurs surgénérateurs et des procédés chimiques de retraitement afférents.
Depuis mars 1996, au Japon, un programme de recherche international doté d'un centre d'études des matériaux a pour objectif d'inventer les matériaux qui pourront résister à la fusion thermonucléaire, baptisé IFMIF.
Des recherches sont en cours en Chine, notamment sur la technologie de réacteur à lit de boulets. Une unité de démonstration composée de deux réacteurs de type HTR-PM (réacteur à haute température refroidi à l'hélium) et d'une turbine de 210 MWe est en cours de tests en 2018 à la Shidao Bay et sa mise en service est attendue en fin d'année 2018 ; 18 unités de cette technologie sont planifiées pour la même centrale ; une version plus puissante de 650 MWe composée de six réacteurs et une turbine est à l'étude pour déploiement dans plusieurs centrales existantes[25].
Un prototype de réacteur intégral à sels fondus à uranium sera mis en service en 2020 au Canada en 2020 par la société Terrestrial Energy[26]. En Chine, un réacteur à sels fondus au thorium est également en développement en 2017[27].
Dans le domaine des petits réacteurs modulaires, le groupe Technicatome prévoit de construire une tête de série du réacteur Nuward en 2030[28].
Coût de l'énergie nucléaire

Le prix de l'énergie nucléaire nouvellement construite a crû au cours des dernières années, alors qu'il a baissé pour les énergies renouvelables. Toutefois, les données de ce graphique ne prennent pas en compte le coût des équipements de stockage ou des centrales pilotables nécessaires pour compenser l'intermittence de l'éolien et du solaire ; les données sur le nucléaire sont d'origine incertaine[29].
Comparée à d'autres sources d'énergie, l'énergie nucléaire civile nécessite des investissements initiaux très importants, mais bénéficie d'un coût d'exploitation plus faible par kilowatt heure produit[30], conduisant à un faible taux de rentabilité interne : l'investissement dans le nucléaire ne se conçoit que dans le cadre d'une politique à très long terme[31]. Cette exploitation se poursuit sur des durées qui se chiffrent en dizaines d'années. Le coût de l'énergie nucléaire dépend fortement de la durée sur laquelle l'investissement initial est amorti, et la prolongation éventuelle de leur exploitation constitue un enjeu économique très important[32],[33]. La rentabilité varie aussi fortement suivant les solutions techniques proposées (type de centrale, de combustible…)[34].

Le coût du combustible nucléaire est principalement dû à l'enrichissement de l'uranium et à la fabrication des éléments combustibles, qui nécessitent une technologie relativement complexe[30]. La part du minerai d'uranium dans le coût de l'énergie est faible comparée à celles des énergies fossiles : l'énergie nucléaire est par elle-même la source d'une activité industrielle spécialisée.

La Chine travaille, par ailleurs, en partenariat avec les États-Unis, sur la mise au point d'une technologie de réacteur nucléaire à sels fondus[35], dont le coût de revient serait à titre de comparaison inférieur[36] à celui du charbon[37].

Situation et perspectives aux États-Unis
L'Inde et la Chine sont les pays où le nucléaire se développe le plus en 2019, mais les États-Unis comptent encore le plus grand parc nucléaire au monde[38]. Cependant, un seul réacteur nucléaire y a été mis en service depuis 30 ans (Watts Bar 2, dans le Tennessee, 1 200 MW connectés au réseau en 2016) alors que huit tranches ont été arrêtées de 2013 à 2019 (la dernière étant Pilgrim 1, dans le Massachusetts, fin mai 2019) ; et seuls deux projets sont annoncés : les tranches 3 et 4 de la centrale de Vogtle, en Géorgie, qui devraient être dotées de réacteurs de troisième génération de type AP100 en 2021 et 2022[38]. Les premiers de ces nouveaux réacteurs ont été lancés sur les sites de VC Summer en Géorgie et de Vogtle en Caroline du Sud, chacun doté de deux réacteurs AP1000, mais en juillet 2017 le projet de VC Summer a été abandonné (centrale nucléaire de Virgil Summer). De plus, ces deux projets en cours ont subi des problèmes techniques, retards et dépassements et budget (27 milliards de dollars évoqués en 2019) à l'image de ceux de l'EPR européen à Flamanville en France, et à Olkiluoto en Finlande[39].

Dans le même temps, le « boom du gaz de schiste », dû la technologie de la fracturation hydraulique, a fait chuter les prix du gaz et de l'énergie, impulsant une multiplication de centrales à cycle combiné gaz. Quatre réacteurs nucléaires ont fermé en 2013 pour manque de compétitivité et un cinquième fin 2014. Cependant, le prix du gaz devrait augmenter à moyen ou long terme, rendant alors le nucléaire plus compétitif, surtout si des normes d'émissions de CO2 plus sévères sont instituées. Dans le même temps le coût des énergies solaires et éoliennes a aussi beaucoup baissé. En mars 2017, le premier fabricant de réacteurs nucléaires, équipant plus de 50 % des réacteurs au monde, Westinghouse, a été placé en faillite[40]. Des investisseurs ont récemment montré un grand intérêt pour les réacteurs modulaires à sels fondus (MSR pour Molten Salt reactors), qui pourraient remplacer les centrales à charbon appelées à fermer à cause des réglementations sur la pollution de l'air ; mais plusieurs sociétés développant ce concept ont réduit leurs programmes faute de perspectives de déploiement à court terme[41].
```

#### Questions 10000 tokens

```markdown
1. **Début du texte — Question :**
   À quelle interaction fondamentale l’énergie nucléaire est-elle associée et dans quels phénomènes naturels se libère-t-elle ?

**Réponse attendue :**
Elle est liée à « la force nucléaire forte au sein du noyau des atomes » et se libère par « fusion… au sein des étoiles » et par « fission… dans la radioactivité naturelle ».
**Citations :** « l’énergie associée à la force de cohésion des nucléons… la force nucléaire forte », « fusion nucléaire au sein des étoiles », « fission nucléaire dans la radioactivité naturelle ».

---

2. **Première moitié — Question :**
   Dans le cas de la fission, quel est l’ordre de grandeur de l’énergie libérée par événement, et en quoi diffère la réaction en chaîne d’un réacteur de celle d’une bombe ?

**Réponse attendue :**
Environ « 200 MeV par événement » ; dans un réacteur, la chaîne est « à vitesse lente et contrôlée », alors que dans une bombe elle devient « une réaction explosive ».
**Citations :** « dégagement d’énergie très important (de l’ordre de 200 MeV par événement) », « Dans un réacteur nucléaire… à vitesse lente et contrôlée », « Dans une bombe… réaction explosive ».

---

3. **Seconde moitié — Question :**
   Combien de réacteurs nucléaires étaient en fonctionnement et quelle puissance totale installée au 23 novembre 2024 ?

**Réponse attendue :**
« Les 415 réacteurs en fonctionnement… totalisent une puissance installée de 373 735 MW. »
**Citation :** « Les 415 réacteurs en fonctionnement au 23 novembre 2024 totalisent une puissance installée de 373 735 MW… ».

---

4. **Fin du texte — Question :**
   Selon le texte, quelle est la situation récente du nucléaire aux États-Unis (mises en service, arrêts et projets emblématiques) ?

**Réponse attendue :**
Un seul réacteur mis en service en 30 ans (« Watts Bar 2… 2016 »), plusieurs arrêts (huit « de 2013 à 2019 »), un projet abandonné (« VC Summer… abandonné » en 2017) et des retards/dépassements (« 27 milliards de dollars… ») sur les projets AP1000 (Vogtle).
**Citations :** « un seul réacteur… Watts Bar 2… 2016 », « huit tranches ont été arrêtées de 2013 à 2019 », « le projet de VC Summer a été abandonné », « problèmes techniques, retards et dépassements… 27 milliards de dollars ».
```

### Texte 12000 tokens

Nombre de token : 11981
Source https://token-count.streamlit.app/

```markdown
Le football (/futbol/), ou dans le langage courant foot par apocope, ou encore soccer (/sɔkœʁ/) en français d'Amérique du Nord, et plus rarement balle au pied[2], est un sport collectif qui se joue avec un ballon sphérique entre deux équipes de onze joueurs ou joueuses. Ces équipes s'opposent, dans le sens de la longueur, sur un terrain rectangulaire équipé de deux buts installés au milieu de chacun des petits côtés du rectangle. L'objectif de chaque camp est de mettre le ballon dans le but adverse un nombre supérieur de fois à celui de l'autre équipe, sans que les joueurs utilisent leurs bras ou leurs mains, à l'exception des gardiens de buts : le pied est en conséquence la partie du corps principalement utilisée pour provoquer le déplacement du ballon sur le terrain.

Nommé à l'origine « football association » et codifié au Royaume-Uni à la fin du XIXe siècle, le football s'est doté en 1904 d'une fédération internationale, la FIFA. Pratiqué en 2006 par environ 264 millions de joueurs à travers le monde, le football est le sport le plus populaire dans la majorité des pays : ceci est dû au fait qu’il est probablement le sport collectif qui exige le moins de moyens matériels pour une pratique ludique ou d’entraînement, le cas échéant avec un nombre réduit de joueurs. Certains continents, comme l'Afrique, l'Amérique du Sud et l'Europe, sont même presque entièrement dominés par cette pratique sportive[3].

Le calendrier des compétitions est gouverné par deux types d'épreuves : celles concernant les clubs et celles des équipes nationales. La Coupe du monde est l'épreuve internationale la plus prestigieuse. Elle a lieu tous les quatre ans depuis 1930 (sauf en 1942 et 1946). Pour les clubs, championnats nationaux et autres coupes sont au programme des compétitions[3].

En compétition de clubs, la Ligue des champions de l'UEFA, disputée en Europe mais qui possède des équivalents sur les autres continents, est le trophée le plus convoité de ce sport, malgré la mise en place récente d'une Coupe du monde des clubs, encore à la recherche de prestige[3].

Histoire
Article détaillé : Histoire du football.
Genèse du jeu
Article détaillé : Origines du football.

Football dans un livre de colportage anglais du XVIIIe siècle.
Indiens jouant au ballon avec le pied , Extrait de : France pittoresque
Indiens jouant au ballon avec le pied, Extrait du livre ancien France pittoresque, XIXe siècle.
Les jeux de balle au pied existent dès l'Antiquité. Ce sont des jeux et non des sports. Les Grecs connaissent ainsi plusieurs jeux de balle se pratiquant avec les pieds : aporrhaxis et phéninde à Athènes et episkyros, notamment à Sparte[4] où le jeu semblait particulièrement violent[5]. La situation est identique chez les Romains où l'on pratique la pila paganica, la pila trigonalis, la follis et l'harpastum[6]. Les Chinois accomplissent également des exercices avec un ballon qu'ils utilisent pour jongler et effectuer des passes ; cette activité pratiquée sans buts et en dehors de toute compétition sert à l'entretien physique des militaires (蹴鞠, cuju). Les premiers textes concernant le cuju datent de la fin du IIIe siècle av. J.-C. et sont considérés comme les textes les plus anciens liés au sport chinois[7]. À la fin du XVe siècle, le calcio florentin apparaît en Italie. Il s'agit d'un lointain cousin du football, qui disparaît totalement en 1739[8].

Croquis crayonné d'une foule jouant à la soule dans un village normand.
Soule en Basse-Normandie en 1852.
Le football trouve ses racines réelles dans la soule (ou choule) médiévale. Ce jeu sportif est pratiqué dans les écoles et universités mais aussi par le peuple[9] des deux côtés de la Manche. La première mention écrite de la soule en France remonte à 1147[10] et son équivalent anglais date de 1174[11]. Dès le XVIe siècle, le ballon de cuir gonflé est courant en France[11]. Longtemps interdite pour des raisons militaires en Angleterre[12] ou de productivité économique en France[13], la soule, malgré sa brutalité, reste populaire jusqu'au début du XIXe siècle dans les îles Britanniques et dans un grand quart nord-ouest de la France. Le jeu est également pratiqué par les colons d'Amérique du Nord et il est notamment interdit par les autorités de la ville de Boston en 1657[14]. Nommée football en anglais, la soule est rebaptisée folk football (« football du peuple ») par les historiens anglophones du sport afin de la distinguer du football moderne[15]. Cette activité est en effet principalement pratiquée par le petit peuple comme le signale un ancien élève d'Eton dans ses Reminiscences of Eton (1831) : « I cannot consider the game of football as being gentlemanly; after all, the Yorkshire common people play it »[16] (« Je ne peux pas considérer le football comme un sport de gentlemen ; après tout, le petit peuple du Yorkshire y joue »).

Le Highway Act britannique de 1835 interdisant la pratique du folk football sur les routes[16] le contraint à se replier sur des espaces clos. Des variantes de la soule se pratiquent déjà, de longue date, sur des terrains clos[17]. C'est là, sur les terrains des écoles d'Eton, Harrow, Charterhouse, Rugby, Shrewsbury, Westminster et Winchester, notamment, que germe le football moderne. Les premiers codes de jeu écrits datent du milieu du XIXe siècle (1848 à Cambridge[18]). Chaque équipe possède ses propres règles, rendant les matches problématiques. La Fédération anglaise de football (Football Association) est créée en 1863. Son premier objectif est d'unifier le règlement.

Exemple britannique
Article détaillé : Débuts du football.
Photo en noir et blanc d'une équipe de football posant autour de son blason et de ses trophées au centre.
Aston Villa en 1899.
Les Britanniques codifient et organisent le football en s'inspirant des exemples du cricket et du baseball, ces deux sports collectifs étant déjà structurés avant l'émergence du football. Des ligues professionnelles aux championnats et autres coupes, le football n'innove pas. Le premier club non scolaire est fondé en 1857 : le Sheffield Football Club. Le Sheffield FC dispute le premier match inter-club face au Hallam FC (fondé en 1860) le 26 décembre 1860 à seize contre seize[19]. Ces deux clubs pionniers se retrouvent en décembre 1862 pour le premier match de charité[19]. La Youdan Cup est la première compétition. Elle se tient en 1867 à Sheffield et Hallam FC remporte le trophée le 5 mars[20]. La première épreuve à caractère national est la FA Challenge Cup 1872. Le professionnalisme est autorisé en 1885 et le premier championnat se dispute en 1888-1889. La Fédération anglaise tient un rôle prépondérant dans cette évolution, imposant notamment un règlement unique en créant la FA Cup, puis les clubs prennent l'ascendant[21]. La création du championnat (League) n'est pas le fait de la Fédération mais une initiative des clubs cherchant à présenter un calendrier stable et cohérent. L'existence d'un réseau ferroviaire rend possible cette évolution engagée par William McGregor, président d'Aston Villa[22]. Ce premier championnat est professionnel, et aucun club du Sud du pays n'y participe.

L'Angleterre est alors coupée en deux : le Nord acceptant pleinement le professionnalisme et le Sud le rejetant. Cette différence a des explications sociales. Le Sud de l'Angleterre est dominé par l'esprit classique des clubs sportifs réservés à une élite sociale. Dans le Nord dominé par l'industrie, le football professionnel est dirigé par des grands patrons n'hésitant pas à rémunérer leurs joueurs pour renforcer leur équipe, de la même façon qu'ils recrutent de meilleurs ingénieurs pour renforcer leurs entreprises[23]. Pendant cinq saisons, le championnat se limite aux seuls clubs du Nord. Le club londonien d'Arsenal devient professionnel en 1891[24]. La ligue de Londres exclut alors de ses compétitions les Gunners d'Arsenal[25] qui rejoignent la League en 1893. La Southern League est créée en réaction (1894)[26]. Cette compétition s'ouvre progressivement au professionnalisme mais ne peut pas éviter les départs de nombreux clubs vers la League. Les meilleurs clubs encore en Southern League sont incorporés à la League en 1920[27].

Photo noir et blanc d'un but marqué dans le petit filet, hors de portée du gardien lors d'un match de football.
Finale de la FA Cup 1905.
Concernant le jeu, le passage du dribbling game (dribbles individuels) au passing game (jeu de passes) est une évolution importante. À l'origine, le football est très individualiste : les joueurs, tous attaquants, se ruent vers le but balle au pied, c’est-à-dire en enchaînant les dribbles. C'est le dribbling. Mais comme Michel Platini aime à le rappeler, « le ballon ira toujours plus vite que le joueur ». C'est sur ce principe simple qu'est construit le passing game. Cette innovation apparaît à la fin des années 1860 et s'impose dans les années 1880. Dès la fin des années 1860, des matches entre Londres et Sheffield auraient introduit le passing au Nord[28]. C'est la version de Charles Alcock, qui situe en 1883 la première vraie démonstration de passing à Londres par le Blackburn Olympic. Entre ces deux dates, la nouvelle façon de jouer trouve refuge en Écosse[29].

Sur le modèle de la Football Association anglaise, des fédérations nationales sont fondées en Écosse (1873)[30], au pays de Galles (1876)[31] et en Irlande (1880)[32]. Des rencontres opposant les sélections des meilleurs joueurs de ces fédérations ont lieu dès le 30 novembre 1872 (Écosse-Angleterre), soit quelques mois avant la fondation officielle de la Fédération écossaise[33]. Des matches annuels mettent aux prises ces différentes sélections, et à partir de 1884, ces matches amicaux se transforment en une première compétition internationale : le British Home Championship. En pratiquant le passing plutôt que le dribbling, les Écossais dominent les premières éditions[34].

Football international
Photo d'un terrain pendant un match prise d'une tribune latérale. Au centre un fan porte le drapeau du Canada sur son dos.
Match de football au stade BMO Field de Toronto au Canada.
Contrairement aux sports « nobles » comme le cricket, le tennis, le hockey sur gazon et le rugby, le football n'est pas très développé au sein des clubs sportifs installés dans l'Empire britannique. Ainsi, cette discipline est aujourd'hui encore peu prisée en Inde, au Pakistan, en Amérique du Nord ou en Australie, notamment. En Afrique du Sud, les colons britanniques y importent le football dès 1869[35] puis une coupe du Natal est organisée dès 1884[36], mais le football, sport roi dans les townships[37], reste très mal perçu par les tenants blancs de l'apartheid qui lui préfèrent le rugby, le tennis et le cricket. Le football fut, il est vrai, en pointe pour dénoncer l'apartheid et dès le 9 avril 1973, une équipe mêlant joueurs noirs et blancs représente l'Afrique du Sud lors d'un match international non officiel face à la Rhodésie[38].

Les Britanniques jouent pourtant un rôle important dans la diffusion du football, notamment grâce aux ouvriers dépêchés aux quatre coins du monde pour mener à bien des chantiers. Le football est par exemple introduit en Amérique du Sud par les ouvriers travaillant sur les chantiers des lignes ferroviaires. Ils montent des équipes et mettent en place des compétitions d'abord réservées aux seuls joueurs britanniques, et qui s'ouvrent progressivement aux joueurs puis aux clubs locaux. Le cas sud-américain est complexe. Il existe également des clubs britanniques qui pratiquent cette discipline et des étudiants originaires d'Angleterre jouent un rôle important dans l'introduction du football entre Montevideo et Buenos Aires[39]. Ainsi, le football s'installe durablement dans des nations comme l'Uruguay ou l'Argentine dès les années 1870-80. En Amérique du Nord, des compétitions sont créées dans les années 1880 (1884 aux États-Unis sur la côte Est)[40].

Photo d'un match de football prise depuis la tribune basse derrière le côté droit des buts.
Match de football en Belgique (Royal Excelsior Mouscron-Standard de Liège).
La Belgique, où les universités anglaises jouent un rôle moteur[41], les Pays-Bas (premier club fondé en 1879[41]), la Suisse (introduction du football dès les années 1860 et premier club en 1879[42]) et le Danemark (premier club en 1876[43]) figurent parmi les premiers pays de l'Europe continentale touchés par le football.

L'expansion du football est également due à des voyageurs de diverses nationalités ayant effectué des séjours au Royaume-Uni où ils furent initiés au jeu. En France, l'introduction du football se fait ainsi principalement par l'action des professeurs d'anglais qui ramènent de leurs voyages linguistiques outre-Manche règles et ballons dans les cours d'écoles[44]. Les Britanniques sont également déterminants dans l'introduction du football en France. L'action des clubs britanniques parisiens des White-Rovers et du Standard AC fait plier l'Union des sociétés françaises de sports athlétiques (USFSA) le 9 janvier 1894, qui, dans la droite ligne des clubs britanniques guindés, redoutait une expansion du football et de ses vices, comme le professionnalisme, les transferts et les paris et se refusait à reconnaître cette discipline[45]. En Allemagne, le football est d'abord clairement perçu comme un corps étranger à la nation et est dédaigneusement surnommé le « sport des Anglais » par les nationalistes[46]. Toutefois, le football prend racine dans les villes (premier club fondé en 1887 : SC Germania Hambourg) où ouvriers et cols blancs se rassemblent autour d'une passion commune[46]. Le football se diffuse ainsi progressivement en Europe du Nord entre les années 1870 et le début des années 1890, avant de gagner l'Europe du Sud (Sud de la France inclus) entre les années 1890 et le début du XXe siècle.

Photo de la présentation des équipes en début de match, les rouge et jaune à gauche contre les blancs à droite.
Match de football amateur à Rodez (France).
La Fédération internationale de football association (FIFA) est fondée à Paris en 1904 malgré le refus britannique de participer à une entreprise lancée par les dirigeants français de l'USFSA[47]. Le but premier de l'Union est de réduire au silence les autres fédérations sportives françaises pratiquant le football, et elle impose dans les textes fondateurs de la FIFA qu'une seule fédération par nation soit reconnue par l'organisme international. Le piège se retourne contre l'USFSA en 1908. L'Union claque la porte de la FIFA, laissant à son principal concurrent, le Comité français interfédéral (ancêtre direct de l'actuelle Fédération française de football), son siège à la FIFA[48] ; l'USFSA se retrouve isolée mais son opposition au professionnalisme demeure la règle jusqu'à la fin des années 1920. Le racingman Frantz Reichel prophétise ainsi en 1922 que « le football professionnel anglais périra s'il reste cantonné sur le sol britannique »[49].

À la fin des années 1920 et au début des années 1930, plusieurs nations européennes et sud-américaines autorisent le professionnalisme afin de mettre un terme aux scandales de l'amateurisme marron qui touchent ces pays depuis les années 1910. Le gardien de but international français Pierre Chayriguès refuse ainsi un « pont d'or » du club anglais de Tottenham Hotspur en 1913 ; il admettra dans ses mémoires que les joueurs du Red Star étaient grassement rémunérés malgré leur statut officiel d'amateur[50]. L'Autriche (1924), la Tchécoslovaquie et la Hongrie (avant 1930), l'Espagne (1929), l'Argentine (1931), la France (1932) et le Brésil (1933) sont les premières nations (hors du Royaume-Uni) à autoriser le professionnalisme dans le football[2]. En Italie, la Carta di Viareggio, mise en place par le régime fasciste en 1926, assure la transition entre le statut amateur et professionnel, définitivement adopté en 1946[51].

Carte stylisée du monde sur laquelle chaque zone continentale possède sa propre couleur.
Les confédérations membres de la FIFA.
     CAF en Afrique
     CONCACAF en Amérique du Nord
     CONMEBOL en Amérique du Sud
     AFC en Asie et Australie
     UEFA en Europe
     OFC en Océanie
Au niveau continental, des confédérations gèrent le football. La première confédération créée est celle d'Amérique du Sud, la CONMEBOL, fondée le 9 juillet 1916. Placées sous l'autorité hiérarchique de la FIFA, les confédérations veillent toutefois à préserver leur indépendance. Elles disposent de certaines libertés, par exemple, pour organiser les qualifications pour la Coupe du monde dans le cadre des règles définies par la FIFA et sont autonomes pour gérer le calendrier de leurs compétitions continentales, malgré des tentatives d'harmonisation sans grande portée de la FIFA. Les cas africains et sud-américains sont significatifs. La Coupe d'Afrique des nations (CAN), par exemple, se dispute tous les deux ans en pleine saison européenne posant des problèmes pour les clubs employant des joueurs africains. La FIFA n'ayant pas autorité sur le calendrier spécifique continental, seule la Confédération africaine maîtrise cette question.

Selon un comptage publié par la FIFA le 31 mai 2007[1], le football est pratiqué dans le monde par 270 millions de personnes dont 264,5 millions de joueurs (239,5 millions d'hommes et 26 millions de femmes). On compte environ 301 000 clubs pour 1 700 000 équipes et 840 000 arbitres. 113 000 joueurs évoluent sous statut professionnel. Ce dernier chiffre est à manier avec précaution car il existe des différences considérables entre les nations à propos de la définition d'un joueur professionnel. L'Allemagne est ainsi absente du classement des vingt premières nations à ce niveau tandis que d'autres nations, moins strictes dans la définition du statut professionnel, avancent des données artificiellement élevées.

Au niveau des nations, la Chine est en tête avec 26,166 millions de joueurs pratiquants. Derrière la Chine, on trouve les États-Unis (24,473 millions), l'Inde (20,588), l'Allemagne (16,309), le Brésil (13,198), le Mexique (8,480), l'Indonésie (7,094), le Nigeria (6,654), le Bangladesh (6,280), la Russie (5,803), l'Italie (4,980), le Japon (4,805), l'Afrique du Sud (4,540), la France (4,190) et l'Angleterre (4,164). Ces chiffres prennent en compte les licenciés et les pratiquants non licenciés. Concernant les joueurs licenciés, le tableau ci-dessous présente les données des douze fédérations nationales comptant le plus de joueurs licenciés. Après la participation en finale de la Coupe du monde 2006 de l'équipe de France, le nombre des joueurs licenciés a dépassé le cap des 2 millions en France (2 020 634)[52].

Joueurs licenciés (en milliers, masculins et féminines au 1er juillet 2006)


Genèse du football féminin
Article détaillé : Débuts du football féminin.
Photo en noir et blanc d'une rencontre féminine au début du XXe siècle.
Rencontre de football féminin en France en février 1923.
Les femmes jouent au football depuis la fin du XIXe siècle en Angleterre et en Écosse[53]. La France met en place le premier championnat national juste après la Première Guerre mondiale[54]. Les recettes sont telles que les joueuses sont rémunérées via la pratique de l'amateurisme marron[55]. Le tir de barrage contre la pratique du football par les femmes s'intensifie[56] et le décès d'une joueuse, Miss C.V. Richards, en plein match en 1926 renforce les tenants de l'interdiction. Henri Desgrange (L'Auto) est plus radical encore dès 1925 : « Que les jeunes filles fassent du sport entre elles, dans un terrain rigoureusement clos, inaccessible au public : oui d'accord. Mais qu'elles se donnent en spectacle, à certains jours de fêtes, où sera convié le public, qu'elles osent même courir après un ballon dans une prairie qui n'est pas entourée de murs épais, voilà qui est intolérable ! »[57]. Les instances masculines refusent déjà d'admettre depuis le début des années 1920 des licenciées féminines et elles doivent s'organiser en fédération indépendante des deux côtés de la Manche. Le championnat de France de football féminin, où brilla notamment le Fémina Sport, s'arrête en 1933[58]. Pourtant favorable au sport féminin, le régime de Vichy « interdit rigoureusement » la pratique dans l'Hexagone en 1941. Le football est jugé « nocif pour les femmes »[59].

Presque anecdotique, la pratique perdure après la Seconde Guerre mondiale mais il faut attendre la seconde moitié des années 1960 pour assister au renouveau du football féminin : en 1969-1970, les fédérations anglaise, française et allemande reconnaissent ainsi le football féminin[60]. On recense 2 170 licenciées à la FFF pour la saison 1970-71, puis 4 900 la saison suivante[61].

Au niveau international, une première Coupe d'Europe est organisée en 1969[62]. Elle met aux prises l'Angleterre, le Danemark, la France et l'Italie. Le football féminin n'étant pas reconnu officiellement par la FIFA et l'UEFA, cette compétition est « non officielle ».

Au niveau mondial, la première Coupe du monde est jouée dès juillet 1970[63]. C'est encore une compétition « non officielle ». Après de multiples organisations de ce type, l'UEFA (1984)[64] puis la FIFA (1991)[65] conviennent qu'il faut mettre en place des compétitions « officielles », Coupe du monde de football féminin et Championnat d'Europe de football féminin notamment.

Appellations contrôlées
L'association anglaise de football, la Football Association, fondée à Londres en 1863, prend à son compte le terme générique de « football » et, en codifiant les règles du jeu, lui adjoint la mention « association » (association football) afin de le distinguer des autres formes de football jouées à l'époque. Cependant certains des clubs adhérents à la FA continuent de suivre des règles très différentes ; Blackheath RC, notamment, qui milite pour l'usage des mains et l'autorisation du placage. L'unification des règles menée par la FA, qui marque la période allant de 1863 à 1870 place Blackheath dans une position isolée. Le club londonien quitte alors la FA et part créer en 1871 la Football Rugby Union, une fédération de football selon les règles dites de Rugby. Ainsi, dès 1871, deux formes principales de football, d'une part l'association football et d'autre part le Rugby football (football de Rugby) sont codifiées et disposent d’instances dirigeantes. Ces deux sports essaiment dans le monde entier et donnent naissance à des variantes américaine, australienne, gaélique ou canadienne.

Très tôt, une variante argotique d'appellation de « association football » apparaît chez les anglophones par abréviation : d'abord « assoc. football » puis « assoc. » et enfin le diminutif « soc » complété par le suffixe « -er » qui donnera le terme « soccer ». Cette dernière appellation s'est largement popularisée au fil du temps en Amérique du Nord au point d'éclipser totalement toute mention de « football ». Les changements de noms de la fédération américaine (États-Unis) de football au cours du vingtième siècle témoignent de cette évolution : en 1913, date de sa fondation, à 1945, elle a pour nom United States Football Association, puis jusqu'en 1974 elle porte le nom de United States Soccer Football Association. Elle adopte alors le nom de United States Soccer Federation. Soccer[66] est officiellement en usage dans trois pays : États-Unis, Canada et Samoa, les trois seules fédérations nationales anglophones qui reprennent le terme de soccer (en excluant football) dans leur nom. Ce terme argotique pour les autres anglophones est toutefois parfois employé, notamment dans la presse. Il est ainsi d'emploi très courant en Afrique du Sud et plus rare au Royaume-Uni.

Chez les francophones, le dictionnaire quadrilingue de la FIFA[67] donne « football » comme seule dénomination officielle du jeu actuellement en français[68], bien que les francophones canadiens aient adopté le terme « soccer » en raison de son usage courant et généralisé au Canada.

Ces questions de dénominations ne touchent pas que les pays donnant naissance à des « football » locaux. Ainsi, en France, la peur panique des paris, du professionnalisme et de la montée en puissance des pouvoirs des clubs provoquent un boycott de la discipline par l'USFSA. Pour cette fédération, le seul football reconnu est celui de la variante du rugby car les instances anglaises de cette discipline étaient parvenues à interdire l’adoption du professionnalisme. Aussi, le terme football employé seul fait plutôt référence en France à celui de Rugby (football rugby) jusqu'au début du XXe siècle[69]. À partir de 1894 et la reconnaissance tardive de la discipline par l'USFSA, l'appellation « football association » (traduction française de « association football ») ou plus simplement « association » s'impose naturellement. On joue ainsi à l'« assoce » en France à la Belle Époque et on retrouve dans certains journaux de province le terme « association » jusque dans les années 1920. C'est également en France, à Paris, en 1904 qu'est fondée (avec comme première langue officielle le français) la Fédération Internationale de Football Association (en anglais : International Federation of Association Football). La Fédération Française de Football Association n'est quant à elle fondée qu'en 1919 à la suite de l'éclatement de la structure omnisports de l'USFSA. Dans le milieu du football association, le terme de football est de plus en plus utilisé seul pour nommer le jeu, et la mention « association » perd alors progressivement de son usage : le magazine spécialisé Football, créé en 1929, puis la FFFA qui devient FFF à la Libération illustrent cette évolution. De son côté le rugby, éclaté en deux sports différents, à XV ou à XIII, a perdu l'usage du terme « football » tandis que les autres variantes sont perçues comme exotiques en Europe et dans les pays francophones, Canada excepté. Elles sont donc nommées selon leur origine : football américain, football australien, football gaélique et football canadien.

Le français, comme c'est le cas en général dans le domaine sportif[70], a ainsi conservé le terme d'origine (au moins en partie à l'époque, car la mention association a bien été traduite, ce qui explique l'inversion en passant de l'anglais « association football » au français « football association »). Ce n'est pas le cas dans la plupart des autres langues où ont été forgés des termes à consonances locales, du Fussball allemand, au Fútbol espagnol (ou également très rarement Balompié) en passant par le Voetbal néerlandais ou le Futebol portugais. En Italie, on adopte en 1909 le terme de calcio en référence à l'ancien jeu du calcio florentin[71].

Pratique du football
Règlement
Premières règles
Articles détaillés : Règles de Cambridge et Règles de Sheffield.
Le premier code de jeu date de 1848 : les Cambridge Rules[18]. D'autres universités suivent l'exemple de Cambridge et édictent leurs propres règlements. Harrow met ainsi en place un code autorisant l'usage des mains qui donnera naissance au rugby et à ses déclinaisons, comme le football américain et le football canadien. Le football se base exclusivement sur les règles de Cambridge, qui s'imposent comme les plus simples. Cette notion de simplicité est fondatrice du football lui-même, comme l'indique clairement le sous-titre des règles de J. C. Thring qui affinent le règlement de Cambridge en 1862 : The Simplest Game[72] (« Le jeu le plus simple »).

Composition de 9 croquis crayonnés présentant différentes actions d'un match de football.
Angleterre-Écosse en 1872.
Quand la Football Association (FA) est fondée à Londres le 26 octobre 1863, E.C. Morley est chargé de faire une synthèse des différentes règles en usage[73]. Blackheath RC qui suivait les règles d'Harrow, était alors membre de la FA et le débat devient houleux quand un premier code de 14 règles s'inspirant des Cambridge Rules est présenté le 24 novembre 1863[73]. Après plusieurs jours de débats et de modifications, un règlement de 13 règles est adopté le 1er décembre par 13 voix contre 4[74]. Le 9 janvier 1864, le premier match disputé sous ses nouvelles lois du jeu est joué[73]. Elles sont assez floues, notamment dans les domaines du nombre de joueurs et des dimensions du terrain ou des buts car un accord n'a pas pu être trouvé sur ces points. Les équipes comptent alors de treize à quinze joueurs puis passent à onze progressivement, malgré les résistances de nombre d'équipes à la fin des années 1860. En 1867, quand la Surrey FA propose un match à onze contre onze au Cambridge University FC, ce dernier répond par courrier : « nous jouons au minimum à quinze par équipe et nous ne pouvons pas jouer avec moins de treize joueurs par équipe[75] ». La loi 11 précise que l'usage des mains est interdit. De fait, il s'agit dans les grandes lignes de la reprise des Cambridge Rules et des règles de J.C. Thring, saluées par tous comme les plus simples[76].

Le 1er décembre 1863, le Sheffield FC demande son affiliation à la FA[76]. Les clubs de Sheffield suivent alors un code de jeu particulier mais proche des Cambridge Rules et qui se joue à onze contre onze[19]. Pendant plus d'une décennie, les deux codes coexistent et s'influencent tandis que certains clubs édictent des règlements internes stipulant que seul leur règlement interne est applicable. Cette situation très hétérogène n'empêche pas la FA de peaufiner son règlement. Le poste du gardien de but est ainsi créé en 1870[75]. De même, entre 1867 et 1870, les règles de Sheffield connaissent quelques modifications comme l'abandon en 1868 du rouge[77] (forme de points semblable au football australien, avec deux poteaux supplémentaires situés à 4 yards des buts). Les clubs de la région de Nottingham, qui avaient également un règlement inspiré des Cambridge Rules, adoptent les règles de la FA en 1867[78].

La FA Cup est fondée en 1871 sur le principe « une coupe, deux codes »[79]. L'espoir de la FA est de pousser les clubs de Sheffield à adopter ses règles. C'est presque l'inverse qui se produit. En fait, les deux codes fusionnent en 1877[80]. Depuis lors, les règles sont unifiées puis confiées à la garde de l'International Board, créé le 6 décembre 1882.

Principes du jeu

Un jeune gardien de but en action dans son but.
Le football met aux prises deux équipes de onze joueurs sur un terrain rectangulaire de 90 à 120 mètres de long sur 45 à 90 mètres de large. Pour les matches internationaux, les dimensions du terrain sont ramenées entre 100 et 110 mètres de long pour 64 à 75 mètres de large. L'objectif est de faire pénétrer un ballon sphérique de 68 à 70 cm de circonférence pour un poids de 410 à 450 grammes[81] dans un but long de 7,32 m sur 2,44 m de hauteur. Le but est considéré marqué quand le ballon a entièrement franchi la ligne de but tracée au sol entre les deux poteaux[82].

Le seul joueur autorisé à utiliser ses mains et ses bras lorsque le ballon est en jeu est le gardien de but, pourvu que ce dernier se trouve dans sa surface de réparation. Dans cette même surface, une faute habituellement sanctionnée par un coup franc direct, l'est par un coup de pied de réparation (pénalty). Ce dernier s'exécute sur un point situé à 11 mètres de la ligne de but. Outre les fautes de mains, les autres fautes concernent essentiellement les comportements antisportifs et les contacts entre les joueurs. Le tacle est autorisé, mais réglementé : un tacle par derrière est ainsi souvent sanctionné d'un carton rouge synonyme d'expulsion. En cas de faute moins grave, un carton jaune peut être donné par l'arbitre au joueur fautif. Si ce joueur écope d'un second carton jaune au cours d'une même partie, il est expulsé[83].

La règle du hors-jeu force les attaquants à ne pas se contenter d'attendre des ballons derrière la défense adverse. Pour qu'un joueur soit en jeu, il faut qu'il soit devant le dernier défenseur adverse, dans le sens du jeu de ce défenseur. L'arbitre assistant signale avec un drapeau le hors-jeu qui se juge au départ de la balle, c'est-à-dire au moment où le passeur frappe le ballon, et non pas à l'arrivée du ballon dans les pieds de l'attaquant.

Le match dure 90 minutes en deux périodes de 45 minutes séparées par une interruption (ou mi-temps) de 15 minutes. Lors de certains matches de coupe devant désigner un vainqueur ou un qualifié (on peut se qualifier en matches aller-retour sans nécessairement remporter le match retour), une prolongation de deux fois quinze minutes est disputée. Au terme de cette période, en cas d'égalité, les tirs au but départagent les deux formations[84].

Lois du jeu
Article détaillé : Lois du jeu.
Le football compte dix-sept « lois du jeu » régies par l'International Board. Le règlement est le même pour les professionnels et les amateurs, en senior ou chez les jeunes. La FIFA veille à l'application uniforme des mêmes lois du jeu partout dans le monde.

Les 17 lois du jeu :

1 Le terrain de jeu
2 Le ballon
3 Nombre de joueurs
4 Équipement des joueurs
5 L'arbitre
6 Les arbitres assistants
7 La durée du match
8 Le coup d'envoi et reprise du jeu
9 Ballon en jeu et hors du jeu
10 But marqué
11 Le hors-jeu
12 Fautes et comportement antisportif
13 Coup franc
14 Coup de pied de réparation (penalty)
15 Rentrée de touche
16 Coup de pied de but
17 Coup de pied de coin (corner)
Très conservateur, l'International Board modifie rarement le règlement contrairement à nombre d'autres disciplines sportives. Depuis la création du Board, la plus importante réforme fut celle de 1925 qui porte de trois à deux le nombre de joueurs adverses devant se situer entre la ligne de but et celui qui reçoit une passe pour ne pas être hors-jeu[85]. Cette réforme a d'importantes implications en matière de tactique. Signalons également les réformes liées au gardien de but avec l'interdiction de prendre le ballon à la main sur une passe d'un partenaire[86] (1992)[87] et de la limitation à l'usage des mains dans la seule surface de réparation (1912)[88]. D'autres évolutions importantes ont lieu en 1891 : elles concernent l'arbitre.

Arbitre
Article détaillé : Arbitre de football.
Photo de la présentation des trois arbitres en tenue (dont deux femmes) avec un ballon posé au sol.
Trio arbitral mixte.
Sur le terrain, l'application du règlement est confiée à un corps arbitral qui se met en place définitivement en 1891[89]. Un temps évoqué, le double arbitrage était en usage au début du jeu et un troisième arbitre, situé en tribune, prenait la décision en cas de conflit entre les deux arbitres principaux. Ce système s’avère inefficace et en 1891, le referee, jadis placé en tribune, est désormais positionné sur le terrain, tandis que la doublette d’arbitres (umpires) est mise sur les bords de touche (linesmen). L'arbitre central est rapidement doté de larges pouvoirs afin de diriger pleinement la partie. Avant ces réformes, les penalties n'existent pas et l'arbitre n'a pas le contrôle du temps de jeu. Depuis 1874, les umpires peuvent siffler des coups francs et expulser des joueurs. Avant cette date, les expulsions sont discutées avec les capitaines[90]. Les cartons jaunes et rouges sont introduits en 1970 à la suite d'un incident au cours du match de Coupe du monde Angleterre-Argentine en 1966. Expulsé, le capitaine argentin Antonio Rattín refuse de quitter le terrain prétextant ne pas comprendre l'arbitre allemand Rudolf Kreitlein ; l'affaire dure sept minutes[91]. Pour éviter ce genre de problèmes, le Board met en place le système universel de cartons de pénalité jaunes et rouges.

Le corps arbitral est aujourd'hui constitué d'un arbitre principal qui se déplace sur le terrain, ainsi que deux arbitres assistants évoluant le long de chaque ligne de touche et munis de drapeaux. Dans le milieu professionnel, un quatrième arbitre est présent pour assurer un remplacement en cas de blessure de l'un des trois autres ; il sert également à signaler les changements de joueurs et à veiller au maintien de l'ordre dans les zones techniques (bancs des joueurs) et au bord du terrain. Au plus haut niveau, les arbitres subissent des tests physiques réguliers (test de Cooper, notamment).

Depuis la fin du XXe siècle, le recours à la vidéo est souvent évoqué pour remédier aux problèmes d’arbitrage. Ce système est toutefois très controversé, notamment car il n'est pas absolument fiable[réf. nécessaire] et n'est pas applicable à tous les niveaux du football, des juniors aux vétérans. Le 8 mars 2008, à l'occasion de sa 122e réunion annuelle, le Board suspend, jusqu'à nouvel ordre, les options technologiques après des essais peu concluants d'arbitrage vidéo testés au Japon et les difficultés techniques rencontrées par les équipes travaillant sur le contrôle de la ligne de but par des moyens électroniques. En revanche, le Board autorise la mise en place de tests avec deux arbitres assistants supplémentaires pour surveiller les surfaces de réparation[92].

Photo d'un arbitre de touche en jaune levant son drapeau avec les tribunes en fond.
Arbitre assistant signalant une sortie de but.
Comme dans d'autres disciplines, l'arbitrage doit faire face à des problèmes de corruption. Les derniers cas en date en Allemagne[93], en Belgique[94], en Italie[95] et au Portugal[96] ont notamment mis en lumière le rôle de certains clubs dans ces affaires mais aussi l'intervention de parieurs. Dans d'autres cas, des joueurs peuvent être également impliqués. Les sanctions (rétrogradation, titre annulé, points retirés et poursuites judiciaires des personnes impliquées) et les précautions (en Allemagne, l'arbitre est désormais désigné 48 heures avant la rencontre) n'empêchent pas la poursuite de ces pratiques. Aussi, de nombreuses voix appellent de leurs vœux la mise en place d'un véritable statut professionnel pour les arbitres.

Le statut des arbitres, professionnel ou pas, est un sujet récurrent des dernières années. La plupart des arbitres sont amateurs. La FIFA et son président Sepp Blatter militent pour l'arbitrage professionnel. Pour les matchs de haut niveau, les arbitres sont sous contrat avec leur fédération en Argentine, au Brésil, au Mexique et en France, liés à la Premier League en Angleterre, et sous une sorte de rapport contractuel en Italie[97].

La féminisation du corps arbitral débute avant la reconnaissance du football féminin. En France, on attend ainsi 1970 pour admettre des licenciées féminines à la FFF mais la première femme certifiée arbitre l'est dès le 10 novembre 1967 (Martine Giron, 21 ans)[98]. Depuis les années 1990, des femmes (Nelly Viénot, notamment, à partir du 23 avril 1996[99]) accèdent au statut d'arbitre assistant en première division. En 2003, un premier match masculin de l'UEFA est arbitré par une femme, Nicole Petignat[100].

Les équipements
L'équipement du joueur

Évolution des chaussures de football de 1930 à 2002.
Article détaillé : Loi 4 du football.
Réglementés par la Loi 4, les équipements des joueurs comprennent un maillot, un short, une paire de chaussettes, des protège-tibias et des chaussures. Le port des gants et des lunettes est autorisé. Les gardiens arborent parfois des casquettes quand ils font face au soleil. Ils doivent de plus porter un maillot de couleur différente. La possibilité de porter une jupe-short est évoquée pour les équipes féminines depuis 2008[101], mais le règlement officiel n'en fait pour l'instant aucune mention[102].

Les équipes disposent de plusieurs jeux de maillots. Habituellement, une équipe évolue avec ses couleurs à domicile et doit s'adapter aux couleurs de l'adversaire en déplacement. L'échange des maillots en fin de partie est une tradition pour les matches importants.

Les premiers maillots sont des lainages assez épais. Ils s'allègent durant la première moitié du XXe siècle avec l'adoption de chemises en coton, puis, grâce aux fibres synthétiques à partir des années 1960, ils deviennent très légers. Polyester et polyamide sont principalement utilisés avec des systèmes d'évacuation de la transpiration.

Les chaussures sont à l'origine des chaussures montantes courantes auxquelles on fixait des crampons. Il faut attendre les années 1950, et les premières chaussures de football commercialisées par Adidas, pour voir l'apparition de chaussures modernes. Depuis les années 1990, les meilleures chaussures sont généralement en peau de kangourou avec semelle en plastique et crampons en aluminium.

Le ballon est codifié par la Loi 2. Ses dimensions sont fixées en 1872. Le ballon doit être sphérique, en cuir ou dans une autre matière adéquate, avoir une circonférence de 70 cm au plus et de 68 cm au moins, un poids de 450 g au plus et de 410 g au moins au début du match et une pression de 0,6 à 1,1 atmosphère (600 - 1 100 g/cm2). Ces dimensions sont plus réduites pour les ballons utilisés par les joueurs de moins de 13 ans. Depuis le 1er janvier 1996, seuls des ballons ayant passé les tests de la FIFA (Fifa Approved) sont utilisables en compétitions internationales organisées par la FIFA ou les confédérations continentales[103].

Le stade
Article détaillé : Stade de football.
Du terrain de jeu au stade
Dessin en couleur du terrain de football sur lequel les dimensions principales sont inscrites.
Le terrain de jeu.
Les terrains de cricket restant déserts pendant l'hiver, ils sont utilisés au début de l'histoire du jeu. Ceux qui peuvent disposer d'installations de cricket comprenant également des vestiaires et des tribunes sont toutefois minoritaires. Il faut le plus souvent se contenter de jouer sur un terrain plus ou moins bien tracé et se changer au café du coin. Certains matches drainent toutefois très vite une affluence certaine, et les premières tentatives d'entrées payantes se font en Angleterre dès les années 1860. Sur le continent européen, les vélodromes jouent le rôle des terrains de cricket au Royaume-Uni.

Passée l'étape du simple pavillon destiné à accueillir les membres du bureau et leurs invités puis l'installation de praticables couverts ou pas autour du terrain pour les autres spectateurs, les premiers stades sont principalement en bois, mais les dimensions des tribunes, toujours plus imposantes, nécessitent bien vite le recours à une armature métallique. Parmi les principaux architectes initiant cette évolution, citons l'emblématique Archibald Leitch qui opère de 1904 à 1939.

Après la Seconde Guerre mondiale, les stades connaissent de nombreuses révolutions, du toit cantilever (sans poteaux de soutien au milieu des tribunes) à la construction de systèmes d'éclairage pour les matches en nocturne. Les premières expériences de matches joués à la lumière des projecteurs datent de 1878, mais ce type de rencontres, interdit en Angleterre de 1930 à 1950, reste marginal jusqu'après la Seconde Guerre mondiale[104]. L'éclairage est seulement de quelques centaines de lux, mais la télévision exige au moins 800 lux pour filmer correctement les rencontres. Cette demande pressante de la télévision et les progrès réalisés au niveau des systèmes d'éclairage permettent désormais aux meilleurs stades de disposer d'au moins 1 500 lux.

Le terrain de jeu connaît également des changements avec la mise en place de systèmes de chauffage pour éviter le gel du terrain ou même l'adoption de surfaces de jeu plus ou moins artificielles. La pelouse naturelle reste toujours la plus courante. Quelques clubs anglais installent des revêtements totalement artificiels comme QPR, Luton, Preston et Oldham dans les années 1980, mais la FA freine ces expériences sans toutefois parvenir à les interdire[105]. Même remarque au niveau de la FIFA qui ne recommande pas cette surface mais qui ne l'interdit pas. En revanche, ce type de revêtement reste longtemps proscrit par la FIFA en phase finale de Coupe du monde. Lors de la Coupe du monde 1994 disputée aux États-Unis, les stades ont dû tous être dotés de pelouse naturelle, Pontiac Silverdome à Détroit (Michigan) et Giants Stadium (New Jersey) au premier chef. À la suite des modifications des tests de certification de la FIFA (2001)[106], il est désormais possible d'utiliser un terrain artificiel en phase finale de Coupe du monde. Toutefois, jamais le cas ne s'est produit. Pourtant équipé depuis 2002 d'une pelouse artificielle certifiée par la FIFA, le Stade Loujniki de Moscou est équipé d'une pelouse naturelle pour accueillir la finale de la Ligue des champions de l'UEFA 2007-2008[107].
```

#### Questions 12000 tokens

```markdown
1. **Début du texte — Question :**
   Quelle est la règle générale d’effectif et d’usage des mains au football, et quel est l’objectif du jeu ?

**Réponse attendue :**
Deux équipes de onze, marquer plus de buts que l’adversaire, sans utiliser bras ni mains sauf pour les gardiens.
**Citation :** « …entre deux équipes de onze joueurs ou joueuses… L'objectif… est de mettre le ballon dans le but adverse… sans que les joueurs utilisent leurs bras ou leurs mains, à l'exception des gardiens de buts ».

---

2. **Première moitié — Question :**
   Quand le football a-t-il été codifié et quand la FIFA a-t-elle été fondée ?

**Réponse attendue :**
Codifié au Royaume-Uni à la fin du XIXᵉ siècle ; la FIFA est fondée en 1904.
**Citation :** « Nommé à l'origine “football association” et codifié au Royaume-Uni à la fin du XIXe siècle, le football s'est doté en 1904 d'une fédération internationale, la FIFA. »

---

3. **Seconde moitié — Question :**
   Quelle réforme majeure de 1925 a modifié la règle du hors-jeu ?

**Réponse attendue :**
On est passé de trois à deux joueurs adverses requis entre le but et le receveur pour ne pas être hors-jeu.
**Citation :** « …la plus importante réforme fut celle de 1925 qui porte de trois à deux le nombre de joueurs adverses… pour ne pas être hors-jeu. »

---

4. **Fin du texte — Question :**
   Que dit le texte sur l’usage de pelouses artificielles en phase finale de Coupe du monde et quel stade illustre cette situation ?

**Réponse attendue :**
Depuis 2001, c’est possible selon la certification FIFA, mais cela n’a jamais été appliqué ; le Stade Loujniki, pourtant équipé en synthétique certifié, a reçu une pelouse naturelle pour une finale européenne.
**Citation :** « …il est désormais possible d'utiliser un terrain artificiel en phase finale de Coupe du monde. Toutefois, jamais le cas ne s'est produit. Pourtant équipé depuis 2002 d'une pelouse artificielle certifiée par la FIFA, le Stade Loujniki de Moscou est équipé d'une pelouse naturelle… »
```