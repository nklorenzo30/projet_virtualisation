#!/bin/bash
#
# Script de deploiement Alertmanager
# ==================================
#
# Alertmanager gere les alertes envoyees par Prometheus et les route
# vers les canaux de notification appropries (email, Slack, etc.).
#
# Fonctionnalites :
# - Groupement et deduplication des alertes
# - Routage intelligent selon la severite
# - Notifications email configurees
# - Integration avec Prometheus
#
# Configuration : ./alertmanager/config.yml
# Port : 9093 (interface web et API)
#

# Nettoyage du conteneur existant
sudo docker rm -f alertmanager

echo "Demarrage d'Alertmanager..."

# Configuration des options Docker
ALERTMANAGER_ARGS=(
  # Configuration de base
  -d                                    # Mode detache
  --network mynet                       # Reseau Docker partage
  --name alertmanager                   # Nom du conteneur
  
  # Exposition du port
  -p 9093:9093                         # Port interface web et API
  
  # Montage de la configuration
  -v ./alertmanager:/etc/alertmanager  # Configuration et templates
  
  # Image officielle
  prom/alertmanager:latest
  
  # Arguments de demarrage
  --config.file=/etc/alertmanager/config.yml    # Fichier de configuration
  --storage.path=/alertmanager                   # Stockage des donnees
  --web.external-url=http://localhost:9093      # URL externe pour les liens
)

# Lancement du conteneur
docker run "${ALERTMANAGER_ARGS[@]}"

# Verification du demarrage
if [ $? -eq 0 ]; then
    echo "Alertmanager demarre avec succes !"
    echo ""
    echo "Acces :"
    echo "  Interface web : http://localhost:9093"
    echo "  API           : http://localhost:9093/api/v1/"
    echo ""
    echo "Configuration :"
    echo "  Fichier       : ./alertmanager/config.yml"
    echo "  Regles        : ./prometheus/alert_rules.yml"
    echo ""
    echo "Test des notifications :"
    echo "  curl -X POST http://localhost:9093/api/v1/alerts"
else
    echo "ERREUR: Echec du demarrage d'Alertmanager"
    exit 1
fi
