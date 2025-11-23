#!/bin/bash

# Единый демо-скрипт для запуска всех методов настройки дашбордов Grafana
# Демонстрирует: JSON+Provisioning, Terraform, Grafonnet, Kubernetes Operator

set -e

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Функция для красивого заголовка
print_header() {
    echo ""
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}================================${NC}"
    echo ""
}

# Функция для проверки зависимостей
check_dependency() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}✗ $1 не установлен${NC}"
        return 1
    else
        echo -e "${GREEN}✓ $1 установлен${NC}"
        return 0
    fi
}

# Проверка обязательных зависимостей
print_header "Проверка зависимостей"

REQUIRED_DEPS=("docker" "python3")
OPTIONAL_DEPS=("terraform" "jsonnet" "kind" "kubectl")

echo "Обязательные:"
all_required=true
for dep in "${REQUIRED_DEPS[@]}"; do
    if ! check_dependency $dep; then
        all_required=false
    fi
done

echo ""
echo "Опциональные:"
has_terraform=false
has_jsonnet=false
has_kubernetes=false

if check_dependency "terraform"; then
    has_terraform=true
fi

if check_dependency "jsonnet"; then
    has_jsonnet=true
fi

if check_dependency "kind" && check_dependency "kubectl"; then
    has_kubernetes=true
fi

if [ "$all_required" = false ]; then
    echo -e "${RED}Ошибка: Не все обязательные зависимости установлены${NC}"
    exit 1
fi

# Меню выбора
echo ""
echo -e "${YELLOW}Выберите режим запуска:${NC}"
echo "  1) Базовый (JSON + Provisioning)"
echo "  2) + Terraform"
echo "  3) + Grafonnet"
echo "  4) + Kubernetes"
echo "  5) Всё вместе (Full Demo)"
echo "  6) Только генерация данных"
echo ""
read -p "Выбор (1-6, по умолчанию 5): " choice
choice=${choice:-5}

# Флаги для включения компонентов
RUN_BASE=false
RUN_TERRAFORM=false
RUN_GRAFONNET=false
RUN_KUBERNETES=false
RUN_DATA_ONLY=false

case $choice in
    1)
        RUN_BASE=true
        ;;
    2)
        RUN_BASE=true
        RUN_TERRAFORM=true
        ;;
    3)
        RUN_BASE=true
        RUN_GRAFONNET=true
        ;;
    4)
        RUN_BASE=true
        RUN_KUBERNETES=true
        ;;
    5)
        RUN_BASE=true
        RUN_TERRAFORM=true
        RUN_GRAFONNET=true
        RUN_KUBERNETES=true
        ;;
    6)
        RUN_DATA_ONLY=true
        ;;
    *)
        echo -e "${RED}Неверный выбор${NC}"
        exit 1
        ;;
esac

# Проверка доступности опциональных компонентов
if [ "$RUN_TERRAFORM" = true ] && [ "$has_terraform" = false ]; then
    echo -e "${YELLOW}Terraform не установлен, пропускаем этот шаг${NC}"
    RUN_TERRAFORM=false
fi

if [ "$RUN_GRAFONNET" = true ] && [ "$has_jsonnet" = false ]; then
    echo -e "${YELLOW}Jsonnet не установлен, пропускаем Grafonnet${NC}"
    RUN_GRAFONNET=false
fi

if [ "$RUN_KUBERNETES" = true ] && [ "$has_kubernetes" = false ]; then
    echo -e "${YELLOW}Kind/kubectl не установлены, пропускаем Kubernetes${NC}"
    RUN_KUBERNETES=false
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# ============================================
# БАЗОВАЯ КОНФИГУРАЦИЯ
# ============================================

