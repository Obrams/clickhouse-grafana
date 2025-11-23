# ClickHouse + Grafana: Система аналитики и мониторинга

Полнофункциональная система для генерации тестовых данных, хранения в ClickHouse и визуализации в Grafana с настроенными дашбордами и алертами.

## Быстрый старт

### 1. Запуск инфраструктуры

```bash
docker-compose up -d
docker ps
```

### 2. Создание виртуального окружения и установка зависимостей

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 3. Генерация тестовых данных

```bash
python python_generate_script.py --password changeme
python python_generate_script.py --password changeme --records 10000
```

### 4. Доступ к Grafana

Откройте в браузере: **http://localhost:3000**

- **Логин**: admin
- **Пароль**: admin123

## Что включено

### Дашборды

1. **Частота событий** - анализ активности по дням/часам/типам
2. **Ошибки по типам** - мониторинг ошибок и проблемных пользователей
3. **Latency мониторинг** - производительность системы (avg, p95, p99)
4. **Аномалии ошибок** - детектирование всплесков и паттернов ошибок

### Алерты

- **High Latency Alert** - срабатывает при latency > 2000 мс
- **High Error Rate Alert** - срабатывает при error_rate > 5%

## Структура проекта

```
clickhouse-grafana/
├── docker-compose.yaml
├── python_generate_script.py
├── requirements.txt
├── README.md
└── grafana/
    ├── provisioning/
    │   ├── datasources/
    │   │   └── clickhouse.yaml
    │   ├── dashboards/
    │   │   └── default.yaml
    │   └── alerting/
    │       └── alerts.yaml
    └── dashboards/
        ├── events_frequency.json
        ├── errors_by_type.json
        ├── latency_monitoring.json
        └── error_anomalies.json
```

## Полезные команды

### Генерация данных

```bash
python python_generate_script.py --password changeme --recreate --records 100000
python python_generate_script.py --password changeme --time-range 24 --records 1000000
python python_generate_script.py --password changeme --skip-create --records 50000
```

### Docker

```bash
docker-compose down
docker-compose down -v
docker-compose logs -f grafana
docker-compose logs -f clickhouse
docker-compose restart grafana
```

### ClickHouse CLI

```bash
docker exec -it clickhouse clickhouse-client --password changeme

SELECT count() FROM web_events;
SELECT event, count() FROM web_events GROUP BY event;
SELECT avg(latency) FROM web_events;
```

## Требования

- Docker и Docker Compose
- Python 3.8+
- 2GB+ свободной RAM для Docker

## Структура данных

Таблица `web_events` содержит:
- `event_time` (DateTime) - время события
- `event` (String) - тип события: login, logout, click, purchase, error, view
- `user_id` (UInt32) - ID пользователя (1-10000)
- `latency` (UInt32) - задержка в мс (10-1000)
- `error_type` (String) - тип ошибки: timeout, server_error, validation_error или пусто

## Примеры использования

### Мониторинг производительности
1. Откройте дашборд "Latency мониторинг"
2. Проверьте метрики P95 и Max latency
3. Посмотрите топ пользователей с высокой латентностью

### Анализ ошибок
1. Откройте дашборд "Ошибки по типам"
2. Проверьте процент ошибок (должен быть < 5%)
3. Изучите динамику ошибок по времени

### Детектирование аномалий
1. Откройте дашборд "Аномалии ошибок"
2. Проверьте тепловую карту для выявления паттернов
3. Сравните текущие значения с предыдущими периодами

## Устранение проблем

### Grafana не показывает данные
1. Проверьте, что ClickHouse запущен: `docker ps`
2. Убедитесь, что данные загружены (см. команды выше)
3. Проверьте datasource в Grafana: Settings → Data sources

### Алерты не работают
1. Убедитесь, что плагин ClickHouse установлен (проверьте логи Grafana)
2. Перейдите в Alerting → Alert rules для проверки статуса
3. При необходимости перезапустите Grafana: `docker-compose restart grafana`

## Дополнительные способы настройки дашбордов

Помимо JSON + provisioning, проект демонстрирует 3 дополнительных метода:

### Способ 4: Terraform (Infrastructure as Code)

**Дашборд**: Server Monitoring  
**Данные**: server_metrics (метрики 10 серверов)

```bash
# Генерация данных
python generate_server_metrics.py --password changeme --records 50000

# Применение через Terraform
cd terraform
terraform init
terraform apply
```

**Преимущества**:
- Полная автоматизация через IaC
- Версионирование инфраструктуры
- CI/CD интеграция
- Multi-environment поддержка

📖 Подробная документация: [TERRAFORM.md](TERRAFORM.md)

### Способ 6: Grafonnet (Программируемые дашборды)

**Дашборд**: User Sessions Analytics  
**Данные**: user_sessions (сессии пользователей)

```bash
# Генерация данных
python generate_user_sessions.py --password changeme --records 10000

# Компиляция Jsonnet в JSON
cd grafonnet
python build.py

# Перезапуск Grafana
cd ..
docker-compose restart grafana
```

