#!/bin/bash

# Nettoyage
sudo docker rm -f prometheus 2>/dev/nul
# --- PROMETHEUS RUN ---
PROMETHEUS_ARGS=(
  --name prometheus
  --network mynet
  
  # Montage du fichier de configuration et du volume de données
  -v ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
  -v prometheus_data:/prometheus
  
  # Expose le port 9090 sur l'hôte pour le tableau de bord Prometheus
  -p 9091:9090
  
  # Image officielle
  prom/prometheus
  
  # Commande pour démarrer Prometheus avec la configuration montée
  --config.file=/etc/prometheus/prometheus.yml
  --web.enable-lifecycle
)

sudo docker run -d "${PROMETHEUS_ARGS[@]}"
