#!/bin/bash

# Скрипт для создания Kind кластера с Grafana

set -e

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Kind Cluster Setup ===${NC}"

# Проверяем наличие необходимых инструментов
echo -e "${BLUE}Проверка зависимостей...${NC}"

if ! command -v kind &> /dev/null; then
    echo -e "${RED}Ошибка: kind не установлен${NC}"
    echo "Установите kind:"
    echo "  macOS: brew install kind"
    echo "  Linux: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Ошибка: kubectl не установлен${NC}"
    echo "Установите kubectl:"
    echo "  macOS: brew install kubectl"
    echo "  Linux: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo -e "${RED}Ошибка: docker не установлен или не запущен${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Все зависимости установлены${NC}"

# Директория скриптов
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
K8S_DIR="$(dirname "$SCRIPT_DIR")"

# Проверяем, существует ли уже кластер
if kind get clusters 2>/dev/null | grep -q "^grafana-demo$"; then
    echo -e "${YELLOW}Кластер grafana-demo уже существует${NC}"
    read -p "Удалить и пересоздать? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Удаление существующего кластера...${NC}"
        kind delete cluster --name grafana-demo
    else
        echo -e "${YELLOW}Используем существующий кластер${NC}"
        kubectl cluster-info --context kind-grafana-demo
        exit 0
    fi
fi

# Создаем Kind кластер
echo -e "${BLUE}Создание Kind кластера...${NC}"
kind create cluster --config "$K8S_DIR/kind-config.yaml"

echo -e "${GREEN}✓ Kind кластер создан${NC}"

# Ждем готовности кластера
echo -e "${BLUE}Ожидание готовности кластера...${NC}"
kubectl wait --for=condition=Ready nodes --all --timeout=120s

echo -e "${GREEN}✓ Кластер готов${NC}"

# Показываем информацию
echo ""
echo -e "${GREEN}=== Информация о кластере ===${NC}"
kubectl cluster-info --context kind-grafana-demo
echo ""
kubectl get nodes

echo ""
echo -e "${GREEN}✓ Kind кластер успешно создан!${NC}"
echo ""
echo "Следующие шаги:"
echo "  1. Запустите: ./deploy-all.sh"
echo "  2. После деплоя доступ к Grafana: http://localhost:3001"
echo "  3. Логин: admin / Пароль: admin123"
