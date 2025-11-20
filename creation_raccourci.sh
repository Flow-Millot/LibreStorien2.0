#!/usr/bin/env bash

################################
# Couleurs console ANSI
################################
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
RESET="\033[0m"

##############################
# Fonctions utilitaires      #
##############################

# Fonctions d’affichage coloré
info()    { echo -e "${CYAN}$*${RESET}"; }
success() { echo -e "${GREEN}$*${RESET}"; }
error()   { echo -e "${RED}$*${RESET}" >&2; }

info "[LibreStorien] Création automatique d’un fichier .desktop"

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
    error "[ERREUR] Le script de lancement est introuvable :"
    error "         $LAUNCH_SCRIPT"
    error "Placer ce script dans le même dossier que launch_librestorien.sh et icon.jpeg"
    exit 1
fi

# Nom de l’application
read -rp "Nom de l'application (Appuyer sur Entrée pour LibreChat) : " APP_NAME
APP_NAME="${APP_NAME:-LibreChat}"

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

info "[LibreStorien] Création du fichier : $DESKTOP_FILE"

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
    # Si aucun dossier n'existe
    error "[ERREUR] Impossible de trouver le dossier Bureau/Desktop dans votre répertoire personnel."
    exit 1
fi

cp "$DESKTOP_FILE" "$USER_DESKTOP/"

# Rendre le raccourci du bureau exécutable
chmod +x "$USER_DESKTOP/${APP_FILE_NAME}.desktop"

info "[LibreStorien] Copié sur le bureau : $USER_DESKTOP/${APP_FILE_NAME}.desktop"

###############################
# Résultat final
###############################

success "[LibreStorien] Fichier .desktop créé avec succès !"
info "[LibreStorien] Menu applications : $DESKTOP_FILE"
info "[LibreStorien] Raccourci sur le bureau : $USER_DESKTOP/${APP_FILE_NAME}.desktop"
