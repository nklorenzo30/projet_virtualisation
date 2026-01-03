#!/bin/bash
#
# Script de monitoring global de la stack
# =======================================
#
# Ce script verifie l'etat complet de votre architecture de monitoring
# et fournit un rapport detaille de tous les services.
#

echo "=== MONITORING GLOBAL DE LA STACK ==="
echo "Date: $(date)"
echo ""

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher le statut
print_status() {
    local service=$1
    local status=$2
    local details=$3
    
    if [ "$status" = "OK" ]; then
        echo -e "${GREEN}✓${NC} $service: ${GREEN}$status${NC} $details"
    elif [ "$status" = "WARNING" ]; then
        echo -e "${YELLOW}⚠${NC} $service: ${YELLOW}$status${NC} $details"
    else
        echo -e "${RED}✗${NC} $service: ${RED}$status${NC} $details"
    fi
}

# === VERIFICATION DES CONTENEURS ===
echo -e "${BLUE}=== ETAT DES CONTENEURS ===${NC}"

REQUIRED_CONTAINERS=("prometheus" "alertmanager" "grafana" "cadvisor" "traefik" "oauth2-proxy" "postgrest" "web1" "keycloak" "db")

for container in "${REQUIRED_CONTAINERS[@]}"; do
    if sudo docker ps --filter "name=$container" --format "{{.Names}}" | grep -q "^$container$"; then
        uptime=$(sudo docker ps --filter "name=$container" --format "{{.Status}}")
        print_status "$container" "OK" "($uptime)"
    else
        print_status "$container" "DOWN" "(conteneur arrete ou inexistant)"
    fi
done

echo ""

# === VERIFICATION DES SERVICES WEB ===
echo -e "${BLUE}=== ETAT DES SERVICES WEB ===${NC}"

# Test Prometheus
if curl -s http://localhost:9091/-/ready > /dev/null 2>&1; then
    print_status "Prometheus Web" "OK" "(http://localhost:9091)"
else
    print_status "Prometheus Web" "DOWN" "(http://localhost:9091)"
fi

# Test Alertmanager
if curl -s http://localhost:9093/-/healthy > /dev/null 2>&1; then
    print_status "Alertmanager Web" "OK" "(http://localhost:9093)"
else
    print_status "Alertmanager Web" "DOWN" "(http://localhost:9093)"
fi

# Test Grafana
if curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
    print_status "Grafana Web" "OK" "(http://localhost:3000)"
else
    print_status "Grafana Web" "DOWN" "(http://localhost:3000)"
fi

# Test cAdvisor
if curl -s http://localhost:5000/healthz > /dev/null 2>&1; then
    print_status "cAdvisor Web" "OK" "(http://localhost:5000)"
else
    print_status "cAdvisor Web" "DOWN" "(http://localhost:5000)"
fi

# Test Traefik
if curl -s http://localhost:8080/ping > /dev/null 2>&1; then
    print_status "Traefik Dashboard" "OK" "(http://localhost:8080)"
else
    print_status "Traefik Dashboard" "DOWN" "(http://localhost:8080)"
fi

# Test Application
if curl -k -s https://localhost/ > /dev/null 2>&1; then
    print_status "Application Web" "OK" "(https://localhost/)"
else
    print_status "Application Web" "DOWN" "(https://localhost/)"
fi

# Test API
if curl -k -s https://localhost/api/ > /dev/null 2>&1; then
    print_status "API PostgREST" "OK" "(https://localhost/api/)"
else
    print_status "API PostgREST" "DOWN" "(https://localhost/api/)"
fi

echo ""

# === VERIFICATION DES METRIQUES ===
echo -e "${BLUE}=== ETAT DES METRIQUES ===${NC}"

