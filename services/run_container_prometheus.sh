#!/bin/bash
#
# Script de deploiement Prometheus avec regles d'alertes
# =====================================================
#
# Prometheus collecte les metriques et evalue les regles d'alertes
# pour envoyer les notifications via Alertmanager.
#
# Fonctionnalites :
# - Collecte de metriques depuis cAdvisor, Traefik, etc.
# - Evaluation des regles d'alertes
# - Integration avec Alertmanager
# - Interface web de requetes
#

# Nettoyage du conteneur existant
sudo docker rm -f prometheus 2>/dev/null

echo "Demarrage de Prometheus avec regles d'alertes..."

# Configuration des options Docker
PROMETHEUS_ARGS=(
  # Configuration de base
  --name prometheus                     # Nom du conteneur
  --network mynet                       # Reseau Docker partage
  -d                                    # Mode detache
  
  # Montage des fichiers de configuration
  -v ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml     # Configuration principale
  -v ./prometheus/alert_rules.yml:/etc/prometheus/alert_rules.yml  # Regles d'alertes
  -v prometheus_data:/prometheus        # Volume de donnees persistant
  
  # Exposition du port
  -p 9091:9090                         # Port interface web (9091 sur l'hote)
  
  # Image officielle Prometheus
  prom/prometheus
  
  # Arguments de demarrage
  --config.file=/etc/prometheus/prometheus.yml    # Fichier de configuration
  --web.enable-lifecycle                           # API de rechargement config
  --storage.tsdb.retention.time=30d               # Retention des donnees 30 jours
  --web.console.libraries=/etc/prometheus/console_libraries
  --web.console.templates=/etc/prometheus/consoles
)

# Lancement du conteneur
sudo docker run "${PROMETHEUS_ARGS[@]}"

# Verification du demarrage
if [ $? -eq 0 ]; then
    echo "Prometheus demarre avec succes !"
    echo ""
    echo "Acces :"
    echo "  Interface web : http://localhost:9091"
    echo "  API           : http://localhost:9091/api/v1/"
    echo ""
    echo "Configuration :"
    echo "  Fichier       : ./prometheus/prometheus.yml"
    echo "  Regles        : ./prometheus/alert_rules.yml"
    echo "  Retention     : 30 jours"
    echo ""
    echo "Verification des regles :"
    echo "  curl http://localhost:9091/api/v1/rules"
else
    echo "ERREUR: Echec du demarrage de Prometheus"
    exit 1
fi
