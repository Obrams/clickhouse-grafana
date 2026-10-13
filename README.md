# ClickHouse + Grafana: analytics and monitoring system

A full-featured system for generating test data, storing it in ClickHouse and visualizing it in Grafana with preconfigured dashboards and alerts.

## Quick start

### 1. Start the infrastructure

```bash
docker-compose up -d
docker ps
```

### 2. Create a virtual environment and install dependencies

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 3. Generate test data

```bash
python python_generate_script.py --password changeme
python python_generate_script.py --password changeme --records 10000
```

### 4. Open Grafana

Open in the browser: **http://localhost:3000**

- **Login**: admin
- **Password**: admin123

## What's included

### Dashboards

1. **Event rate** - activity analysis by day/hour/type
2. **Errors by type** - monitoring errors and problematic users
3. **Latency monitoring** - system performance (avg, p95, p99)
4. **Error anomalies** - detecting error spikes and patterns

### Alerts

- **High Latency Alert** - fires when latency > 2000 ms
- **High Error Rate Alert** - fires when error_rate > 5%

## Project structure

```
clickhouse-grafana/
├── docker-compose.yaml
├── python_generate_script.py
├── requirements.txt
├── README.md
└── grafana/
    ├── provisioning/
    │   ├── datasources/
    │   │   └── clickhouse.yaml
    │   ├── dashboards/
    │   │   └── default.yaml
    │   └── alerting/
    │       └── alerts.yaml
    └── dashboards/
        ├── events_frequency.json
        ├── errors_by_type.json
        ├── latency_monitoring.json
        └── error_anomalies.json
```

## Useful commands

### Data generation

```bash
python python_generate_script.py --password changeme --recreate --records 100000
python python_generate_script.py --password changeme --time-range 24 --records 1000000
python python_generate_script.py --password changeme --skip-create --records 50000
```

### Docker

```bash
docker-compose down
docker-compose down -v
docker-compose logs -f grafana
docker-compose logs -f clickhouse
docker-compose restart grafana
```

### ClickHouse CLI

```bash
docker exec -it clickhouse clickhouse-client --password changeme

SELECT count() FROM web_events;
SELECT event, count() FROM web_events GROUP BY event;
SELECT avg(latency) FROM web_events;
```

## Requirements

- Docker and Docker Compose
- Python 3.8+
- 2GB+ free RAM for Docker

## Data structure

The `web_events` table contains:
- `event_time` (DateTime) - event time
- `event` (String) - event type: login, logout, click, purchase, error, view
- `user_id` (UInt32) - user ID (1-10000)
- `latency` (UInt32) - latency in ms (10-1000)
- `error_type` (String) - error type: timeout, server_error, validation_error or empty

## Usage examples

### Performance monitoring
1. Open the "Latency monitoring" dashboard
2. Check P95 and Max latency metrics
3. Look at the top users with high latency

### Error analysis
1. Open the "Errors by type" dashboard
2. Check the error rate (should be < 5%)
3. Review error trends over time

### Anomaly detection
1. Open the "Error anomalies" dashboard
2. Check the heatmap to spot patterns
3. Compare current values with previous periods

## Troubleshooting

### Grafana shows no data
1. Check that ClickHouse is running: `docker ps`
2. Make sure the data is loaded (see commands above)
3. Check the datasource in Grafana: Settings → Data sources

### Alerts do not work
1. Make sure the ClickHouse plugin is installed (check Grafana logs)
2. Go to Alerting → Alert rules to check status
3. Restart Grafana if needed: `docker-compose restart grafana`

## Resources

- [ClickHouse Documentation](https://clickhouse.com/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Grafana ClickHouse Plugin](https://grafana.com/grafana/plugins/grafana-clickhouse-datasource/)
