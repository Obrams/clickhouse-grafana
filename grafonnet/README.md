# Grafonnet - Программируемые дашборды Grafana

Grafonnet позволяет создавать дашборды Grafana с помощью кода Jsonnet вместо ручного редактирования JSON.

## Преимущества Grafonnet

- **DRY принцип**: Переиспользование компонентов и конфигураций
- **Версионирование**: Код дашбордов в Git
- **Программируемость**: Циклы, условия, функции
- **Типизация**: Проверка на этапе компиляции
- **Модульность**: Библиотеки и импорты

## Предварительные требования

### Установка Jsonnet

#### macOS
```bash
brew install jsonnet
```

#### Linux (Ubuntu/Debian)
```bash
sudo apt install jsonnet
```

#### Через Go
```bash
go install github.com/google/go-jsonnet/cmd/jsonnet@latest
```

#### Через Python (альтернатива)
```bash
pip install jsonnet
```

### Проверка установки
```bash
jsonnet --version
```

## Структура проекта

```
grafonnet/
├── lib/                          # Библиотеки
│   ├── grafonnet-lib/           # Клон grafonnet-lib (автоматически)
│   └── grafonnet/               # Симлинк на библиотеку
├── dashboards/
│   └── user_sessions.jsonnet    # Исходный код дашборда
├── build.sh                      # Скрипт компиляции
└── README.md                     # Эта документация
```

## Использование

### 1. Первый запуск (установка библиотеки)

Скрипт `build.sh` автоматически загрузит библиотеку grafonnet при первом запуске:

```bash
cd grafonnet
chmod +x build.sh
./build.sh
```

Это выполнит:
- Клонирование grafonnet-lib из GitHub
- Создание необходимых симлинков
- Компиляцию всех .jsonnet файлов в JSON

### 2. Компиляция дашбордов

После изменения .jsonnet файлов запустите:

```bash
./build.sh
```

Это скомпилирует все дашборды из `dashboards/*.jsonnet` в `../grafana/dashboards/*.json`

### 3. Применение изменений в Grafana

После компиляции перезапустите Grafana:

```bash
cd ..
docker-compose restart grafana
```

Дашборд появится в папке "ClickHouse Analytics".

## Создаваемый дашборд

### User Sessions Analytics (Grafonnet)

Дашборд для анализа пользовательских сессий из таблицы `user_sessions`:

**Панели:**

1. **Статистические панели (верхний ряд):**
   - Average Session Duration - средняя длительность
   - Total Sessions - всего сессий за 24ч
   - Avg Pages per Session - среднее количество страниц
   - Unique Users - уникальных пользователей

2. **Sessions Over Time** - сессии во времени по типам устройств (time series)

3. **Device Distribution** - распределение по устройствам (pie chart)

4. **Sessions Heatmap** - тепловая карта активности по часам (heatmap)

5. **Top Countries by Sessions** - топ стран по сессиям с метриками (table)

6. **Activity by Hour** - активность по часам дня (bar gauge)

7. **Session Duration Trend** - тренд длительности сессий (avg, median, p95)

**Характеристики:**
- Период: последние 24 часа
- Автообновление: каждую минуту
- Теги: grafonnet, sessions, users, analytics

## Редактирование дашборда

Откройте файл `dashboards/user_sessions.jsonnet`:

```jsonnet
// Импорт библиотек
local grafana = import '../lib/grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local statPanel = grafana.statPanel;

// Создание дашборда
dashboard.new(
  'My Dashboard',
  tags=['custom'],
)
.addPanel(
  statPanel.new(
    'My Panel',
    datasource='ClickHouse',
  )
  { gridPos: { x: 0, y: 0, w: 6, h: 6 } },
)
```

## Примеры кода

### Создание простого stat panel

```jsonnet
local grafana = import '../lib/grafonnet/grafana.libsonnet';
local statPanel = grafana.statPanel;

statPanel.new(
  'Total Count',
  datasource='ClickHouse',
  unit='short',
  colorMode='value',
)
.addTarget({
  rawSql: 'SELECT count() as value FROM my_table',
  format: 'table',
})
```

### Создание time series с несколькими запросами

```jsonnet
local grafana = import '../lib/grafonnet/grafana.libsonnet';

{
  type: 'timeseries',
  title: 'My Time Series',
  targets: [
    {
      refId: 'A',
      rawSql: 'SELECT time, value FROM table1',
    },
    {
      refId: 'B',
      rawSql: 'SELECT time, value FROM table2',
    },
  ],
}
```

### Использование циклов для создания панелей

```jsonnet
local grafana = import '../lib/grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;

local metrics = ['cpu', 'memory', 'disk'];

dashboard.new('Multi Metrics')
.addPanels([
  {
    title: metric,
    type: 'timeseries',
    gridPos: { x: 0, y: i * 8, w: 24, h: 8 },
  }
  for i, metric in std.enumerate(metrics)
])
```

### Создание переиспользуемых функций

