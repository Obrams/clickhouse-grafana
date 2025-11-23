# Terraform для управления дашбордами Grafana

Этот модуль Terraform позволяет управлять дашбордами Grafana как кодом (Infrastructure as Code).

## Предварительные требования

1. Terraform >= 1.5
2. Запущенный Grafana (через docker-compose)
3. Доступ к Grafana API

## Установка Terraform

### macOS
```bash
brew install terraform
```

### Linux
```bash
wget https://releases.hashicorp.com/terraform/1.6.5/terraform_1.6.5_linux_amd64.zip
unzip terraform_1.6.5_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

### Проверка установки
```bash
terraform version
```

## Использование

### 1. Инициализация Terraform
```bash
cd terraform
terraform init
```

Эта команда:
- Скачивает провайдер Grafana
- Инициализирует рабочую директорию
- Создает файл блокировки зависимостей

### 2. Проверка конфигурации
```bash
terraform validate
```

### 3. Планирование изменений
```bash
terraform plan
```

Покажет, какие ресурсы будут созданы:
- Папка "Terraform Managed"
- Дашборд "Server Monitoring (Terraform)"

### 4. Применение изменений
```bash
terraform apply
```

Введите `yes` для подтверждения.

### 5. Просмотр созданных ресурсов
```bash
terraform show
```

### 6. Получение outputs
```bash
terraform output
terraform output server_monitoring_dashboard_url
```

## Структура файлов

- `main.tf` - основная конфигурация и провайдер Grafana
- `variables.tf` - объявление переменных
- `terraform.tfvars` - значения переменных
- `dashboards.tf` - определение дашборда Server Monitoring
- `outputs.tf` - выходные значения (URLs, IDs)

## Создаваемый дашборд

### Server Monitoring (Terraform)

Дашборд для мониторинга серверных метрик из таблицы `server_metrics`:

**Панели:**
1. **CPU Utilization by Server** - использование CPU по серверам (time series)
2. **RAM Usage by Server** - использование RAM по серверам (time series)
3. **Average Disk Usage** - средний объем диска (gauge)
4. **Current Avg CPU** - текущее среднее CPU (stat)
5. **Network Traffic by Server** - сетевой трафик (bar chart)
6. **Top 5 Servers by Load** - топ 5 серверов по нагрузке (table)

**Характеристики:**
- Период: последние 24 часа
- Автообновление: каждые 30 секунд
- Интервал агрегации: 5 минут
- Теги: terraform, servers, infrastructure

## Изменение дашборда

Для изменения дашборда:

1. Отредактируйте `dashboards.tf`
2. Запустите `terraform plan` для проверки
3. Примените изменения: `terraform apply`

## Удаление ресурсов

Для удаления всех созданных ресурсов:

```bash
terraform destroy
```

**Внимание:** Это удалит папку и дашборд из Grafana!

## Переменные окружения

Вместо файла `terraform.tfvars` можно использовать переменные окружения:

```bash
export TF_VAR_grafana_url="http://localhost:3000"
export TF_VAR_grafana_auth="admin:admin123"
terraform apply
```

## Импорт существующих дашбордов

Если дашборд уже существует в Grafana, его можно импортировать:

```bash
# Получить ID дашборда из Grafana UI
terraform import grafana_dashboard.server_monitoring <dashboard_id>
```

## Работа с несколькими окружениями

### Development
```bash
terraform workspace new dev
terraform workspace select dev
terraform apply -var-file="dev.tfvars"
```

### Production
```bash
terraform workspace new prod
terraform workspace select prod
terraform apply -var-file="prod.tfvars"
```

## Troubleshooting

### Ошибка подключения к Grafana
```
Error: error getting folder: 401 Unauthorized
```

**Решение:** Проверьте учетные данные в `terraform.tfvars`

### Datasource не найден
```
Error: datasource with UID 'clickhouse_ds' not found
```

**Решение:** Проверьте, что ClickHouse datasource создан в Grafana и имеет правильный UID

### Конфликт ресурсов
```
Error: resource already exists
```

**Решение:** Используйте `terraform import` или измените UID дашборда

## Интеграция с CI/CD

Пример для GitHub Actions:

```yaml
name: Terraform Apply
on:
  push:
    branches: [main]
    paths: ['terraform/**']

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: hashicorp/setup-terraform@v2
      
      - name: Terraform Init
        run: terraform init
        working-directory: ./terraform
      
      - name: Terraform Apply
        run: terraform apply -auto-approve
        working-directory: ./terraform
        env:
          TF_VAR_grafana_auth: ${{ secrets.GRAFANA_AUTH }}
```

## Полезные команды

```bash
# Форматирование кода
terraform fmt

# Валидация конфигурации
terraform validate

# Граф зависимостей
terraform graph | dot -Tpng > graph.png

# Обновление провайдеров
terraform init -upgrade

# Список ресурсов в state
terraform state list

# Детали конкретного ресурса
terraform state show grafana_dashboard.server_monitoring
```

## Дополнительные ресурсы

- [Terraform Grafana Provider Documentation](https://registry.terraform.io/providers/grafana/grafana/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Grafana Provisioning Documentation](https://grafana.com/docs/grafana/latest/administration/provisioning/)
