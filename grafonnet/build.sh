#!/bin/bash

# Скрипт для компиляции Jsonnet в JSON дашборды Grafana

set -e

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Grafonnet Build Script ===${NC}"

# Проверяем наличие jsonnet
if ! command -v jsonnet &> /dev/null; then
    echo -e "${RED}Ошибка: jsonnet не установлен${NC}"
    echo "Установите jsonnet:"
    echo "  macOS: brew install jsonnet"
    echo "  Linux: sudo apt install jsonnet"
    echo "  или используйте Python: pip install jsonnet"
    exit 1
fi

# Директории
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DASHBOARDS_DIR="$SCRIPT_DIR/dashboards"
OUTPUT_DIR="$SCRIPT_DIR/../grafana/dashboards"
LIB_DIR="$SCRIPT_DIR/lib"

# Проверяем наличие grafonnet lib
if [ ! -d "$LIB_DIR/grafonnet" ]; then
    echo -e "${BLUE}Загрузка grafonnet библиотеки...${NC}"
    mkdir -p "$LIB_DIR"
    cd "$LIB_DIR"
    
    # Клонируем grafonnet-lib
    if [ ! -d "grafonnet-lib" ]; then
        git clone https://github.com/grafana/grafonnet-lib.git
    fi
    
    # Создаем симлинк
    ln -sf grafonnet-lib/grafonnet grafonnet
    
    cd "$SCRIPT_DIR"
    echo -e "${GREEN}✓ Библиотека grafonnet загружена${NC}"
fi

# Создаем output директорию если нет
mkdir -p "$OUTPUT_DIR"

echo -e "${BLUE}Компиляция дашбордов...${NC}"

# Компилируем все .jsonnet файлы
compiled=0
failed=0

for jsonnet_file in "$DASHBOARDS_DIR"/*.jsonnet; do
    if [ -f "$jsonnet_file" ]; then
        filename=$(basename "$jsonnet_file" .jsonnet)
        output_file="$OUTPUT_DIR/${filename}.json"
        
        echo -n "  Компилируем $filename.jsonnet... "
        
        if jsonnet -J "$LIB_DIR" "$jsonnet_file" > "$output_file" 2>/dev/null; then
            echo -e "${GREEN}✓${NC}"
            compiled=$((compiled + 1))
        else
            echo -e "${RED}✗${NC}"
            failed=$((failed + 1))
            # Показываем ошибку
            jsonnet -J "$LIB_DIR" "$jsonnet_file" 2>&1 | sed 's/^/    /'
        fi
    fi
done

echo ""
echo -e "${BLUE}=== Результаты ===${NC}"
echo -e "  Успешно: ${GREEN}$compiled${NC}"
if [ $failed -gt 0 ]; then
    echo -e "  Ошибки:  ${RED}$failed${NC}"
fi

if [ $failed -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Все дашборды успешно скомпилированы!${NC}"
    echo -e "  Файлы находятся в: $OUTPUT_DIR"
    echo ""
    echo "Чтобы применить изменения в Grafana:"
    echo "  docker-compose restart grafana"
    exit 0
else
    echo ""
    echo -e "${RED}✗ Есть ошибки компиляции${NC}"
    exit 1
fi
