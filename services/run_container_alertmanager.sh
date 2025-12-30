#!/bin/bash

sudo  docker rm -f alertmanager
# Lancer Alertmanager
ALERTMANAGER_ARGS=(
  -d
  --network mynet 
  --name alertmanager 
  -p 9093:9093 
  -v ./alertmanager:/etc/alertmanager 
  prom/alertmanager:latest 
  --config.file=/etc/alertmanager/config.yml 
  --storage.path=/alertmanager
)

docker run "${ALERTMANAGER_ARGS[@]}"
