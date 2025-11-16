#!/usr/bin/env bash

echo "=== Création automatique d’un fichier .desktop ==="

###############################
# Détection des chemins locaux
###############################

# Dossier où se trouve ce script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Script de lancement attendu
LAUNCH_SCRIPT="$SCRIPT_DIR/launcher.sh"

# Icône optionnelle
ICON_FILE="$SCRIPT_DIR/icon.jpeg"

###############################
# Vérification du script
###############################

if [[ ! -f "$LAUNCH_SCRIPT" ]]; then
    echo "[ERREUR] Le script de lancement est introuvable :"
    echo "         $LAUNCH_SCRIPT"
    echo "Placer ce script dans le même dossier que launch_librestorien.sh et icon.jpeg"
    exit 1
fi

# Nom de l’application
read -rp "Nom de l'application (ex: LibreChat) : " APP_NAME

# Conversion en minuscules pour nom fichier
APP_FILE_NAME="${APP_NAME,,}"

###############################
# Dossier de destination
###############################

DESKTOP_DIR="$HOME/.local/share/applications"
mkdir -p "$DESKTOP_DIR"

DESKTOP_FILE="$DESKTOP_DIR/${APP_FILE_NAME}.desktop"

###############################
# Création du .desktop
###############################

echo "Création du fichier : $DESKTOP_FILE"

{
echo "[Desktop Entry]"
echo "Type=Application"
echo "Version=1.0"
echo "Name=$APP_NAME"
echo "Comment=Lancer $APP_NAME"
echo "Exec=$LAUNCH_SCRIPT"
if [[ -f "$ICON_FILE" ]]; then
    echo "Icon=$ICON_FILE"
fi
echo "Terminal=true"
echo "Categories=Utility;Development;"
} > "$DESKTOP_FILE"

chmod +x "$DESKTOP_FILE"

###############################
# Copie sur le bureau
###############################

# Détection du dossier Desktop / Bureau selon la langue
if [[ -d "$HOME/Bureau" ]]; then
    USER_DESKTOP="$HOME/Bureau"
elif [[ -d "$HOME/Desktop" ]]; then
    USER_DESKTOP="$HOME/Desktop"
else
    # Si aucun dossier n'existe, on en crée un
    USER_DESKTOP="$HOME/Desktop"
    mkdir -p "$USER_DESKTOP"
fi

cp "$DESKTOP_FILE" "$USER_DESKTOP/"

# Rendre le raccourci du bureau exécutable
chmod +x "$USER_DESKTOP/${APP_FILE_NAME}.desktop"

echo "Copié sur le bureau : $USER_DESKTOP/${APP_FILE_NAME}.desktop"

###############################
# Résultat final
###############################

echo "Fichier .desktop créé avec succès !"
echo "Menu applications : $DESKTOP_FILE"
echo "Raccourci sur le bureau : $USER_DESKTOP/${APP_FILE_NAME}.desktop"
