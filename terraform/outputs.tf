output "folder_id" {
  description = "ID созданной папки для дашбордов"
  value       = grafana_folder.terraform_dashboards.id
}

output "folder_uid" {
  description = "UID созданной папки для дашбордов"
  value       = grafana_folder.terraform_dashboards.uid
}

output "server_monitoring_dashboard_url" {
  description = "URL дашборда Server Monitoring"
  value       = "${var.grafana_url}/d/${grafana_dashboard.server_monitoring.uid}"
}

output "dashboard_uid" {
  description = "UID дашборда Server Monitoring"
  value       = grafana_dashboard.server_monitoring.uid
}
