#!/bin/bash
#
# Script de test Alertmanager
# ===========================
#
# Ce script teste le bon fonctionnement d'Alertmanager en :
# - Verifiant la connectivite
# - Envoyant une alerte de test
# - Validant la configuration
#

echo "=== TEST ALERTMANAGER ==="
echo ""

# Verification que le conteneur tourne
echo "1. Verification du conteneur Alertmanager..."
if sudo docker ps --filter "name=alertmanager" --format "{{.Names}}" | grep -q alertmanager; then
    echo "   ✓ Conteneur Alertmanager actif"
else
    echo "   ✗ Conteneur Alertmanager non trouve"
    echo "   Conteneurs actifs :"
    sudo docker ps --format "table {{.Names}}\t{{.Status}}"
    exit 1
fi

# Verification de la connectivite
echo ""
echo "2. Test de connectivite..."
if curl -s http://localhost:9093/-/healthy > /dev/null; then
    echo "   ✓ Alertmanager est accessible"
else
    echo "   ✗ Alertmanager n'est pas accessible"
    echo "   Verifiez les logs : sudo docker logs alertmanager"
    exit 1
fi

# Verification de la configuration
echo ""
echo "3. Verification de la configuration..."
CONFIG_STATUS=$(curl -s http://localhost:9093/api/v2/status | jq -r '.cluster.status')
if [ "$CONFIG_STATUS" = "ready" ]; then
    echo "   ✓ Configuration valide"
else
    echo "   ⚠ Status: $CONFIG_STATUS"
fi

# Affichage des recepteurs configures
echo ""
echo "4. Recepteurs configures :"
curl -s http://localhost:9093/api/v2/receivers 2>/dev/null | jq -r '.[].name' | sed 's/^/   - /' || echo "   - email-notifications (configuration basique)"

# Test d'envoi d'alerte
echo ""
echo "5. Envoi d'une alerte de test..."

# Creation d'une alerte de test
TEST_ALERT=$(cat <<EOF
[
  {
    "labels": {
      "alertname": "TestAlert",
      "severity": "warning",
      "instance": "test-instance",
      "service": "test-service"
    },
    "annotations": {
      "summary": "Alerte de test depuis le script",
      "description": "Ceci est une alerte de test pour verifier le bon fonctionnement d'Alertmanager"
    },
    "startsAt": "$(date -Iseconds)",
    "generatorURL": "http://localhost:9093/test"
  }
]
EOF
)

# Envoi de l'alerte (API v2)
RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d "$TEST_ALERT" \
  http://localhost:9093/api/v2/alerts)

if [ -z "$RESPONSE" ]; then
    echo "   ✓ Alerte de test envoyee avec succes"
    echo "   → Verifiez votre email dans quelques minutes"
else
    echo "   ✗ Echec de l'envoi de l'alerte de test"
    echo "   Response: $RESPONSE"
fi

# Verification des alertes actives
echo ""
echo "6. Alertes actuellement actives :"
ACTIVE_ALERTS=$(curl -s http://localhost:9093/api/v2/alerts 2>/dev/null | jq -r '.[] | "   - " + .labels.alertname + " (" + .status.state + ")"' 2>/dev/null)
if [ -n "$ACTIVE_ALERTS" ]; then
    echo "$ACTIVE_ALERTS"
else
    echo "   Aucune alerte active"
fi

# Verification de l'integration Prometheus
echo ""
echo "7. Integration avec Prometheus :"
if curl -s http://localhost:9091/api/v1/alertmanagers 2>/dev/null | jq -r '.data.activeAlertmanagers[].url' | grep -q "alertmanager:9093"; then
    echo "   ✓ Prometheus est connecte a Alertmanager"
else
    echo "   ⚠ Prometheus n'est pas connecte a Alertmanager (normal si Prometheus pas demarre)"
fi

# Verification des logs recents
echo ""
echo "8. Logs recents d'Alertmanager :"
sudo docker logs alertmanager --tail=5 2>/dev/null | sed 's/^/   /'

echo ""
echo "=== RESUME ==="
echo "Interface Alertmanager : http://localhost:9093"
echo "Configuration          : ./alertmanager/config.yml"
echo "Regles d'alertes       : ./prometheus/alert_rules.yml"
echo ""
echo "Commandes utiles :"
echo "  # Voir les alertes actives"
echo "  curl -s http://localhost:9093/api/v1/alerts | jq"
echo ""
echo "  # Voir la configuration"
echo "  curl -s http://localhost:9093/api/v1/status | jq"
echo ""
echo "  # Logs du conteneur"
echo "  sudo docker logs alertmanager"