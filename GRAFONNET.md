# Grafonnet - Программируемые дашборды Grafana

> 📖 **Полная документация**: [grafonnet/README.md](grafonnet/README.md)

## Быстрый старт

```bash
# 1. Генерация тестовых данных
python generate_user_sessions.py --password changeme --records 10000

# 2. Установка jsonnet (если не установлен)
# macOS:
brew install jsonnet
# Linux:
sudo apt install jsonnet

# 3. Компиляция дашборда
cd grafonnet
./build.sh

# 4. Перезапуск Grafana
cd ..
docker-compose restart grafana
```

## Что создается

- **Дашборд**: "User Sessions Analytics (Grafonnet)"
- **Источник данных**: user_sessions
- **Формат**: Jsonnet → JSON

## Панели дашборда

1. Average Session Duration (stat)
2. Total Sessions (stat)
3. Avg Pages per Session (stat)
4. Unique Users (stat)
5. Sessions Over Time (time series)
6. Device Distribution (pie chart)
7. Sessions Heatmap (heatmap)
8. Top Countries by Sessions (table)
9. Activity by Hour (bar gauge)
10. Session Duration Trend (time series)

## Основные команды

```bash
# Компиляция всех дашбордов
cd grafonnet
./build.sh

# Компиляция конкретного файла
jsonnet -J lib dashboards/user_sessions.jsonnet > output.json

# Форматирование кода
jsonnetfmt -i dashboards/user_sessions.jsonnet

# Проверка синтаксиса
jsonnet -J lib dashboards/user_sessions.jsonnet > /dev/null
```

## Пример кода

```jsonnet
local grafana = import '../lib/grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local statPanel = grafana.statPanel;

dashboard.new(
  'My Dashboard',
  tags=['custom'],
  time_from='now-24h',
)
.addPanel(
  statPanel.new(
    'Total Count',
    datasource='ClickHouse',
    unit='short',
  )
  .addTarget({
    rawSql: 'SELECT count() FROM my_table',
    format: 'table',
  })
  { gridPos: { x: 0, y: 0, w: 6, h: 6 } },
)
```

## Структура

```
grafonnet/
├── lib/                      # Библиотеки
│   └── grafonnet/           # Grafonnet library
├── dashboards/
│   └── user_sessions.jsonnet # Исходный код
├── build.sh                  # Скрипт компиляции
└── README.md                 # Детальная документация
```

## Преимущества

✅ **DRY принцип** - переиспользование кода  
✅ **Программируемость** - циклы, условия, функции  
✅ **Типизация** - проверка на этапе компиляции  
✅ **Модульность** - библиотеки и импорты  
✅ **Генерация** - создание похожих дашбордов в цикле  

## Пример: Генерация панелей в цикле

```jsonnet
local metrics = ['cpu', 'memory', 'disk'];

dashboard.new('Multi Metrics')
.addPanels([
  {
    title: metric,
    type: 'timeseries',
    gridPos: { x: 0, y: i * 8, w: 24, h: 8 },
    targets: [{
      rawSql: 'SELECT time, %s FROM metrics' % metric
    }]
  }
  for i, metric in std.enumerate(metrics)
])
```

## Пример: Переиспользуемые функции

```jsonnet
local makeStatPanel(title, query, unit='short') = {
  type: 'stat',
  title: title,
  targets: [{
    rawSql: query,
    format: 'table',
  }],
  fieldConfig: {
    defaults: { unit: unit },
  },
};

// Использование
makeStatPanel('CPU Usage', 'SELECT avg(cpu) FROM metrics', 'percent')
makeStatPanel('Memory', 'SELECT avg(memory) FROM metrics', 'bytes')
```

## Сравнение: JSON vs Grafonnet

### Традиционный JSON
```json
{
  "panels": [
    {"id": 1, "title": "CPU Server 1", "targets": [...]},
    {"id": 2, "title": "CPU Server 2", "targets": [...]},
    {"id": 3, "title": "CPU Server 3", "targets": [...]}
  ]
}
```

### Grafonnet (компактно)
```jsonnet
local servers = ['server1', 'server2', 'server3'];

{
  panels: [
    {
      id: i + 1,
      title: 'CPU ' + server,
      targets: [{rawSql: "SELECT cpu FROM metrics WHERE server='%s'" % server}]
    }
    for i, server in std.enumerate(servers)
  ]
}
```

## Интеграция с CI/CD

```yaml
# .github/workflows/grafonnet.yml
name: Build Dashboards
on:
  push:
    paths: ['grafonnet/**']

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install jsonnet
        run: sudo apt-get install -y jsonnet
      
      - name: Build dashboards
        run: |
          cd grafonnet
          ./build.sh
      
      - name: Commit compiled dashboards
        run: |
          git config user.name "GitHub Actions"
          git add grafana/dashboards/*.json
          git commit -m "Auto-compile dashboards" || true
          git push
```

## Troubleshooting

### jsonnet: command not found
```bash
# macOS
brew install jsonnet

# Linux
sudo apt install jsonnet

# Или через Python
pip install jsonnet
```

### Ошибка импорта библиотеки
```bash
# Скрипт build.sh автоматически загрузит библиотеку
./build.sh
```

### Дашборд не появляется
```bash
# 1. Проверьте компиляцию
./build.sh

# 2. Проверьте JSON
cat ../grafana/dashboards/user_sessions.json | jq '.'

# 3. Перезапустите Grafana
docker-compose restart grafana
```

## Дополнительные возможности

### Темплейтинг
```jsonnet
local template = grafana.template;

dashboard.new('My Dashboard')
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
```

### Импорт библиотек
```jsonnet
// lib/custom.libsonnet
{
  colors:: {
    primary: '#1f77b4',
    secondary: '#ff7f0e',
  },
}

// dashboard.jsonnet
local custom = import '../lib/custom.libsonnet';
color: custom.colors.primary
```

## Дополнительные материалы

- 📚 [Jsonnet Tutorial](https://jsonnet.org/learning/tutorial.html)
- 📚 [Grafonnet GitHub](https://github.com/grafana/grafonnet-lib)
- 📚 [Grafonnet Examples](https://github.com/grafana/grafonnet-lib/tree/master/examples)
- 📁 [Полная документация](grafonnet/README.md)

## Следующие шаги

1. Изучите [полную документацию](grafonnet/README.md)
2. Создайте свой дашборд на Jsonnet
3. Попробуйте генерацию панелей в цикле
4. Создайте переиспользуемую библиотеку компонентов
5. Настройте автоматическую компиляцию в CI/CD
