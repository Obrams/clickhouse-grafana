# Примеры использования генератора данных

## Базовое использование

```bash
# Активируем виртуальное окружение
source venv/bin/activate

# Запуск с параметрами по умолчанию (1 млн записей)
python python_generate_script.py --password changeme
```

## Примеры с различными параметрами

### 1. Быстрая генерация небольшого набора данных
```bash
python python_generate_script.py --password changeme --records 10000
```

### 2. Подключение к удаленному ClickHouse
```bash
python python_generate_script.py \
    --host 192.168.1.100 \
    --port 9000 \
    --user admin \
    --password secretpass \
    --database analytics \
    --table events \
    --records 500000
```


## Параметры

| Параметр | Описание | Значение по умолчанию |
|----------|----------|----------------------|
| `--host` | Хост ClickHouse | localhost |
| `--port` | Порт ClickHouse | 9000 |
| `--database` | База данных | default |
| `--user` | Имя пользователя | default |
| `--password` | Пароль | (пустой) |
| `--table` | Имя таблицы | web_events |
| `--recreate` | Пересоздать таблицу | false |
| `--skip-create` | Не создавать таблицу | false |
| `--records` | Количество записей | 1,000,000 |
| `--batch-size` | Размер батча | 10,000 |
| `--time-range` | Временной диапазон (часы) | 1 |

## Структура данных

Таблица содержит следующие поля:
- `event_time` (DateTime) - время события
- `event` (String) - тип события: login, logout, click, purchase, error, view
- `user_id` (UInt32) - ID пользователя (1-10000)
- `latency` (UInt32) - задержка в мс (10-1000)
- `error_type` (String) - тип ошибки или пусто

---

# Работа с Grafana

## Доступ к Grafana

После запуска docker-compose Grafana будет доступна по адресу:
- **URL**: http://localhost:3000
- **Логин**: admin
- **Пароль**: admin123

## Автоматически созданные дашборды

При запуске автоматически создаются 4 дашборда в папке "ClickHouse Analytics":

### 1. Частота событий
**Что показывает**: Общая активность системы
- События по дням (bar chart)
- События по часам (line chart)
- События по типам во времени (stacked area chart)

**Использование**: Анализ пиковых нагрузок, выявление паттернов активности пользователей

### 2. Ошибки по типам
**Что показывает**: Анализ ошибок в системе
- Распределение ошибок по типам (pie chart)
- Статистика ошибок (процент от общего числа событий)
- Динамика ошибок по типам во времени
- Топ-10 пользователей с наибольшим количеством ошибок

**Использование**: Мониторинг качества работы системы, выявление проблемных пользователей

### 3. Latency мониторинг
**Что показывает**: Производительность системы
- Средняя, 95-й перцентиль и максимальная латентность по часам
- Текущие метрики латентности (последний час)
- Топ-20 пользователей по средней латентности
- Распределение латентности (гистограмма)

**Использование**: Мониторинг производительности, выявление узких мест

### 4. Аномалии ошибок
**Что показывает**: Детектирование аномалий
- Количество и процент ошибок в минуту
- Текущая частота ошибок (за 5, 15 и 60 минут)
- Сравнение ошибок с предыдущим часом
- Тепловая карта ошибок по часам и дням недели

**Использование**: Быстрое обнаружение проблем, выявление временных паттернов

## Настроенные алерты

Автоматически настроены 2 алерта:

### High Latency Alert
- **Условие**: Средняя латентность > 2000 мс за последние 5 минут
- **Проверка**: Каждую минуту
- **Срабатывание**: Если условие выполняется 2 минуты подряд
- **Severity**: Warning

### High Error Rate Alert
- **Условие**: Процент ошибок > 5% за последние 5 минут
- **Проверка**: Каждую минуту
- **Срабатывание**: Если условие выполняется 2 минуты подряд
- **Severity**: Critical

## Просмотр алертов

