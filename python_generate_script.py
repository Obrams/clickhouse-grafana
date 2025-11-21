import random
import datetime
import argparse
from clickhouse_driver import Client


SECONDS_IN_HOUR = 3600
MIN_USER_ID = 1
MAX_USER_ID = 10000
MIN_LATENCY_MS = 10
MAX_LATENCY_MS = 1000
PROGRESS_REPORT_MULTIPLIER = 10


def create_table(client, table_name, recreate=False):
    if recreate:
        client.execute(f'DROP TABLE IF EXISTS {table_name}')
    
    client.execute(f'''
    CREATE TABLE IF NOT EXISTS {table_name}
    (
        event_time DateTime,
        event String,
        user_id UInt32,
        latency UInt32,
        error_type String
    )
    ENGINE = MergeTree()
    ORDER BY event_time
    ''')


def generate_data(client, table_name, num_records, batch_size, time_range_hours):
    events = ['login', 'logout', 'click', 'purchase', 'error', 'view']
    error_types = ['', 'timeout', 'server_error', 'validation_error', '']
    
    rows = []
    time_range_seconds = time_range_hours * SECONDS_IN_HOUR
    
    for i in range(num_records):
        event_time = datetime.datetime.now() - datetime.timedelta(
            seconds=random.randint(0, time_range_seconds)
        )
        event = random.choice(events)
        user_id = random.randint(MIN_USER_ID, MAX_USER_ID)
        latency = random.randint(MIN_LATENCY_MS, MAX_LATENCY_MS)
        error_type = random.choice(error_types)
        
        rows.append((event_time, event, user_id, latency, error_type))
        
        if len(rows) >= batch_size:
            client.execute(f'INSERT INTO {table_name} VALUES', rows)
            rows = []
            if (i + 1) % (batch_size * PROGRESS_REPORT_MULTIPLIER) == 0:
                print(f"Inserted {i + 1:,} records")
    
    if rows:
        client.execute(f'INSERT INTO {table_name} VALUES', rows)
    
    print(f"Done. Total: {num_records:,} records")


def main():
    parser = argparse.ArgumentParser(description='ClickHouse test data generator')
    
    parser.add_argument('--host', default='localhost', help='ClickHouse host')
    parser.add_argument('--port', type=int, default=9000, help='ClickHouse port')
    parser.add_argument('--database', default='default', help='Database name')
    parser.add_argument('--user', default='default', help='Username')
    parser.add_argument('--password', default='', help='Password')
    
    parser.add_argument('--table', default='web_events', help='Table name')
    parser.add_argument('--recreate', action='store_true', help='Drop and recreate table')
    parser.add_argument('--skip-create', action='store_true', help='Skip table creation')
    
    parser.add_argument('--records', type=int, default=1_000, help='Number of records')
    parser.add_argument('--batch-size', type=int, default=10_000, help='Insert batch size')
    parser.add_argument('--time-range', type=int, default=1, help='Time range in hours')
    
    args = parser.parse_args()
    
    client = Client(
        host=args.host,
        port=args.port,
        database=args.database,
        user=args.user,
        password=args.password
    )
    
    if not args.skip_create:
        create_table(client, args.table, args.recreate)
    
    generate_data(
        client,
        args.table,
        args.records,
        args.batch_size,
        args.time_range
    )


if __name__ == '__main__':
    main()
