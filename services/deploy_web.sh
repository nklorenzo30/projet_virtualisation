#!/bin/bash

# --- 1. Saisie Utilisateur ---
while true; do
  read -p "Combien d'instances Nginx souhaitez-vous déployer (minimum 1) ? " REPLICAS
  
  # Validation : Vérifie si c'est un nombre entier et supérieur ou égal à 1
  if [[ "$REPLICAS" =~ ^[0-9]+$ ]] && [ "$REPLICAS" -ge 1 ]; then
    break # Sort de la boucle si la saisie est valide
  else
    echo "Saisie invalide. Veuillez entrer un nombre entier supérieur ou égal à 1."
  fi
done

echo "Déploiement de $REPLICAS répliques Nginx sur le réseau mynet..."

# --- 2. Boucle de Déploiement ---
for i in $(seq 1 $REPLICAS); do
  
  # Nom unique pour chaque conteneur
  CONTAINER_NAME="web-$i"
  
  # Nettoyage de l'ancienne instance
  sudo docker rm -f "$CONTAINER_NAME" > /dev/null 2>&1
  
  # --- ARGUMENTS DOCKER ---
  WEB_ARGS=(
    --name "$CONTAINER_NAME"
    --network mynet
    
    # LABELS TRAEFIK
    -l "traefik.enable=true"
    
    # Règle de routage (PathPrefix est très général, utilisez Host() si possible)
    # Traefik voit tous les conteneurs avec cette règle et les met en Load Balancer
    -l "traefik.http.routers.$CONTAINER_NAME.rule=PathPrefix(\`/\`)"
    
    # On utilise l'entrypoint 'https' (géré globalement par Traefik)
    -l "traefik.http.routers.$CONTAINER_NAME.entrypoints=https"
    
    # Port interne de Nginx
    -l "traefik.http.services.$CONTAINER_NAME.loadbalancer.server.port=80"
    
    # IMAGE
    nginx
  )
  
  # Lancement du conteneur
  sudo docker run -d "${WEB_ARGS[@]}"
  
  echo "  Instance $i/$REPLICAS ($CONTAINER_NAME) déployée."
done

echo "Déploiement terminé. Traefik répartit la charge entre les $REPLICAS instances."
