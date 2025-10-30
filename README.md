# LibreStorien2.0 - Guide pour installer le projet

## Installer OpenWeb Ui
Nous mettons à disposition le lien pour installer l'app car l'installation multiplateforme y est détaillée.

https://docs.openwebui.com/getting-started/quick-start/

Dans notre version, nous avons choisi Python et venv.

---

## Installer llama.cpp
Nous mettons à disposition le lien pour installer l'app car l'installation multiplateforme y est détaillée.

https://github.com/ggml-org/llama.cpp/blob/master/docs/install.md

Dans notre version, nous avons choisi l'installation par python après la création de la venv.
```bash
python -m pip install "llama-cpp-python[server]"
```

Puis
```bash
python -m llama_cpp.server \
  --model /absolute/path/to/your-model.gguf \
  --host 127.0.0.1 --port 10000 \
  --n-gpu-layers 999 --ctx-size 8192

```

Il est possible de modifier les paramètres pour convenir au mieux à votre machine.

---

## Ajouter le modèle dans la conversation
1. 
Il est possible de se rendre sur l'interface en suivant ce lien:

http://localhost:8080

Ou bien de suivre le guide d'installation de OpenWeb Ui suivant votre configuration.

2. 
Actuellement le modèle n'est pas encore connecté à l'interface, et donc il va falloir se rendre sur la page:

`Profil` → `Réglages` → `Réglages d'administration` → `Connexions` → `Gérer les connexions API OpenAI`

Ou bien http://localhost:8080/admin/settings/connections s'il s'agit du même port.

3. 
Rentrer le précédent lien dans la case `url`: `http://127.0.0.1:10000/v1` et laisser les autres champs vides.

4. 
Maintenant il est possible de chosir un modèle dans la liste déroulante de la conversation.
Refaire le même procédé llamacpp pour ajouter d'autres modèles et ainsi interchanger suivant l'utilisation.

---