**Преимущества**:
- DRY (Don't Repeat Yourself)
- Переиспользование компонентов
- Генерация дашбордов в цикле
- Типобезопасность

📖 Подробная документация: [GRAFONNET.md](GRAFONNET.md)

### Способ 8: Kubernetes Operator (GitOps)

**Дашборд**: API Requests Monitoring  
**Данные**: api_requests (API запросы)

```bash
# Генерация данных
python generate_api_requests.py --password changeme --records 100000

# Создание Kind кластера
cd kubernetes/scripts
./start-cluster.sh

# Деплой Grafana Operator
./deploy-all.sh
```

**Доступ**: http://localhost:3001 (порт 3001!)

**Преимущества**:
- Декларативное управление
- GitOps подход
- Kubernetes-native
- Auto-healing

📖 Подробная документация: [kubernetes/README.md](kubernetes/README.md)

## Сравнение методов

| Метод | Сложность | Автоматизация | Версионирование | CI/CD | Использование |
|-------|-----------|---------------|-----------------|-------|---------------|
| **JSON + Provisioning** | ⭐ | ⭐⭐ | ✅ | ⚠️ | Начинающие |
| **Terraform** | ⭐⭐ | ⭐⭐⭐ | ✅ | ✅ | IaC команды |
| **Grafonnet** | ⭐⭐⭐ | ⭐⭐⭐ | ✅ | ✅ | Разработчики |
| **Kubernetes Operator** | ⭐⭐⭐⭐ | ⭐⭐⭐ | ✅ | ✅ | K8s окружения |

## Единый демо-скрипт

Запустить все методы сразу:

```bash
./demo.sh
```

## Генераторы данных

Проект включает 4 генератора тестовых данных:

| Скрипт | Таблица | Описание | Записей по умолчанию |
|--------|---------|----------|----------------------|
| `python_generate_script.py` | web_events | События веб-приложения | 1,000 |
| `generate_server_metrics.py` | server_metrics | Метрики серверов (CPU, RAM) | 50,000 |
| `generate_user_sessions.py` | user_sessions | Сессии пользователей | 10,000 |
| `generate_api_requests.py` | api_requests | API запросы с метриками | 100,000 |

## Docker Compose профили

```bash
# Базовая конфигурация (ClickHouse + Grafana)
docker-compose up -d

# С Terraform контейнером
docker-compose --profile terraform up -d

# Все сервисы
docker-compose --profile all up -d
```

## Структура проекта (обновлено)

```
clickhouse-grafana/
├── docker-compose.yaml           # Docker Compose с профилями
├── python_generate_script.py    # Генератор web_events
├── generate_server_metrics.py   # Генератор server_metrics
├── generate_user_sessions.py    # Генератор user_sessions
├── generate_api_requests.py     # Генератор api_requests
├── requirements.txt              # Python зависимости
├── demo.sh                       # Единый демо-скрипт
├── README.md                     # Эта документация
├── QUICKSTART.md                 # Быстрый старт
├── TERRAFORM.md                  # Документация Terraform
├── GRAFONNET.md                  # Документация Grafonnet
├── grafana/
│   ├── provisioning/
│   │   ├── datasources/
│   │   │   └── clickhouse.yaml
│   │   ├── dashboards/
│   │   │   └── default.yaml
│   │   └── alerting/
│   │       └── alerts.yaml
│   └── dashboards/              # JSON дашборды
│       ├── events_frequency.json
│       ├── errors_by_type.json
│       ├── latency_monitoring.json
│       ├── error_anomalies.json
│       └── user_sessions_grafonnet.json  # Из Grafonnet
├── terraform/                   # Terraform конфигурация
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── dashboards.tf
│   ├── terraform.tfvars
│   └── README.md
├── grafonnet/                   # Grafonnet дашборды
│   ├── lib/
│   │   └── grafonnet/
│   │       └── grafana.libsonnet
│   ├── dashboards/
│   │   └── user_sessions.jsonnet
│   ├── build.sh
│   ├── build.py
│   └── README.md
└── kubernetes/                  # Kubernetes манифесты
    ├── kind-config.yaml
    ├── grafana-operator/
    │   ├── namespace.yaml
    │   └── grafana-instance.yaml
    ├── datasources/
    │   └── clickhouse-datasource.yaml
    ├── dashboards/
    │   └── api-requests-dashboard.yaml
    ├── scripts/
    │   ├── start-cluster.sh
    │   ├── stop-cluster.sh
    │   ├── deploy-all.sh
    │   ├── status.sh
    │   └── port-forward.sh
    └── README.md
```

## Когда использовать какой метод?

### JSON + Provisioning
✅ Простые дашборды  
✅ Прототипирование  
✅ Небольшие команды  
✅ Начинающие пользователи  

### Terraform
✅ IaC практики в команде  
✅ Multi-environment (dev/staging/prod)  
✅ Интеграция с другой инфраструктурой  
✅ Нужен полный контроль версий  

### Grafonnet
✅ Много похожих дашбордов  
✅ Динамическая генерация  
✅ Переиспользуемые компоненты  
✅ Команда разработчиков  

### Kubernetes Operator
✅ Работа в Kubernetes  
✅ GitOps workflow  
✅ Namespace isolation  
✅ Большая инфраструктура  

## Ресурсы

### Документация проекта
- [Быстрый старт](QUICKSTART.md)
- [Terraform подход](TERRAFORM.md)
- [Grafonnet подход](GRAFONNET.md)
- [Kubernetes Operator](kubernetes/README.md)

### Внешние ресурсы
- [ClickHouse Documentation](https://clickhouse.com/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Grafana ClickHouse Plugin](https://grafana.com/grafana/plugins/grafana-clickhouse-datasource/)
- [Terraform Grafana Provider](https://registry.terraform.io/providers/grafana/grafana/latest/docs)
- [Grafonnet Library](https://github.com/grafana/grafonnet-lib)
- [Grafana Operator](https://grafana.github.io/grafana-operator/)
- [Kind Documentation](https://kind.sigs.k8s.io/)
