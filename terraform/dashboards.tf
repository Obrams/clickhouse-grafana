resource "grafana_dashboard" "server_monitoring" {
  folder = grafana_folder.terraform_dashboards.id
  
  config_json = jsonencode({
    title = "Server Monitoring (Terraform)"
    uid   = "terraform-server-monitoring"
    tags  = ["terraform", "servers", "infrastructure"]
    
    timezone        = "browser"
    editable        = true
    graphTooltip    = 1
    schemaVersion   = 39
    
    time = {
      from = "now-24h"
      to   = "now"
    }
    
    refresh = "30s"
    
    panels = [
      # CPU Utilization по серверам
      {
        id    = 1
        title = "CPU Utilization by Server"
        type  = "timeseries"
        
        gridPos = {
          x = 0
          y = 0
          w = 12
          h = 8
        }
        
        datasource = {
          type = "grafana-clickhouse-datasource"
          uid  = var.clickhouse_datasource_uid
        }
        
        fieldConfig = {
          defaults = {
            color = {
              mode = "palette-classic"
            }
            custom = {
              lineWidth       = 2
              fillOpacity     = 10
              showPoints      = "never"
              spanNulls       = true
              lineInterpolation = "smooth"
            }
            unit = "percent"
          }
          overrides = []
        }
        
        options = {
          legend = {
            displayMode = "table"
            placement   = "right"
            calcs       = ["mean", "max"]
          }
          tooltip = {
            mode = "multi"
          }
        }
        
        targets = [
          {
            datasource = {
              type = "grafana-clickhouse-datasource"
              uid  = var.clickhouse_datasource_uid
            }
            refId      = "A"
            rawSql     = <<-EOT
              SELECT 
                toStartOfInterval(timestamp, INTERVAL 5 MINUTE) as time,
                server_name,
                round(avg(cpu_percent), 2) as cpu
              FROM server_metrics
              WHERE $__timeFilter(timestamp)
              GROUP BY time, server_name
              ORDER BY time
            EOT
            format     = "time_series"
          }
        ]
      },
      
      # RAM Usage
      {
        id    = 2
        title = "RAM Usage by Server"
        type  = "timeseries"
        
        gridPos = {
          x = 12
          y = 0
          w = 12
          h = 8
        }
        
        datasource = {
          type = "grafana-clickhouse-datasource"
          uid  = var.clickhouse_datasource_uid
        }
        
        fieldConfig = {
          defaults = {
            color = {
              mode = "palette-classic"
            }
            custom = {
              lineWidth       = 2
              fillOpacity     = 30
              showPoints      = "never"
              spanNulls       = true
              lineInterpolation = "smooth"
              drawStyle       = "line"
              gradientMode    = "opacity"
            }
            unit = "decmbytes"
          }
          overrides = []
        }
        
        options = {
          legend = {
            displayMode = "table"
            placement   = "right"
            calcs       = ["mean", "max"]
          }
          tooltip = {
            mode = "multi"
          }
        }
        
        targets = [
          {
            datasource = {
              type = "grafana-clickhouse-datasource"
              uid  = var.clickhouse_datasource_uid
            }
            refId      = "A"
            rawSql     = <<-EOT
              SELECT 
                toStartOfInterval(timestamp, INTERVAL 5 MINUTE) as time,
                server_name,
                round(avg(ram_mb), 0) as ram_mb
              FROM server_metrics
              WHERE $__timeFilter(timestamp)
              GROUP BY time, server_name
              ORDER BY time
            EOT
            format     = "time_series"
          }
        ]
      },
      
      # Average Disk Space (Gauge)
      {
        id    = 3
        title = "Average Disk Usage"
        type  = "gauge"
        
        gridPos = {
          x = 0
          y = 8
          w = 6
          h = 6
        }
        
        datasource = {
          type = "grafana-clickhouse-datasource"
          uid  = var.clickhouse_datasource_uid
        }
        
        fieldConfig = {
          defaults = {
            color = {
              mode = "thresholds"
            }
            thresholds = {
              mode = "absolute"
              steps = [
                {
                  value = null
                  color = "green"
                },
                {
                  value = 300
                  color = "yellow"
                },
                {
                  value = 400
                  color = "red"
                }
              ]
            }
            unit = "deckbytes"
            min  = 0
            max  = 500
          }
          overrides = []
        }
        
        options = {
          showThresholdLabels    = true
          showThresholdMarkers   = true
          reduceOptions = {
            values = false
            calcs  = ["lastNotNull"]
          }
        }
        
        targets = [
          {
            datasource = {
              type = "grafana-clickhouse-datasource"
              uid  = var.clickhouse_datasource_uid
            }
            refId      = "A"
            rawSql     = <<-EOT
              SELECT 
                now() as time,
                round(avg(disk_gb), 2) as value
              FROM server_metrics
              WHERE timestamp >= now() - INTERVAL 1 HOUR
            EOT
            format     = "table"
          }
        ]
      },
      
      # Current Average CPU
      {
        id    = 4
        title = "Current Avg CPU"
        type  = "stat"
        
        gridPos = {
          x = 6
          y = 8
          w = 6
          h = 6
        }
        
        datasource = {
          type = "grafana-clickhouse-datasource"
          uid  = var.clickhouse_datasource_uid
        }
        
        fieldConfig = {
          defaults = {
            color = {
              mode = "thresholds"
            }
            thresholds = {
              mode = "absolute"
              steps = [
                {
                  value = null
                  color = "green"
                },
                {
                  value = 60
                  color = "yellow"
                },
                {
                  value = 80
                  color = "red"
                }
              ]
            }
            unit = "percent"
          }
          overrides = []
        }
        
        options = {
          graphMode       = "area"
          colorMode       = "background"
          justifyMode     = "center"
          textMode        = "value_and_name"
          reduceOptions = {
            values = false
            calcs  = ["lastNotNull"]
          }
        }
        
        targets = [
          {
            datasource = {
              type = "grafana-clickhouse-datasource"
              uid  = var.clickhouse_datasource_uid
            }
            refId      = "A"
            rawSql     = <<-EOT
              SELECT 
                now() as time,
                round(avg(cpu_percent), 2) as value
              FROM server_metrics
              WHERE timestamp >= now() - INTERVAL 5 MINUTE
            EOT
            format     = "table"
          }
        ]
      },
      
      # Network Traffic
      {
        id    = 5
        title = "Network Traffic by Server"
        type  = "barchart"
        
        gridPos = {
          x = 12
          y = 8
          w = 12
          h = 6
        }
        
        datasource = {
          type = "grafana-clickhouse-datasource"
          uid  = var.clickhouse_datasource_uid
        }
        
        fieldConfig = {
          defaults = {
            color = {
              mode = "palette-classic"
            }
            unit = "decbytes"
          }
          overrides = []
        }
        
        options = {
          orientation     = "horizontal"
          xTickLabelRotation = 0
          legend = {
            displayMode = "list"
            placement   = "bottom"
          }
        }
        
        targets = [
          {
            datasource = {
              type = "grafana-clickhouse-datasource"
              uid  = var.clickhouse_datasource_uid
            }
            refId      = "A"
            rawSql     = <<-EOT
              SELECT 
                server_name as metric,
                round(avg(network_mbps), 2) as value
              FROM server_metrics
              WHERE timestamp >= now() - INTERVAL 1 HOUR
              GROUP BY server_name
              ORDER BY value DESC
            EOT
            format     = "table"
          }
        ]
      },
      
      # Top 5 серверов по нагрузке
      {
        id    = 6
        title = "Top 5 Servers by Load (Last Hour)"
        type  = "table"
        
        gridPos = {
          x = 0
          y = 14
          w = 24
          h = 6
        }
        
        datasource = {
          type = "grafana-clickhouse-datasource"
          uid  = var.clickhouse_datasource_uid
        }
        
        fieldConfig = {
          defaults = {
            custom = {
              align = "left"
            }
            color = {
              mode = "thresholds"
            }
            thresholds = {
              mode = "absolute"
              steps = [
                {
                  value = null
                  color = "green"
                },
                {
                  value = 60
                  color = "yellow"
                },
                {
                  value = 80
                  color = "red"
                }
              ]
            }
          }
          overrides = [
            {
              matcher = {
                id      = "byName"
                options = "avg_cpu"
              }
              properties = [
                {
                  id    = "unit"
                  value = "percent"
                },
                {
                  id    = "custom.width"
                  value = 120
                }
              ]
            },
            {
              matcher = {
                id      = "byName"
                options = "avg_ram_mb"
              }
              properties = [
                {
                  id    = "unit"
                  value = "decmbytes"
                },
                {
                  id    = "custom.width"
                  value = 120
                }
              ]
            },
            {
              matcher = {
                id      = "byName"
                options = "avg_network"
              }
              properties = [
                {
                  id    = "unit"
                  value = "decbytes"
                },
                {
                  id    = "custom.width"
                  value = 130
                }
              ]
            }
          ]
        }
        
        options = {
          showHeader = true
          sortBy = [
            {
              displayName = "avg_cpu"
              desc        = true
            }
          ]
        }
        
        targets = [
          {
            datasource = {
              type = "grafana-clickhouse-datasource"
              uid  = var.clickhouse_datasource_uid
            }
            refId      = "A"
            rawSql     = <<-EOT
              SELECT 
                server_name,
                round(avg(cpu_percent), 2) as avg_cpu,
                round(avg(ram_mb), 0) as avg_ram_mb,
                round(avg(network_mbps), 2) as avg_network,
                max(cpu_percent) as max_cpu
              FROM server_metrics
              WHERE timestamp >= now() - INTERVAL 1 HOUR
              GROUP BY server_name
              ORDER BY avg_cpu DESC
              LIMIT 5
            EOT
            format     = "table"
          }
        ]
      }
    ]
  })
}
