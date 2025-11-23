#!/bin/bash

# Скрипт для установки Grafana Operator и всех ресурсов

set -e

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Grafana Operator Deployment ===${NC}"

# Директория скриптов
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
K8S_DIR="$(dirname "$SCRIPT_DIR")"

# Проверяем наличие кластера
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Ошибка: Kubernetes кластер недоступен${NC}"
    echo "Запустите сначала: ./start-cluster.sh"
    exit 1
fi

echo -e "${GREEN}✓ Кластер доступен${NC}"

# 1. Создаем namespace
echo -e "${BLUE}Создание namespace grafana-system...${NC}"
kubectl apply -f "$K8S_DIR/namespace.yaml"

# 2. Устанавливаем CRDs
echo -e "${BLUE}Установка Custom Resource Definitions...${NC}"
kubectl apply -f "$K8S_DIR/grafana-crds.yaml"

# Ждем готовности CRDs
echo -e "${BLUE}Ожидание готовности CRDs...${NC}"
sleep 3

# 3. Устанавливаем Grafana Operator
echo -e "${BLUE}Установка Grafana Operator...${NC}"
kubectl apply -f "$K8S_DIR/grafana-operator.yaml"

# Ждем готовности оператора
echo -e "${BLUE}Ожидание готовности Grafana Operator...${NC}"
kubectl wait --for=condition=available --timeout=120s \
    deployment/grafana-operator -n grafana-system

echo -e "${GREEN}✓ Grafana Operator установлен${NC}"

# 4. Создаем Grafana инстанс
echo -e "${BLUE}Создание Grafana инстанса...${NC}"
kubectl apply -f "$K8S_DIR/grafana-instance.yaml"

# Ждем готовности Grafana
echo -e "${BLUE}Ожидание готовности Grafana (это может занять несколько минут)...${NC}"
echo -e "${YELLOW}Grafana загружает плагин ClickHouse...${NC}"

# Ждем создания deployment
for i in {1..30}; do
    if kubectl get deployment -n grafana-system -l app=grafana &> /dev/null; then
        break
    fi
    echo -n "."
    sleep 2
done
echo ""

# Ждем готовности deployment
kubectl wait --for=condition=available --timeout=300s \
    deployment -n grafana-system -l app=grafana || true

echo -e "${GREEN}✓ Grafana запущена${NC}"

# 5. Создаем datasource
echo -e "${BLUE}Создание ClickHouse datasource...${NC}"
kubectl apply -f "$K8S_DIR/clickhouse-datasource.yaml"

sleep 2
echo -e "${GREEN}✓ Datasource создан${NC}"

# 6. Создаем dashboard
echo -e "${BLUE}Создание API Requests dashboard...${NC}"
kubectl apply -f "$K8S_DIR/api-requests-dashboard.yaml"

sleep 2
echo -e "${GREEN}✓ Dashboard создан${NC}"

# Показываем статус
echo ""
echo -e "${GREEN}=== Статус развертывания ===${NC}"
kubectl get all -n grafana-system

echo ""
echo -e "${GREEN}=== Ресурсы Grafana ===${NC}"
kubectl get grafana,grafanadatasource,grafanadashboard -n grafana-system

echo ""
echo -e "${GREEN}✓ Все компоненты успешно развернуты!${NC}"
echo ""
echo -e "${BLUE}=== Информация о доступе ===${NC}"
echo "  URL: http://localhost:3001"
echo "  Логин: admin"
echo "  Пароль: admin123"
echo ""
echo "Для проброса портов запустите (если нужно):"
echo "  ./port-forward.sh"
echo ""
echo "Для просмотра логов:"
echo "  kubectl logs -n grafana-system -l app=grafana -f"
echo ""
echo "Для проверки datasource:"
echo "  kubectl describe grafanadatasource -n grafana-system"
