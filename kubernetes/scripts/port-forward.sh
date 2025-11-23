#!/bin/bash

# Скрипт для проброса портов Grafana из кластера

set -e

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Port Forwarding для Grafana ===${NC}"

# Проверяем наличие кластера
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Ошибка: Kubernetes кластер недоступен${NC}"
    echo "Запустите сначала: ./start-cluster.sh"
    exit 1
fi

# Находим Grafana pod
echo -e "${BLUE}Поиск Grafana pod...${NC}"
POD_NAME=$(kubectl get pods -n grafana-system -l app=grafana -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$POD_NAME" ]; then
    echo -e "${RED}Ошибка: Grafana pod не найден${NC}"
    echo "Убедитесь, что Grafana развернута:"
    echo "  kubectl get pods -n grafana-system"
    exit 1
fi

echo -e "${GREEN}✓ Найден pod: $POD_NAME${NC}"

# Проверяем статус pod
POD_STATUS=$(kubectl get pod "$POD_NAME" -n grafana-system -o jsonpath='{.status.phase}')
if [ "$POD_STATUS" != "Running" ]; then
    echo -e "${YELLOW}Внимание: Pod в статусе $POD_STATUS${NC}"
    echo "Ожидание готовности pod..."
    kubectl wait --for=condition=Ready pod/"$POD_NAME" -n grafana-system --timeout=120s || true
fi

echo ""
echo -e "${GREEN}=== Проброс портов ===${NC}"
echo "  Grafana: http://localhost:3001"
echo ""
echo -e "${YELLOW}Нажмите Ctrl+C для остановки${NC}"
echo ""

# Пробрасываем порт
kubectl port-forward -n grafana-system "pod/$POD_NAME" 3001:3000
