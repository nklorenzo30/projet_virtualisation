#!/bin/bash
# Variables pour simplifier
REALM="myrealm"
CLIENT_ID="traefik-client"
CLIENT_SECRET="E0EfyreeUDBlfb9pKO3S3qElan8b5adi"
USERNAME="user1"
PASSWORD="1234"
KEYCLOAK_URL="https://localhost/auth"

# Récupérer le token
TOKEN_JSON=$(curl -k -v -s -X POST "$KEYCLOAK_URL/realms/$REALM/protocol/openid-connect/token" \
  -d "grant_type=password" \
  -d "client_id=$CLIENT_ID" \
  -d "client_secret=$CLIENT_SECRET" \
  -d "username=$USERNAME" \
  -d "password=$PASSWORD")

# Extraire l'access token
ACCESS_TOKEN=$(echo "$TOKEN_JSON" | jq -r '.access_token')

echo "Token: $ACCESS_TOKEN"

