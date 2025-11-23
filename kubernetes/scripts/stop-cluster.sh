#!/bin/bash

# Скрипт для удаления Kind кластера

set -e

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Kind Cluster Deletion ===${NC}"

# Проверяем, существует ли кластер
if ! kind get clusters 2>/dev/null | grep -q "^grafana-demo$"; then
    echo -e "${YELLOW}Кластер grafana-demo не найден${NC}"
    exit 0
fi

echo -e "${YELLOW}Это удалит кластер grafana-demo и все его ресурсы${NC}"
read -p "Продолжить? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Отменено${NC}"
    exit 0
fi

# Удаляем кластер
echo -e "${BLUE}Удаление Kind кластера...${NC}"
kind delete cluster --name grafana-demo

echo -e "${GREEN}✓ Кластер grafana-demo удален${NC}"

# Проверяем оставшиеся кластеры
remaining=$(kind get clusters 2>/dev/null | wc -l)
if [ $remaining -gt 0 ]; then
    echo ""
    echo "Оставшиеся Kind кластеры:"
    kind get clusters
else
    echo ""
    echo "Kind кластеров не осталось"
fi
