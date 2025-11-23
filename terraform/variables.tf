variable "grafana_url" {
  description = "URL Grafana"
  type        = string
  default     = "http://localhost:3000"
}

variable "grafana_auth" {
  description = "Grafana admin credentials (format: username:password)"
  type        = string
  default     = "admin:admin123"
  sensitive   = true
}

variable "clickhouse_datasource_uid" {
  description = "UID datasource ClickHouse"
  type        = string
  default     = "clickhouse_ds"
}

variable "dashboard_folder" {
  description = "Папка для дашбордов"
  type        = string
  default     = "Terraform Managed"
}
