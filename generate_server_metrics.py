import random
import datetime
import argparse
from clickhouse_driver import Client


SECONDS_IN_HOUR = 3600
SERVERS = [f'web-{i:02d}' for i in range(1, 11)]
MIN_CPU_PERCENT = 10
MAX_CPU_PERCENT = 95
MIN_RAM_MB = 1024
MAX_RAM_MB = 8192
MIN_DISK_GB = 50
MAX_DISK_GB = 500
MIN_NETWORK_MBPS = 1
MAX_NETWORK_MBPS = 1000
PROGRESS_REPORT_MULTIPLIER = 10


def create_table(client, table_name, recreate=False):
    """Создает таблицу server_metrics в ClickHouse"""
    if recreate:
        client.execute(f'DROP TABLE IF EXISTS {table_name}')
    
    client.execute(f'''
    CREATE TABLE IF NOT EXISTS {table_name}
    (
        timestamp DateTime,
        server_name String,
        cpu_percent Float32,
        ram_mb UInt32,
        disk_gb UInt32,
        network_mbps Float32
    )
    ENGINE = MergeTree()
    ORDER BY (server_name, timestamp)
    ''')
    print(f"Таблица {table_name} создана/проверена")


def generate_data(client, table_name, num_records, batch_size, time_range_hours):
    """Генерирует метрики серверов"""
    rows = []
    time_range_seconds = time_range_hours * SECONDS_IN_HOUR
    
    # Генерируем базовые значения для каждого сервера (для реалистичности)
    server_baselines = {
        server: {
            'cpu': random.uniform(20, 60),
            'ram': random.randint(2048, 6144),
            'disk': random.randint(100, 400),
            'network': random.uniform(50, 500)
        }
        for server in SERVERS
    }
    
    for i in range(num_records):
        timestamp = datetime.datetime.now() - datetime.timedelta(
            seconds=random.randint(0, time_range_seconds)
        )
        server_name = random.choice(SERVERS)
        baseline = server_baselines[server_name]
        
        # Добавляем вариацию к базовым значениям
        cpu_percent = max(MIN_CPU_PERCENT, min(MAX_CPU_PERCENT, 
            baseline['cpu'] + random.uniform(-20, 20)))
        ram_mb = int(max(MIN_RAM_MB, min(MAX_RAM_MB,
            baseline['ram'] + random.randint(-1024, 1024))))
        disk_gb = int(max(MIN_DISK_GB, min(MAX_DISK_GB,
            baseline['disk'] + random.randint(-50, 50))))
        network_mbps = max(MIN_NETWORK_MBPS, min(MAX_NETWORK_MBPS,
            baseline['network'] + random.uniform(-100, 100)))
        
        rows.append((timestamp, server_name, cpu_percent, ram_mb, disk_gb, network_mbps))
        
        if len(rows) >= batch_size:
            client.execute(f'INSERT INTO {table_name} VALUES', rows)
            rows = []
            if (i + 1) % (batch_size * PROGRESS_REPORT_MULTIPLIER) == 0:
                print(f"Вставлено {i + 1:,} записей")
    
    if rows:
        client.execute(f'INSERT INTO {table_name} VALUES', rows)
    
    print(f"Готово! Всего: {num_records:,} записей")
    
    # Показываем статистику
    result = client.execute(f'''
        SELECT 
            server_name,
            count() as records,
            round(avg(cpu_percent), 2) as avg_cpu,
            round(avg(ram_mb), 0) as avg_ram_mb
        FROM {table_name}
        GROUP BY server_name
        ORDER BY server_name
        LIMIT 5
    ''')
    
    print("\nСтатистика по серверам (первые 5):")
    print(f"{'Сервер':<12} {'Записей':<10} {'Avg CPU %':<12} {'Avg RAM MB':<12}")
    print("-" * 50)
    for row in result:
        print(f"{row[0]:<12} {row[1]:<10} {row[2]:<12} {row[3]:<12}")


def main():
    parser = argparse.ArgumentParser(
        description='Генератор метрик серверов для ClickHouse'
    )
    
    parser.add_argument('--host', default='localhost', help='Хост ClickHouse')
    parser.add_argument('--port', type=int, default=9000, help='Порт ClickHouse')
    parser.add_argument('--database', default='default', help='Имя базы данных')
    parser.add_argument('--user', default='default', help='Имя пользователя')
    parser.add_argument('--password', default='', help='Пароль')
    
    parser.add_argument('--table', default='server_metrics', help='Имя таблицы')
    parser.add_argument('--recreate', action='store_true', 
                       help='Удалить и пересоздать таблицу')
    parser.add_argument('--skip-create', action='store_true', 
                       help='Пропустить создание таблицы')
    
    parser.add_argument('--records', type=int, default=50_000, 
                       help='Количество записей (по умолчанию 50000)')
    parser.add_argument('--batch-size', type=int, default=10_000, 
                       help='Размер batch для вставки')
    parser.add_argument('--time-range', type=int, default=24, 
                       help='Временной диапазон в часах')
    
    args = parser.parse_args()
    
    print(f"Подключение к ClickHouse на {args.host}:{args.port}...")
    client = Client(
        host=args.host,
        port=args.port,
        database=args.database,
        user=args.user,
        password=args.password
    )
    
    if not args.skip_create:
        create_table(client, args.table, args.recreate)
    
    print(f"\nГенерация {args.records:,} записей метрик для {len(SERVERS)} серверов...")
    generate_data(
        client,
        args.table,
        args.records,
        args.batch_size,
        args.time_range
    )


if __name__ == '__main__':
    main()
