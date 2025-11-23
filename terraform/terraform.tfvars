# Переменные для Terraform конфигурации Grafana

# URL Grafana (по умолчанию для docker-compose)
grafana_url = "http://localhost:3000"

# Учетные данные администратора Grafana
# Формат: "username:password"
grafana_auth = "admin:admin123"

# UID источника данных ClickHouse в Grafana
clickhouse_datasource_uid = "clickhouse_ds"

# Название папки для дашбордов, управляемых через Terraform
dashboard_folder = "Terraform Managed"
