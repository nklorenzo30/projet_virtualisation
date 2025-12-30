#!/bin/bash

# Nettoyage
sudo docker rm -f cadvisor 2>/dev/nul
# 1. Définition des arguments dans un tableau
CADVISOR_ARGS=(
  --detach                                     # Tourne en arrière-plan
  --name=cadvisor                              # Nom du conteneur
  --network mynet
  --publish=5000:8080                          # Port Web (Hôte:Conteneur)
  --volume=/:/rootfs:ro                        # Système de fichiers hôte (lecture seule)
  --volume=/var/run:/var/run:rw                # Socket Docker
  --volume=/sys:/sys:ro                        # Stats Kernel / cgroups
  --volume=/var/lib/docker/:/var/lib/docker:ro # Données Docker
  --volume=/dev/disk/:/dev/disk:ro             # Stats Disques
  --privileged                                 # Droits étendus pour les metrics
  --device=/dev/kmsg                           # Logs noyau
)

# 2. Exécution de la commande en utilisant le tableau
docker run "${CADVISOR_ARGS[@]}" ghcr.io/google/cadvisor:latest
