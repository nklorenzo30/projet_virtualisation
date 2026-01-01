#!/bin/bash

# 1. Lancer la Base de données et Traefik
echo "🚀 Démarrage Infrastructure..."
sudo ./run_container_traefik.sh
sudo ./run_container_postgrest_server.sh

# Attente que la DB soit chaude
sleep 5

# 2. Lancer Keycloak
echo "🔑 Démarrage Keycloak..."
sudo ./run_container_keycloak.sh

echo "⏳ Attente du démarrage complet de Keycloak (45 sec)..."
# Keycloak est lourd, il lui faut du temps pour ouvrir le port 8080
sleep 45 

# Astuce : On peut vérifier si Keycloak est prêt avec curl avant de continuer
until curl -s -f "https://localhost/auth/realms/myrealm" > /dev/null; do
  echo "En attente de Keycloak..."
  sleep 5
done

# 3. Lancer les services dépendants
echo "🛡️ Démarrage OAuth2-Proxy..."
sudo ./run_container_oauth2-proxy.sh

echo "api Démarrage PostgREST..."
sudo ./run_container_postgrest.sh

echo "✅ Tout est en ligne !"
