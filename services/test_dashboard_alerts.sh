#!/bin/bash

# Script de test des alertes basées sur le dashboard
echo "=== TEST DES ALERTES DASHBOARD ==="
echo "Date: $(date)"
echo

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour tester une métrique
test_metric() {
    local name="$1"
    local query="$2"
    local expected="$3"
    
    echo -e "${BLUE}🔍 Test: $name${NC}"
    echo "   Requête: $query"
    
    # Exécuter la requête Prometheus
    result=$(curl -s "http://localhost:9091/api/v1/query?query=$(echo "$query" | sed 's/ /%20/g')" | jq -r '.data.result[0].value[1] // "N/A"' 2>/dev/null)
    
    if [ "$result" != "N/A" ] && [ "$result" != "null" ]; then
        echo -e "   ${GREEN}✓ Résultat: $result $expected${NC}"
    else
        echo -e "   ${RED}✗ Pas de données disponibles${NC}"
    fi
    echo
}

# Fonction pour vérifier les règles d'alertes
check_alert_rules() {
    echo -e "${YELLOW}📋 VERIFICATION DES REGLES D'ALERTES${NC}"
    
    # Vérifier que Prometheus est accessible
    if ! curl -s http://localhost:9091/api/v1/rules >/dev/null 2>&1; then
        echo -e "${RED}✗ Prometheus non accessible sur http://localhost:9091${NC}"
        return 1
    fi
    
    # Compter les groupes de règles
    groups=$(curl -s http://localhost:9091/api/v1/rules | jq '.data.groups | length' 2>/dev/null)
    echo -e "   ${GREEN}✓ Groupes de règles chargés: $groups${NC}"
    
    # Lister les alertes spécifiques au dashboard
    echo -e "${BLUE}📊 Alertes Dashboard configurées:${NC}"
    dashboard_alerts=(
        "LowActiveContainers"
        "ContainerCountAnomaly" 
        "ContainerRecentRestart"
        "LowAverageUptime"
        "ContainerHighCPU"
        "ContainerCriticalCPU"
        "ContainerHighMemory"
        "ContainerHighNetworkRX"
        "ContainerHighNetworkTX"
        "ContainerHighDiskRead"
        "ContainerHighDiskWrite"
        "HighTotalMemoryUsage"
    )
    
    for alert in "${dashboard_alerts[@]}"; do
        if curl -s http://localhost:9091/api/v1/rules | jq -r '.data.groups[].rules[].alert' | grep -q "^$alert$"; then
            echo -e "   ${GREEN}✓ $alert${NC}"
        else
            echo -e "   ${RED}✗ $alert (manquant)${NC}"
        fi
    done
    echo
}

# Fonction pour tester les métriques du dashboard
test_dashboard_metrics() {
    echo -e "${YELLOW}📊 TEST DES METRIQUES DASHBOARD${NC}"
    
    # 1. Nombre de conteneurs actifs
    test_metric "Nombre de conteneurs actifs" \
        "count(container_start_time_seconds{name!=\"\"})" \
        "conteneurs"
    
    # 2. Uptime maximum
    test_metric "Uptime maximum" \
        "max(time() - container_start_time_seconds{name!=\"\"})" \
        "secondes"
    
    # 3. CPU moyen des conteneurs
    test_metric "CPU moyen des conteneurs" \
        "avg(100 * sum by (name) (rate(container_cpu_usage_seconds_total{name!=\"\"}[5m])))" \
        "%"
    
    # 4. Mémoire totale utilisée
    test_metric "Mémoire totale utilisée" \
        "sum(container_memory_working_set_bytes{name!=\"\"}) / 1073741824" \
        "GB"
    
    # 5. Débit réseau entrant total
    test_metric "Débit réseau entrant total" \
        "sum(rate(container_network_receive_bytes_total{name!=\"\"}[5m])) * 8 / 1024 / 1024" \
        "Mbps"
    
    # 6. Débit réseau sortant total
    test_metric "Débit réseau sortant total" \
        "sum(rate(container_network_transmit_bytes_total{name!=\"\"}[5m])) * 8 / 1024 / 1024" \
        "Mbps"
    
    # 7. I/O disque lecture total
    test_metric "I/O disque lecture total" \
        "sum(rate(container_fs_reads_bytes_total{name!=\"\"}[5m]))" \
        "B/s"
    
    # 8. I/O disque écriture total
    test_metric "I/O disque écriture total" \
        "sum(rate(container_fs_writes_bytes_total{name!=\"\"}[5m]))" \
        "B/s"
}

# Fonction pour vérifier les alertes actives
check_active_alerts() {
    echo -e "${YELLOW}🚨 ALERTES ACTIVES${NC}"
    
    if ! curl -s http://localhost:9093/api/v1/alerts >/dev/null 2>&1; then
        echo -e "${RED}✗ Alertmanager non accessible sur http://localhost:9093${NC}"
        return 1
    fi
    
    active_alerts=$(curl -s http://localhost:9093/api/v1/alerts | jq '.data | length' 2>/dev/null)
    
    if [ "$active_alerts" = "0" ]; then
        echo -e "   ${GREEN}✓ Aucune alerte active${NC}"
    else
        echo -e "   ${YELLOW}⚠ $active_alerts alerte(s) active(s):${NC}"
        curl -s http://localhost:9093/api/v1/alerts | jq -r '.data[].labels.alertname' 2>/dev/null | while read alert; do
            echo -e "     ${RED}• $alert${NC}"
        done
    fi
    echo
}

# Fonction pour simuler des alertes
simulate_alerts() {
    echo -e "${YELLOW}🧪 SIMULATION D'ALERTES${NC}"
    
    echo -e "${BLUE}Envoi d'une alerte de test...${NC}"
    
    # Créer une alerte de test basée sur les métriques dashboard
    test_alert='{
        "alerts": [
            {
                "labels": {
                    "alertname": "DashboardTestAlert",
                    "severity": "warning",
                    "category": "test",
                    "name": "test-container"
                },
                "annotations": {
                    "summary": "Test d'\''alerte basée sur le dashboard",
                    "description": "Cette alerte teste la configuration des notifications pour les métriques du dashboard"
                },
                "startsAt": "'$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)'",
                "endsAt": "'$(date -u -d '+5 minutes' +%Y-%m-%dT%H:%M:%S.%3NZ)'"
            }
        ]
    }'
    
    if curl -s -X POST -H "Content-Type: application/json" \
        -d "$test_alert" \
        http://localhost:9093/api/v1/alerts >/dev/null 2>&1; then
        echo -e "   ${GREEN}✓ Alerte de test envoyée${NC}"
    else
        echo -e "   ${RED}✗ Échec de l'envoi de l'alerte de test${NC}"
    fi
    echo
}

# Exécution des tests
main() {
    check_alert_rules
    test_dashboard_metrics
    check_active_alerts
    simulate_alerts
    
    echo -e "${GREEN}=== RESUME ===${NC}"
    echo -e "Dashboard: http://localhost:3000"
    echo -e "Prometheus: http://localhost:9091"
    echo -e "Alertmanager: http://localhost:9093"
    echo
    echo -e "Pour voir la correspondance complète:"
    echo -e "cat dashboard_alert_mapping.md"
}

# Vérifier les dépendances
if ! command -v jq >/dev/null 2>&1; then
    echo -e "${RED}✗ jq n'est pas installé. Installation...${NC}"
    sudo apt-get update && sudo apt-get install -y jq
fi

main "$@"