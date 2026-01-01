#!/bin/bash

# 1. Récupérer le jeton auprès de Keycloak
TOKEN=$(curl -s -X POST "https://localhost/auth/realms/myrealm/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=user1" \
  -d "password=1234" \
  -d "grant_type=password" \
  -d "client_id=traefik-client" \
  -d "client_secret=haP55a5J6B355idcE81HwqvOE5MD8wwP" \
  --insecure | jq -r '.access_token')

# 2. Appeler l'API avec ce jeton
curl -X GET "https://localhost/api/users" \
  -H "Authorization: Bearer $TOKEN" \
  --insecure
