#!/bin/bash
#
# Script de deploiement du conteneur web Nginx
# =============================================
#
# Ce script lance un conteneur Nginx simple qui sert l'interface web.
# Le conteneur est protege par OAuth2-Proxy et accessible uniquement
# apres authentification via Keycloak.
#
# Fonctionnalites :
# - Conteneur Nginx avec page par defaut
# - Integration au reseau Docker partage
# - Accessible via OAuth2-Proxy sur https://localhost/
#
# Usage : ./run_container_web.sh [nom_conteneur]
# Par defaut, le nom du conteneur est 'web1'
#

# Recuperation du nom du conteneur (parametre optionnel)
INSTANCE_NAME=${1:-web1}

# Suppression du conteneur existant s'il existe
sudo docker rm -f $INSTANCE_NAME 2>/dev/null

# Configuration des options Docker
# Utilisation d'un tableau pour une meilleure lisibilite
WEB_ARGS=(
  --name $INSTANCE_NAME          # Nom du conteneur
  --network mynet                # Reseau Docker partage avec les autres services
  -d                             # Mode detache (arriere-plan)

  # Image Nginx officielle avec configuration par defaut
  nginx
)

# Lancement du conteneur Nginx
sudo docker run "${WEB_ARGS[@]}"

# Confirmation du demarrage
echo "Conteneur Nginx $INSTANCE_NAME demarre (accessible via OAuth2-Proxy)"
echo "Acces : https://localhost/ (apres authentification Keycloak)"
