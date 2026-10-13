# Quick start

## Step 1: Start the infrastructure

```bash
docker-compose up -d
```

Wait 30-60 seconds for Grafana to fully initialize and install the ClickHouse plugin.

## Step 2: Generate data

```bash
source venv/bin/activate
python python_generate_script.py --password changeme --records 10000 --time-range 24
```

## Step 3: Open Grafana

Open in the browser: **http://localhost:3000**

- Login: **admin**
- Password: **admin123**

## Step 4: View dashboards

1. In the left menu, click the "Dashboards" icon (4 squares)
2. Select the folder **"ClickHouse Analytics"**
3. Open any of the 4 dashboards:
   - Event rate
   - Errors by type
   - Latency monitoring
   - Error anomalies

## Step 5: Check alerts

1. In the left menu, select **"Alerting"** → **"Alert rules"**
2. You will see 2 configured alerts:
   - High Latency Alert
   - High Error Rate Alert

## Generating more data

For more realistic testing:

```bash
python python_generate_script.py --password changeme --records 1000000 --time-range 168
```

## Stopping the system

```bash
docker-compose down
docker-compose down -v
```

## Troubleshooting

### Dashboards are empty?
- Make sure the data is loaded (see Step 2)
- Select the correct time range in Grafana (top right corner)

### ClickHouse connection error?
```bash
docker ps
docker-compose logs clickhouse
docker-compose logs grafana
```
