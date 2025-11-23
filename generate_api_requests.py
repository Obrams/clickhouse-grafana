import random
import datetime
import argparse
from clickhouse_driver import Client


SECONDS_IN_HOUR = 3600
API_ENDPOINTS = [
    '/api/users', '/api/users/{id}', '/api/products', '/api/products/{id}',
    '/api/orders', '/api/orders/{id}', '/api/auth/login', '/api/auth/logout',
    '/api/cart', '/api/cart/items', '/api/search', '/api/categories',
    '/api/reviews', '/api/payments', '/api/shipping', '/api/inventory'
]
HTTP_METHODS = ['GET', 'POST', 'PUT', 'DELETE', 'PATCH']
# Распределение методов: GET чаще всего
METHOD_WEIGHTS = [60, 20, 10, 5, 5]
STATUS_CODES = [200, 201, 204, 400, 401, 403, 404, 500, 502, 503]
# Распределение статусов: успешные чаще
STATUS_WEIGHTS = [70, 10, 5, 3, 2, 2, 3, 3, 1, 1]
USER_AGENTS = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Safari/17.0',
    'Mozilla/5.0 (X11; Linux x86_64) Firefox/121.0',
    'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) Safari/17.0',
    'Mozilla/5.0 (iPad; CPU OS 17_0 like Mac OS X) Safari/17.0',
    'Mozilla/5.0 (Android 14; Mobile) Chrome/120.0.0.0',
    'PostmanRuntime/7.36.0',
    'curl/8.4.0',
    'python-requests/2.31.0'
]
MIN_RESPONSE_TIME_MS = 5
MAX_RESPONSE_TIME_MS = 3000
PROGRESS_REPORT_MULTIPLIER = 10


def create_table(client, table_name, recreate=False):
    """Создает таблицу api_requests в ClickHouse"""
    if recreate:
        client.execute(f'DROP TABLE IF EXISTS {table_name}')
    
    client.execute(f'''
    CREATE TABLE IF NOT EXISTS {table_name}
    (
        request_time DateTime,
        endpoint String,
        method String,
        status_code UInt16,
        response_time_ms UInt32,
        user_agent String
    )
    ENGINE = MergeTree()
    ORDER BY request_time
    ''')
    print(f"Таблица {table_name} создана/проверена")


def generate_data(client, table_name, num_records, batch_size, time_range_hours):
    """Генерирует API запросы"""
    rows = []
    time_range_seconds = time_range_hours * SECONDS_IN_HOUR
    
    for i in range(num_records):
        request_time = datetime.datetime.now() - datetime.timedelta(
            seconds=random.randint(0, time_range_seconds)
        )
        
        endpoint = random.choice(API_ENDPOINTS)
        # Заменяем {id} на реальный ID для реалистичности
        if '{id}' in endpoint:
            endpoint = endpoint.replace('{id}', str(random.randint(1, 1000)))
        
        method = random.choices(HTTP_METHODS, weights=METHOD_WEIGHTS)[0]
        status_code = random.choices(STATUS_CODES, weights=STATUS_WEIGHTS)[0]
        
        # Время ответа зависит от статуса
        if status_code >= 500:
            # Серверные ошибки обычно медленнее
            response_time_ms = random.randint(1000, MAX_RESPONSE_TIME_MS)
        elif status_code >= 400:
            # Клиентские ошибки быстрые
            response_time_ms = random.randint(MIN_RESPONSE_TIME_MS, 200)
        else:
            # Успешные запросы - нормальное распределение
            response_time_ms = random.randint(MIN_RESPONSE_TIME_MS, 1000)
        
        user_agent = random.choice(USER_AGENTS)
        
        rows.append((
            request_time, endpoint, method, 
            status_code, response_time_ms, user_agent
        ))
        
        if len(rows) >= batch_size:
            client.execute(f'INSERT INTO {table_name} VALUES', rows)
            rows = []
            if (i + 1) % (batch_size * PROGRESS_REPORT_MULTIPLIER) == 0:
                print(f"Вставлено {i + 1:,} записей")
    
    if rows:
        client.execute(f'INSERT INTO {table_name} VALUES', rows)
    
    print(f"Готово! Всего: {num_records:,} запросов")
    
    # Показываем статистику по методам
    result = client.execute(f'''
        SELECT 
            method,
            count() as requests,
            round(avg(response_time_ms), 2) as avg_response_ms
        FROM {table_name}
        GROUP BY method
        ORDER BY requests DESC
    ''')
    
    print("\nСтатистика по HTTP методам:")
    print(f"{'Метод':<10} {'Запросов':<12} {'Avg время (мс)':<15}")
    print("-" * 40)
    for row in result:
        print(f"{row[0]:<10} {row[1]:<12} {row[2]:<15}")
    
    # Статистика по статус кодам
    result = client.execute(f'''
        SELECT 
            status_code,
            count() as requests,
            round(count() * 100.0 / (SELECT count() FROM {table_name}), 2) as percentage
        FROM {table_name}
        GROUP BY status_code
        ORDER BY requests DESC
        LIMIT 5
    ''')
    
    print("\nТоп-5 статус кодов:")
    print(f"{'Код':<10} {'Запросов':<12} {'Процент %':<12}")
    print("-" * 35)
    for row in result:
        print(f"{row[0]:<10} {row[1]:<12} {row[2]:<12}")
    
    # Топ endpoints
    result = client.execute(f'''
        SELECT 
            endpoint,
            count() as requests
        FROM {table_name}
        GROUP BY endpoint
        ORDER BY requests DESC
        LIMIT 5
    ''')
    
    print("\nТоп-5 endpoints:")
    print(f"{'Endpoint':<30} {'Запросов':<12}")
    print("-" * 45)
    for row in result:
        print(f"{row[0]:<30} {row[1]:<12}")


def main():
    parser = argparse.ArgumentParser(
        description='Генератор API запросов для ClickHouse'
    )
    
    parser.add_argument('--host', default='localhost', help='Хост ClickHouse')
    parser.add_argument('--port', type=int, default=9000, help='Порт ClickHouse')
    parser.add_argument('--database', default='default', help='Имя базы данных')
    parser.add_argument('--user', default='default', help='Имя пользователя')
    parser.add_argument('--password', default='', help='Пароль')
    
    parser.add_argument('--table', default='api_requests', help='Имя таблицы')
    parser.add_argument('--recreate', action='store_true', 
                       help='Удалить и пересоздать таблицу')
    parser.add_argument('--skip-create', action='store_true', 
                       help='Пропустить создание таблицы')
    
    parser.add_argument('--records', type=int, default=100_000, 
                       help='Количество запросов (по умолчанию 100000)')
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
    
    print(f"\nГенерация {args.records:,} API запросов...")
    generate_data(
        client,
        args.table,
        args.records,
        args.batch_size,
        args.time_range
    )


if __name__ == '__main__':
    main()
