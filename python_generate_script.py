import random
import datetime
import argparse
from clickhouse_driver import Client


# Константы для генерации данных
SECONDS_IN_HOUR = 3600
MIN_USER_ID = 1
MAX_USER_ID = 10000
MIN_LATENCY_MS = 10
MAX_LATENCY_MS = 1000
PROGRESS_REPORT_MULTIPLIER = 10


def create_table(client, table_name, recreate=False):
    """Создание или пересоздание таблицы"""
    if recreate:
        print(f"Удаляем таблицу {table_name}...")
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
    """Генерация и вставка тестовых данных"""
    events = ['login', 'logout', 'click', 'purchase', 'error', 'view']
    error_types = ['', 'timeout', 'server_error', 'validation_error', '']
    
    rows = []
    time_range_seconds = time_range_hours * SECONDS_IN_HOUR
    
    print(f"Генерируем {num_records:,} записей...")
    
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
                print(f"  Вставлено {i + 1:,} записей...")
    
    if rows:
        client.execute(f'INSERT INTO {table_name} VALUES', rows)
    
    print(f"✅ Данные успешно загружены! Всего записей: {num_records:,}")


def main():
    parser = argparse.ArgumentParser(
        description='Генератор тестовых данных для ClickHouse'
    )
    
    parser.add_argument('--host', default='localhost',
                        help='Хост ClickHouse (по умолчанию: localhost)')
    parser.add_argument('--port', type=int, default=9000,
                        help='Порт ClickHouse (по умолчанию: 9000)')
    parser.add_argument('--database', default='default',
                        help='База данных (по умолчанию: default)')
    parser.add_argument('--user', default='default',
                        help='Пользователь (по умолчанию: default)')
    parser.add_argument('--password', default='',
                        help='Пароль (по умолчанию: пустой)')
    
    parser.add_argument('--table', default='web_events',
                        help='Имя таблицы (по умолчанию: web_events)')
    parser.add_argument('--recreate', action='store_true',
                        help='Пересоздать таблицу (удалить старую)')
    parser.add_argument('--skip-create', action='store_true',
                        help='Не создавать таблицу, только вставить данные')
    
    parser.add_argument('--records', type=int, default=1_000,
                        help='Количество записей (по умолчанию: 1,000)')
    parser.add_argument('--batch-size', type=int, default=10_000,
                        help='Размер батча для вставки (по умолчанию: 10,000)')
    parser.add_argument('--time-range', type=int, default=1,
                        help='Временной диапазон в часах (по умолчанию: 1)')
    
    args = parser.parse_args()
    
    print(f"Подключаемся к ClickHouse {args.host}:{args.port}...")
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
