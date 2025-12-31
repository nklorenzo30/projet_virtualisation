#!/bin/bash

# Nettoyage
sudo docker rm -f db 2>/dev/null

DB_ARGS=(
  --name db
  --network mynet
  
  # --- VOLUMES DE PERSISTENCE ---
  # Stockage permanent des données de la BDD
  -v pgdata:/var/lib/postgresql/data
  # Scripts d'initialisation (SQL, sh) exécutés au premier démarrage
  -v "$(pwd)/db-init":/docker-entrypoint-initdb.d
  
  # --- EXPOSITION DU PORT ---
  # Le port est exposé sur l'hôte UNIQUEMENT si vous utilisez des outils externes.
  # Si vous passez uniquement par PostgREST/Traefik, cette ligne est facultative :
  -p 5432:5432
  
  # --- VARIABLES D'ENVIRONNEMENT ---
  -e POSTGRES_DB=app_db
  -e POSTGRES_USER=admin
  -e POSTGRES_PASSWORD=admin123
  
  # --- IMAGE ---
  postgres:15.15-trixie
)

sudo docker run -d "${DB_ARGS[@]}"
echo "Base de données 'db' lancée. Bases 'app_db' et 'keycloak' prêtes."