```jsonnet
local makeStatPanel(title, query, unit='short') = {
  type: 'stat',
  title: title,
  targets: [{
    rawSql: query,
    format: 'table',
  }],
  fieldConfig: {
    defaults: {
      unit: unit,
    },
  },
};

// Использование
makeStatPanel('CPU Usage', 'SELECT avg(cpu) FROM metrics', 'percent')
```

## Продвинутые возможности

### Темплейтинг и переменные

```jsonnet
local template = grafana.template;

dashboard.new('My Dashboard')
.addTemplate(
  template.datasource(
    'datasource',
    'grafana-clickhouse-datasource',
    'ClickHouse',
  )
)
.addTemplate(
  template.new(
    'server',
    '$datasource',
    'SELECT DISTINCT server_name FROM metrics',
  )
)
```

### Условная логика

```jsonnet
local isDev = std.extVar('environment') == 'dev';

dashboard.new(
  if isDev then 'Dashboard (DEV)' else 'Dashboard'
)
.addPanel(
  if isDev then devPanel else prodPanel
)
```

### Импорт собственных библиотек

Создайте `lib/custom.libsonnet`:

```jsonnet
{
  myColors:: {
    primary: '#1f77b4',
    secondary: '#ff7f0e',
  },
  
  makeAlert(name, expr):: {
    name: name,
    expression: expr,
    frequency: '1m',
  },
}
```

Используйте:

```jsonnet
local custom = import '../lib/custom.libsonnet';

// Используем цвета
color: custom.myColors.primary
```

## Отладка

### Проверка синтаксиса без компиляции

```bash
jsonnet -J lib dashboards/user_sessions.jsonnet > /dev/null
```

### Вывод в консоль для отладки

```bash
jsonnet -J lib dashboards/user_sessions.jsonnet | jq '.'
```

### Форматирование кода

```bash
jsonnetfmt -i dashboards/user_sessions.jsonnet
```

## Интеграция с CI/CD

### GitHub Actions

```yaml
name: Build Dashboards

on:
  push:
    paths:
      - 'grafonnet/**'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install jsonnet
        run: |
          sudo apt-get update
          sudo apt-get install -y jsonnet
      
      - name: Build dashboards
        run: |
          cd grafonnet
          ./build.sh
      
      - name: Commit compiled dashboards
        run: |
          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
          git add grafana/dashboards/*.json
          git commit -m "Auto-compile dashboards" || true
          git push
```

## Сравнение: JSON vs Grafonnet

### JSON (традиционный способ)
```json
{
  "panels": [
    {
      "id": 1,
      "type": "stat",
      "title": "CPU Server 1",
      "targets": [{"rawSql": "SELECT avg(cpu) FROM metrics WHERE server='server1'"}]
    },
    {
      "id": 2,
      "type": "stat",
      "title": "CPU Server 2",
      "targets": [{"rawSql": "SELECT avg(cpu) FROM metrics WHERE server='server2'"}]
    }
  ]
}
```

### Grafonnet (программируемый способ)
```jsonnet
local servers = ['server1', 'server2'];

{
  panels: [
    {
      id: i + 1,
      type: 'stat',
      title: 'CPU ' + server,
      targets: [{
        rawSql: "SELECT avg(cpu) FROM metrics WHERE server='%s'" % server
      }]
    }
    for i, server in std.enumerate(servers)
  ]
}
```

## Troubleshooting

### Ошибка: "jsonnet: command not found"
Установите jsonnet (см. раздел "Установка Jsonnet")

### Ошибка: "RUNTIME ERROR: couldn't open import"
Проверьте путь к библиотеке:
```bash
ls -la lib/grafonnet
./build.sh  # Скрипт автоматически загрузит библиотеку
```

### Дашборд не появляется в Grafana
1. Проверьте компиляцию: `./build.sh`
2. Проверьте JSON файл: `cat ../grafana/dashboards/user_sessions.json`
3. Перезапустите Grafana: `docker-compose restart grafana`
4. Проверьте логи: `docker-compose logs grafana`

### Синтаксическая ошибка в Jsonnet
Используйте `jsonnet` напрямую для диагностики:
```bash
jsonnet -J lib dashboards/user_sessions.jsonnet
```

## Полезные ссылки

- [Grafonnet GitHub](https://github.com/grafana/grafonnet-lib)
- [Jsonnet Documentation](https://jsonnet.org/)
- [Jsonnet Tutorial](https://jsonnet.org/learning/tutorial.html)
- [Grafana Dashboard JSON Model](https://grafana.com/docs/grafana/latest/developers/http_api/dashboard/)
- [Grafonnet Examples](https://github.com/grafana/grafonnet-lib/tree/master/examples)

## Следующие шаги

1. Изучите примеры в `grafonnet-lib/examples/`
2. Создайте свои переиспользуемые библиотеки
3. Настройте автоматическую компиляцию в CI/CD
4. Экспериментируйте с темплейтингом и переменными
