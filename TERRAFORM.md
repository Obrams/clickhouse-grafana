# Terraform для управления дашбордами Grafana

> 📖 **Полная документация**: [terraform/README.md](terraform/README.md)

## Быстрый старт

```bash
# 1. Генерация тестовых данных
python generate_server_metrics.py --password changeme --records 50000

# 2. Инициализация Terraform
cd terraform
terraform init

# 3. Проверка плана
terraform plan

# 4. Применение конфигурации
terraform apply

# 5. Получение URL дашборда
terraform output server_monitoring_dashboard_url
```

## Что создается

- **Папка**: "Terraform Managed" в Grafana
- **Дашборд**: "Server Monitoring (Terraform)"
- **Источник данных**: server_metrics

## Панели дашборда

1. CPU Utilization by Server (time series)
2. RAM Usage by Server (time series)
3. Average Disk Usage (gauge)
4. Current Avg CPU (stat)
5. Network Traffic by Server (bar chart)
6. Top 5 Servers by Load (table)

## Основные команды

```bash
# Просмотр состояния
terraform show

# Обновление дашборда
# Отредактируйте dashboards.tf, затем:
terraform apply

# Удаление ресурсов
terraform destroy

# Форматирование кода
terraform fmt

# Валидация конфигурации
terraform validate
```

## Структура

```
terraform/
├── main.tf          # Provider и основная конфигурация
├── variables.tf     # Переменные
├── outputs.tf       # Outputs
├── dashboards.tf    # Ресурсы дашбордов
├── terraform.tfvars # Значения переменных
└── README.md        # Детальная документация
```

## Преимущества

✅ **Infrastructure as Code** - дашборды как код  
✅ **Версионирование** - полная история изменений в Git  
✅ **Автоматизация** - интеграция с CI/CD  
✅ **Multi-environment** - dev/staging/prod из одного кода  
✅ **Планирование** - `terraform plan` показывает изменения  

## Пример использования в CI/CD

```yaml
# .github/workflows/terraform.yml
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

## Переменные

| Переменная | По умолчанию | Описание |
|-----------|--------------|----------|
| `grafana_url` | http://localhost:3000 | URL Grafana |
| `grafana_auth` | admin:admin123 | Учетные данные |
| `clickhouse_datasource_uid` | clickhouse_ds | UID datasource |
| `dashboard_folder` | Terraform Managed | Папка дашбордов |

## Troubleshooting

### Ошибка подключения
```
Error: error getting folder: 401 Unauthorized
```
**Решение**: Проверьте `grafana_auth` в `terraform.tfvars`

### Datasource не найден
```
Error: datasource with UID 'clickhouse_ds' not found
```
**Решение**: Убедитесь, что ClickHouse datasource существует в Grafana

## Дополнительные материалы

- 📚 [Terraform Grafana Provider Docs](https://registry.terraform.io/providers/grafana/grafana/latest/docs)
- 📚 [Terraform Best Practices](https://www.terraform-best-practices.com/)
- 📁 [Полная документация](terraform/README.md)

## Следующие шаги

1. Изучите [полную документацию](terraform/README.md)
2. Попробуйте создать свой дашборд
3. Настройте CI/CD для автоматического деплоя
4. Создайте workspaces для разных окружений