1. Откройте Grafana: http://localhost:3000
2. В левом меню выберите "Alerting" → "Alert rules"
3. Здесь вы увидите все настроенные алерты и их текущее состояние
4. При срабатывании алерта он отобразится с красным значком

## Кастомизация SQL-запросов

Все дашборды используют SQL-запросы к ClickHouse. Вы можете их изменить:

1. Откройте любой дашборд
2. Нажмите на заголовок панели → "Edit"
3. Внизу увидите SQL-запрос с комментариями
4. Измените запрос и нажмите "Apply"

### Полезные функции ClickHouse

#### Временные функции
```sql
toDate(event_time)           -- Группировка по дням
toStartOfHour(event_time)    -- Начало часа
toStartOfMinute(event_time)  -- Начало минуты
toDayOfWeek(event_time)      -- День недели (1-7)
```

#### Агрегатные функции
```sql
count()                      -- Количество записей
avg(latency)                 -- Среднее значение
quantile(0.95)(latency)      -- 95-й перцентиль
max(latency)                 -- Максимум
countIf(error_type != '')    -- Условный подсчет
```

#### Оконные функции
```sql
lagInFrame(value, 1) OVER (ORDER BY time)  -- Значение из предыдущей строки
```

### Макрос Grafana

`$__timeFilter(event_time)` - автоматически подставляет выбранный временной диапазон

Эквивалентно:
```sql
event_time >= '2024-01-01' AND event_time <= '2024-01-02'
```

## Примеры кастомных запросов

### Топ-5 событий по пользователю
```sql
SELECT 
    event,
    count() AS count
FROM web_events
WHERE $__timeFilter(event_time)
  AND user_id = 1234
GROUP BY event
ORDER BY count DESC
LIMIT 5
```

### События по часам дня (0-23)
```sql
SELECT 
    toHour(event_time) AS hour_of_day,
    count() AS events_count
FROM web_events
WHERE $__timeFilter(event_time)
GROUP BY hour_of_day
ORDER BY hour_of_day
```

### Среднее количество событий в день
```sql
SELECT 
    avg(daily_count) AS avg_events_per_day
FROM (
    SELECT 
        toDate(event_time) AS day,
        count() AS daily_count
    FROM web_events
    WHERE $__timeFilter(event_time)
    GROUP BY day
)
```

## Советы по использованию

1. **Выбор временного диапазона**: Используйте селектор времени в правом верхнем углу
2. **Обновление данных**: Включите автообновление (значок "⟳" в правом верхнем углу)
3. **Экспорт дашбордов**: Settings → JSON Model → Copy to Clipboard
4. **Создание новых панелей**: Нажмите "Add panel" в правом верхнем углу дашборда
5. **Переменные**: Можно добавить переменные для фильтрации (например, выбор user_id)

## Устранение проблем

### Дашборды не загрузились
1. Проверьте логи Grafana: `docker logs grafana`
2. Убедитесь, что директории `grafana/` смонтированы корректно
3. Перезапустите контейнер: `docker-compose restart grafana`

### Нет данных в дашбордах
1. Убедитесь, что ClickHouse запущен: `docker ps | grep clickhouse`
2. Проверьте, что данные загружены: 
   ```bash
   source venv/bin/activate
   python python_generate_script.py --password changeme --records 10000
   ```
3. Проверьте подключение datasource в Grafana: Settings → Data sources → ClickHouse

### Алерты не работают
1. Убедитесь, что плагин ClickHouse установлен
2. Проверьте логи Grafana на наличие ошибок
3. В Grafana перейдите в Alerting → Alert rules и проверьте статус

## Дополнительные ресурсы

- [Документация Grafana](https://grafana.com/docs/)
- [ClickHouse SQL Reference](https://clickhouse.com/docs/en/sql-reference/)
- [Grafana ClickHouse Plugin](https://grafana.com/grafana/plugins/grafana-clickhouse-datasource/)