# Prometheus targets
TARGETS_UP=$(curl -s http://localhost:9091/api/v1/targets 2>/dev/null | jq -r '.data.activeTargets[] | select(.health=="up") | .scrapeUrl' | wc -l)
TARGETS_TOTAL=$(curl -s http://localhost:9091/api/v1/targets 2>/dev/null | jq -r '.data.activeTargets[] | .scrapeUrl' | wc -l)

if [ "$TARGETS_UP" -gt 0 ] && [ "$TARGETS_TOTAL" -gt 0 ]; then
    if [ "$TARGETS_UP" -eq "$TARGETS_TOTAL" ]; then
        print_status "Prometheus Targets" "OK" "($TARGETS_UP/$TARGETS_TOTAL actifs)"
    else
        print_status "Prometheus Targets" "WARNING" "($TARGETS_UP/$TARGETS_TOTAL actifs)"
    fi
else
    print_status "Prometheus Targets" "DOWN" "(aucune cible active)"
fi

# Regles d'alertes
RULES_COUNT=$(curl -s http://localhost:9091/api/v1/rules 2>/dev/null | jq -r '.data.groups | length')
if [ "$RULES_COUNT" -gt 0 ]; then
    print_status "Regles d'alertes" "OK" "($RULES_COUNT groupes charges)"
else
    print_status "Regles d'alertes" "DOWN" "(aucune regle chargee)"
fi

# Integration Alertmanager
ALERTMANAGERS=$(curl -s http://localhost:9091/api/v1/alertmanagers 2>/dev/null | jq -r '.data.activeAlertmanagers | length')
if [ "$ALERTMANAGERS" -gt 0 ]; then
    print_status "Integration Alertmanager" "OK" "($ALERTMANAGERS instance(s))"
else
    print_status "Integration Alertmanager" "DOWN" "(aucune instance)"
fi

echo ""

# === ALERTES ACTIVES ===
echo -e "${BLUE}=== ALERTES ACTIVES ===${NC}"

ACTIVE_ALERTS=$(curl -s http://localhost:9093/api/v2/alerts 2>/dev/null | jq -r '.[] | select(.status.state=="active") | .labels.alertname' | sort | uniq)

if [ -n "$ACTIVE_ALERTS" ]; then
    echo -e "${YELLOW}Alertes en cours :${NC}"
    echo "$ACTIVE_ALERTS" | while read alert; do
        echo "  - $alert"
    done
else
    echo -e "${GREEN}Aucune alerte active${NC}"
fi

echo ""

# === UTILISATION DES RESSOURCES ===
echo -e "${BLUE}=== UTILISATION DES RESSOURCES ===${NC}"

# Utilisation CPU/Memoire des conteneurs de monitoring
echo "Conteneurs de monitoring :"
sudo docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" \
    prometheus alertmanager grafana cadvisor 2>/dev/null | tail -n +2 | while read line; do
    echo "  $line"
done

echo ""

# === RESUME ET RECOMMANDATIONS ===
echo -e "${BLUE}=== RESUME ===${NC}"

# Compter les services OK vs DOWN
SERVICES_OK=$(sudo docker ps --filter "name=prometheus" --filter "name=alertmanager" --filter "name=grafana" --filter "name=cadvisor" --format "{{.Names}}" | wc -l)
SERVICES_TOTAL=4

if [ "$SERVICES_OK" -eq "$SERVICES_TOTAL" ]; then
    echo -e "${GREEN}✓ Stack de monitoring completement operationnelle${NC}"
else
    echo -e "${YELLOW}⚠ Stack de monitoring partiellement operationnelle ($SERVICES_OK/$SERVICES_TOTAL)${NC}"
fi

echo ""
echo -e "${BLUE}Acces rapides :${NC}"
echo "  Grafana (dashboards)    : http://localhost:3000"
echo "  Prometheus (metriques)  : http://localhost:9091"
echo "  Alertmanager (alertes)  : http://localhost:9093"
echo "  cAdvisor (conteneurs)   : http://localhost:5000"
echo "  Traefik (reverse proxy) : http://localhost:8080"
echo ""
echo -e "${BLUE}Commandes utiles :${NC}"
echo "  # Relancer ce monitoring"
echo "  ./monitor_stack.sh"
echo ""
echo "  # Tester Alertmanager"
echo "  ./test_alertmanager.sh"
echo ""
echo "  # Voir les logs d'un service"
echo "  sudo docker logs [service_name]"