if [ "$RUN_BASE" = true ]; then
    print_header "1. Базовая инфраструктура (Docker Compose)"
    
    echo "Запуск ClickHouse и Grafana..."
    docker-compose up -d
    
    echo "Ожидание готовности сервисов..."
    sleep 10
    
    echo -e "${GREEN}✓ Инфраструктура запущена${NC}"
    
    # Виртуальное окружение
    print_header "2. Python окружение"
    
    if [ ! -d "venv" ]; then
        echo "Создание виртуального окружения..."
        python3 -m venv venv
    fi
    
    echo "Активация виртуального окружения..."
    source venv/bin/activate
    
    echo "Установка зависимостей..."
    pip install -q -r requirements.txt
    
    echo -e "${GREEN}✓ Python окружение готово${NC}"
    
    # Генерация базовых данных
    print_header "3. Генерация данных: web_events"
    
    echo "Генерация 10,000 событий web_events..."
    python python_generate_script.py --password changeme --records 10000
    
    echo -e "${GREEN}✓ Данные web_events сгенерированы${NC}"
    echo -e "${BLUE}Grafana доступна: http://localhost:3000${NC}"
    echo -e "${BLUE}Логин: admin / Пароль: admin123${NC}"
fi

# ============================================
# TERRAFORM
# ============================================

if [ "$RUN_TERRAFORM" = true ]; then
    print_header "4. Terraform: Server Monitoring"
    
    echo "Генерация данных: server_metrics (50,000 записей)..."
    python generate_server_metrics.py --password changeme --records 50000
    
    echo -e "${GREEN}✓ Данные server_metrics сгенерированы${NC}"
    
    echo "Инициализация Terraform..."
    cd terraform
    
    if [ ! -d ".terraform" ]; then
        terraform init
    fi
    
    echo "Применение Terraform конфигурации..."
    terraform apply -auto-approve
    
    echo ""
    terraform output
    
    cd ..
    
    echo -e "${GREEN}✓ Terraform дашборд создан${NC}"
    echo -e "${BLUE}Папка в Grafana: Terraform Managed${NC}"
fi

# ============================================
# GRAFONNET
# ============================================

if [ "$RUN_GRAFONNET" = true ]; then
    print_header "5. Grafonnet: User Sessions Analytics"
    
    echo "Генерация данных: user_sessions (10,000 сессий)..."
    python generate_user_sessions.py --password changeme --records 10000
    
    echo -e "${GREEN}✓ Данные user_sessions сгенерированы${NC}"
    
    echo "Компиляция Jsonnet в JSON..."
    cd grafonnet
    chmod +x build.sh
    ./build.sh
    cd ..
    
    echo "Перезапуск Grafana для загрузки нового дашборда..."
    docker-compose restart grafana
    
    echo "Ожидание готовности Grafana..."
    sleep 5
    
    echo -e "${GREEN}✓ Grafonnet дашборд создан${NC}"
    echo -e "${BLUE}Дашборд: User Sessions Analytics (Grafonnet)${NC}"
fi

# ============================================
# KUBERNETES
# ============================================

if [ "$RUN_KUBERNETES" = true ]; then
    print_header "6. Kubernetes: API Requests Monitoring"
    
    echo "Генерация данных: api_requests (100,000 запросов)..."
    python generate_api_requests.py --password changeme --records 100000
    
    echo -e "${GREEN}✓ Данные api_requests сгенерированы${NC}"
    
    # Проверяем, существует ли кластер
    if kind get clusters 2>/dev/null | grep -q "^grafana-demo$"; then
        echo -e "${YELLOW}Kind кластер grafana-demo уже существует${NC}"
    else
        echo "Создание Kind кластера..."
        cd kubernetes/scripts
        chmod +x *.sh
        ./start-cluster.sh
        cd ../..
    fi
    
    echo "Установка Grafana Operator и ресурсов..."
    cd kubernetes/scripts
    ./deploy-all.sh
    cd ../..
    
    echo -e "${GREEN}✓ Kubernetes дашборд создан${NC}"
    echo -e "${BLUE}Grafana K8s: http://localhost:3001${NC}"
    echo -e "${BLUE}Логин: admin / Пароль: admin123${NC}"
fi

# ============================================
# ТОЛЬКО ГЕНЕРАЦИЯ ДАННЫХ
# ============================================

