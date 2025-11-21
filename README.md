# ClickHouse + Grafana: Система аналитики и мониторинга

Полнофункциональная система для генерации тестовых данных, хранения в ClickHouse и визуализации в Grafana с настроенными дашбордами и алертами.

## 🚀 Быстрый старт

### 1. Запуск инфраструктуры

```bash
# Запуск ClickHouse и Grafana
docker-compose up -d

# Проверка статуса
docker ps
```

### 2. Создание виртуального окружения и установка зависимостей

```bash
# Создание виртуального окружения (если еще не создано)
python3 -m venv venv

# Активация
source venv/bin/activate

# Установка зависимостей
pip install -r requirements.txt
```

### 3. Генерация тестовых данных

```bash
# Базовая генерация (1 млн записей за последний час)
python python_generate_script.py --password changeme

# Или быстрая генерация для тестирования (10 тыс. записей)
python python_generate_script.py --password changeme --records 10000
```

### 4. Доступ к Grafana

Откройте в браузере: **http://localhost:3000**

- **Логин**: admin
- **Пароль**: admin123

## 📊 Что включено

### Дашборды (автоматически создаются)

1. **Частота событий** - анализ активности по дням/часам/типам
2. **Ошибки по типам** - мониторинг ошибок и проблемных пользователей
3. **Latency мониторинг** - производительность системы (avg, p95, p99)
4. **Аномалии ошибок** - детектирование всплесков и паттернов ошибок

### Алерты (автоматически настроены)

- **High Latency Alert** - срабатывает при latency > 2000 мс
- **High Error Rate Alert** - срабатывает при error_rate > 5%

## 📁 Структура проекта

```
clickhouse-grafana/
├── docker-compose.yaml              # Конфигурация ClickHouse и Grafana
├── python_generate_script.py       # Генератор тестовых данных
├── requirements.txt                 # Python зависимости
├── USAGE.md                         # Подробная документация
├── README.md                        # Этот файл
└── grafana/
    ├── provisioning/
    │   ├── datasources/
    │   │   └── clickhouse.yaml      # Автоподключение к ClickHouse
    │   ├── dashboards/
    │   │   └── default.yaml         # Настройка автозагрузки дашбордов
    │   └── alerting/
    │       └── alerts.yaml          # Конфигурация алертов
    └── dashboards/
        ├── events_frequency.json    # Дашборд частоты событий
        ├── errors_by_type.json      # Дашборд ошибок
        ├── latency_monitoring.json  # Дашборд latency
        └── error_anomalies.json     # Дашборд аномалий
```

## 🛠 Полезные команды

### Генерация данных

```bash
# Пересоздать таблицу и загрузить данные
python python_generate_script.py --password changeme --recreate --records 100000

# Данные за последние 24 часа
python python_generate_script.py --password changeme --time-range 24 --records 1000000

# Только добавить данные (не пересоздавать таблицу)
python python_generate_script.py --password changeme --skip-create --records 50000
```

### Docker

```bash
# Остановка всех контейнеров
docker-compose down

# Остановка с удалением данных
docker-compose down -v

# Просмотр логов
docker-compose logs -f grafana
docker-compose logs -f clickhouse

# Перезапуск контейнера
docker-compose restart grafana
```

### ClickHouse CLI

```bash
# Подключение к ClickHouse
docker exec -it clickhouse clickhouse-client --password changeme

# Примеры запросов
SELECT count() FROM web_events;
SELECT event, count() FROM web_events GROUP BY event;
SELECT avg(latency) FROM web_events;
```

## 📖 Дополнительная информация

Подробная документация находится в файле [USAGE.md](USAGE.md):
- Примеры использования генератора данных
- Структура данных
- Подробное описание дашбордов
- Кастомизация SQL-запросов
- Устранение проблем

## 🔧 Требования

- Docker и Docker Compose
- Python 3.8+
- 2GB+ свободной RAM для Docker

## 📝 Структура данных

Таблица `web_events` содержит:
- `event_time` (DateTime) - время события
- `event` (String) - тип события: login, logout, click, purchase, error, view
- `user_id` (UInt32) - ID пользователя (1-10000)
- `latency` (UInt32) - задержка в мс (10-1000)
- `error_type` (String) - тип ошибки: timeout, server_error, validation_error или пусто

## 🎯 Примеры использования

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

## 🐛 Устранение проблем

### Grafana не показывает данные
1. Проверьте, что ClickHouse запущен: `docker ps`
2. Убедитесь, что данные загружены (см. команды выше)
3. Проверьте datasource в Grafana: Settings → Data sources

### Алерты не работают
1. Убедитесь, что плагин ClickHouse установлен (проверьте логи Grafana)
2. Перейдите в Alerting → Alert rules для проверки статуса
3. При необходимости перезапустите Grafana: `docker-compose restart grafana`

## 📚 Ресурсы

- [ClickHouse Documentation](https://clickhouse.com/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Grafana ClickHouse Plugin](https://grafana.com/grafana/plugins/grafana-clickhouse-datasource/)

## 📄 Лицензия

MIT

