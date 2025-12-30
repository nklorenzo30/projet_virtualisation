#!/bin/bash

# Nettoyage
sudo docker rm -f grafana 2>/dev/null

GRAFANA_ARGS=(
  --name grafana
  --network mynet
  
  # Volume de persistance pour les dashboards et configurations
  -v grafana_data:/var/lib/grafana
  
  # Expose le port 3000 sur l'hôte
  -p 3000:3000
  
  # Image officielle
  grafana/grafana:main-ubuntu 
)

sudo docker run -d "${GRAFANA_ARGS[@]}"

echo "Grafana lancé. Accès via : http://localhost:3000"