if [ "$RUN_DATA_ONLY" = true ]; then
    print_header "Генерация всех данных"
    
    # Активируем venv
    if [ ! -d "venv" ]; then
        python3 -m venv venv
    fi
    source venv/bin/activate
    pip install -q -r requirements.txt
    
    echo "1. web_events (10,000 записей)..."
    python python_generate_script.py --password changeme --records 10000
    
    echo "2. server_metrics (50,000 записей)..."
    python generate_server_metrics.py --password changeme --records 50000
    
    echo "3. user_sessions (10,000 сессий)..."
    python generate_user_sessions.py --password changeme --records 10000
    
    echo "4. api_requests (100,000 запросов)..."
    python generate_api_requests.py --password changeme --records 100000
    
    echo -e "${GREEN}✓ Все данные сгенерированы${NC}"
fi

# ============================================
# ИТОГИ
# ============================================

print_header "Готово!"

echo -e "${GREEN}Демо успешно развернуто!${NC}"
echo ""
echo -e "${CYAN}=== Доступные ресурсы ===${NC}"
echo ""

if [ "$RUN_BASE" = true ] || [ "$RUN_TERRAFORM" = true ] || [ "$RUN_GRAFONNET" = true ]; then
    echo -e "${BLUE}Grafana (Docker Compose):${NC}"
    echo "  URL: http://localhost:3000"
    echo "  Логин: admin"
    echo "  Пароль: admin123"
    echo ""
    
    if [ "$RUN_BASE" = true ]; then
        echo "  Дашборды (JSON + Provisioning):"
        echo "    - Частота событий"
        echo "    - Ошибки по типам"
        echo "    - Latency мониторинг"
        echo "    - Аномалии ошибок"
        echo ""
    fi
    
    if [ "$RUN_TERRAFORM" = true ]; then
        echo "  Дашборды (Terraform):"
        echo "    - Server Monitoring (папка: Terraform Managed)"
        echo ""
    fi
    
    if [ "$RUN_GRAFONNET" = true ]; then
        echo "  Дашборды (Grafonnet):"
        echo "    - User Sessions Analytics"
        echo ""
    fi
fi

if [ "$RUN_KUBERNETES" = true ]; then
    echo -e "${BLUE}Grafana (Kubernetes):${NC}"
    echo "  URL: http://localhost:3001"
    echo "  Логин: admin"
    echo "  Пароль: admin123"
    echo ""
    echo "  Дашборды (K8s Operator):"
    echo "    - API Requests Monitoring"
    echo ""
fi

echo -e "${CYAN}=== Данные в ClickHouse ===${NC}"
echo ""
if [ "$RUN_BASE" = true ]; then
    echo "  - web_events: ~10,000 записей"
fi
if [ "$RUN_TERRAFORM" = true ]; then
    echo "  - server_metrics: ~50,000 записей"
fi
if [ "$RUN_GRAFONNET" = true ]; then
    echo "  - user_sessions: ~10,000 записей"
fi
if [ "$RUN_KUBERNETES" = true ]; then
    echo "  - api_requests: ~100,000 записей"
fi
echo ""

echo -e "${CYAN}=== Полезные команды ===${NC}"
echo ""
echo "  Логи Grafana:"
echo "    docker-compose logs -f grafana"
echo ""
echo "  ClickHouse CLI:"
echo "    docker exec -it clickhouse clickhouse-client --password changeme"
echo ""

if [ "$RUN_KUBERNETES" = true ]; then
    echo "  Kubernetes статус:"
    echo "    kubectl get all -n grafana-system"
    echo ""
    echo "  Удалить Kind кластер:"
    echo "    cd kubernetes/scripts && ./stop-cluster.sh"
    echo ""
fi

if [ "$RUN_TERRAFORM" = true ]; then
    echo "  Terraform команды:"
    echo "    cd terraform && terraform show"
    echo "    cd terraform && terraform destroy"
    echo ""
fi

echo -e "${YELLOW}Документация:${NC}"
echo "  - README.md - общая документация"
echo "  - QUICKSTART.md - быстрый старт"
echo "  - TERRAFORM.md - Terraform подход"
echo "  - GRAFONNET.md - Grafonnet подход"
echo "  - kubernetes/README.md - Kubernetes подход"
echo ""

echo -e "${GREEN}Приятного использования! 🎉${NC}"
