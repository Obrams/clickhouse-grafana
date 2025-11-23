import random
import datetime
import argparse
import uuid
from clickhouse_driver import Client


SECONDS_IN_HOUR = 3600
MIN_USER_ID = 1
MAX_USER_ID = 10000
MIN_SESSION_DURATION_MINUTES = 1
MAX_SESSION_DURATION_MINUTES = 120
MIN_PAGES_VISITED = 1
MAX_PAGES_VISITED = 50
DEVICE_TYPES = ['desktop', 'mobile', 'tablet', 'smarttv', 'console']
COUNTRIES = [
    'USA', 'UK', 'Germany', 'France', 'Spain', 'Italy', 'Canada', 'Australia',
    'Japan', 'China', 'India', 'Brazil', 'Mexico', 'Russia', 'Netherlands',
    'Sweden', 'Poland', 'Turkey', 'South Korea', 'Argentina'
]
PROGRESS_REPORT_MULTIPLIER = 10


def create_table(client, table_name, recreate=False):
    """Создает таблицу user_sessions в ClickHouse"""
    if recreate:
        client.execute(f'DROP TABLE IF EXISTS {table_name}')
    
    client.execute(f'''
    CREATE TABLE IF NOT EXISTS {table_name}
    (
        session_id String,
        user_id UInt32,
        start_time DateTime,
        end_time DateTime,
        duration_minutes UInt32,
        pages_visited UInt16,
        device_type String,
        country String
    )
    ENGINE = MergeTree()
    ORDER BY (start_time, user_id)
    ''')
    print(f"Таблица {table_name} создана/проверена")


def generate_data(client, table_name, num_records, batch_size, time_range_hours):
    """Генерирует пользовательские сессии"""
    rows = []
    time_range_seconds = time_range_hours * SECONDS_IN_HOUR
    
    for i in range(num_records):
        session_id = str(uuid.uuid4())
        user_id = random.randint(MIN_USER_ID, MAX_USER_ID)
        
        # Генерируем время начала сессии
        start_time = datetime.datetime.now() - datetime.timedelta(
            seconds=random.randint(0, time_range_seconds)
        )
        
        # Длительность сессии
        duration_minutes = random.randint(
            MIN_SESSION_DURATION_MINUTES, 
            MAX_SESSION_DURATION_MINUTES
        )
        end_time = start_time + datetime.timedelta(minutes=duration_minutes)
        
        # Количество посещенных страниц зависит от длительности
        base_pages = duration_minutes // 3  # примерно 1 страница на 3 минуты
        pages_visited = max(MIN_PAGES_VISITED, min(MAX_PAGES_VISITED,
            base_pages + random.randint(-2, 5)))
        
        device_type = random.choice(DEVICE_TYPES)
        country = random.choice(COUNTRIES)
        
        rows.append((
            session_id, user_id, start_time, end_time, 
            duration_minutes, pages_visited, device_type, country
        ))
        
        if len(rows) >= batch_size:
            client.execute(f'INSERT INTO {table_name} VALUES', rows)
            rows = []
            if (i + 1) % (batch_size * PROGRESS_REPORT_MULTIPLIER) == 0:
                print(f"Вставлено {i + 1:,} записей")
    
    if rows:
        client.execute(f'INSERT INTO {table_name} VALUES', rows)
    
    print(f"Готово! Всего: {num_records:,} сессий")
    
    # Показываем статистику
    result = client.execute(f'''
        SELECT 
            device_type,
            count() as sessions,
            round(avg(duration_minutes), 2) as avg_duration_min,
            round(avg(pages_visited), 2) as avg_pages
        FROM {table_name}
        GROUP BY device_type
        ORDER BY sessions DESC
    ''')
    
    print("\nСтатистика по типам устройств:")
    print(f"{'Устройство':<12} {'Сессий':<10} {'Avg мин':<12} {'Avg страниц':<12}")
    print("-" * 50)
    for row in result:
        print(f"{row[0]:<12} {row[1]:<10} {row[2]:<12} {row[3]:<12}")
    
    # Топ стран
    result = client.execute(f'''
        SELECT 
            country,
            count() as sessions
        FROM {table_name}
        GROUP BY country
        ORDER BY sessions DESC
        LIMIT 5
    ''')
    
    print("\nТоп-5 стран по сессиям:")
    print(f"{'Страна':<20} {'Сессий':<10}")
    print("-" * 30)
    for row in result:
        print(f"{row[0]:<20} {row[1]:<10}")


def main():
    parser = argparse.ArgumentParser(
        description='Генератор пользовательских сессий для ClickHouse'
    )
    
    parser.add_argument('--host', default='localhost', help='Хост ClickHouse')
    parser.add_argument('--port', type=int, default=9000, help='Порт ClickHouse')
    parser.add_argument('--database', default='default', help='Имя базы данных')
    parser.add_argument('--user', default='default', help='Имя пользователя')
    parser.add_argument('--password', default='', help='Пароль')
    
    parser.add_argument('--table', default='user_sessions', help='Имя таблицы')
    parser.add_argument('--recreate', action='store_true', 
                       help='Удалить и пересоздать таблицу')
    parser.add_argument('--skip-create', action='store_true', 
                       help='Пропустить создание таблицы')
    
    parser.add_argument('--records', type=int, default=10_000, 
                       help='Количество сессий (по умолчанию 10000)')
    parser.add_argument('--batch-size', type=int, default=5_000, 
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
    
    print(f"\nГенерация {args.records:,} пользовательских сессий...")
    generate_data(
        client,
        args.table,
        args.records,
        args.batch_size,
        args.time_range
    )


if __name__ == '__main__':
    main()
