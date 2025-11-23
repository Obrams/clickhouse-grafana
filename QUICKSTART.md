# Быстрый старт

Самый быстрый способ развернуть проект и увидеть все возможности.

## Вариант 1: Базовая конфигурация (5 минут)

### Шаг 1: Запуск инфраструктуры

```bash
# Клонируем репозиторий (если еще не сделано)
git clone <repository-url>
cd clickhouse-grafana

# Запускаем Docker Compose
docker-compose up -d

# Проверяем статус
docker ps
```

### Шаг 2: Установка зависимостей

```bash
# Создаем виртуальное окружение
python3 -m venv venv
source venv/bin/activate  # Linux/macOS
# или
venv\Scripts\activate     # Windows

# Устанавливаем зависимости
pip install -r requirements.txt
```

### Шаг 3: Генерация данных

```bash
# Генерируем тестовые данные для web_events
python python_generate_script.py --password changeme --records 10000
```

### Шаг 4: Открываем Grafana

Откройте в браузере: **http://localhost:3000**

- **Логин**: admin
- **Пароль**: admin123

**Готово!** Вы увидите 4 предустановленных дашборда.

---

## Вариант 2: Полная демонстрация всех методов (15-20 минут)

### Предварительные требования

Установите дополнительные инструменты:

```bash
# macOS
brew install terraform jsonnet kind kubectl

# Linux (Ubuntu/Debian)
# Terraform
wget https://releases.hashicorp.com/terraform/1.6.5/terraform_1.6.5_linux_amd64.zip
unzip terraform_1.6.5_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Jsonnet
sudo apt install jsonnet

# Kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

### Единый демо-скрипт

```bash
# Запускает все генераторы и настраивает все методы
./demo.sh
```

### Или по шагам:

#### 1. Базовая инфраструктура

```bash
docker-compose up -d
source venv/bin/activate
python python_generate_script.py --password changeme --records 10000
```

**Проверка**: http://localhost:3000

#### 2. Terraform метод

```bash
# Генерируем данные для server_metrics
python generate_server_metrics.py --password changeme --records 50000

# Применяем Terraform
cd terraform
terraform init
terraform apply -auto-approve
cd ..
```

**Проверка**: Откройте папку "Terraform Managed" в Grafana

#### 3. Grafonnet метод

```bash
# Генерируем данные для user_sessions
python generate_user_sessions.py --password changeme --records 10000

# Компилируем Jsonnet
cd grafonnet
./build.sh
cd ..

# Перезапускаем Grafana
docker-compose restart grafana
```

**Проверка**: Дашборд "User Sessions Analytics (Grafonnet)"

#### 4. Kubernetes Operator метод

```bash
# Генерируем данные для api_requests
python generate_api_requests.py --password changeme --records 100000

# Создаем Kind кластер
cd kubernetes/scripts
./start-cluster.sh

# Устанавливаем Grafana Operator
./deploy-all.sh
cd ../..
```

**Проверка**: http://localhost:3001 (порт 3001!)

---

## Что вы получите

После полного развертывания у вас будет:

### Данные в ClickHouse

| Таблица | Записей | Описание |
|---------|---------|----------|
| `web_events` | 10,000 | События веб-приложения |
| `server_metrics` | 50,000 | Метрики серверов |
| `user_sessions` | 10,000 | Пользовательские сессии |
| `api_requests` | 100,000 | API запросы |

### Дашборды в Grafana

#### Базовые (JSON + Provisioning)
- ✅ Частота событий
- ✅ Ошибки по типам
- ✅ Latency мониторинг
- ✅ Аномалии ошибок

#### Terraform
- ✅ Server Monitoring

#### Grafonnet
- ✅ User Sessions Analytics

#### Kubernetes (на порту 3001)
- ✅ API Requests Monitoring

---

## Проверка компонентов

### ClickHouse

```bash
# Подключение через CLI
docker exec -it clickhouse clickhouse-client --password changeme

# В CLI:
SHOW TABLES;
SELECT count() FROM web_events;
SELECT count() FROM server_metrics;
SELECT count() FROM user_sessions;
SELECT count() FROM api_requests;
```

### Grafana (Docker Compose)

```bash
# Проверка логов
docker-compose logs grafana

# Статус контейнера
docker ps | grep grafana

# URL: http://localhost:3000
```

### Terraform

```bash
cd terraform
terraform show
terraform output
cd ..
```

### Grafonnet

```bash
# Проверка скомпилированного JSON
ls -la grafana/dashboards/user_sessions.json

# Повторная компиляция
cd grafonnet
./build.sh
cd ..
```

### Kubernetes

```bash
# Статус кластера
kubectl cluster-info

# Ресурсы Grafana
kubectl get all -n grafana-system

# URL: http://localhost:3001
```

---

## Очистка

### Удалить базовые данные

```bash
docker exec -it clickhouse clickhouse-client --password changeme
# В CLI:
DROP TABLE IF EXISTS web_events;
DROP TABLE IF EXISTS server_metrics;
DROP TABLE IF EXISTS user_sessions;
DROP TABLE IF EXISTS api_requests;
```

### Остановить Docker Compose

```bash
# Остановить контейнеры
docker-compose down

# Остановить и удалить volumes
docker-compose down -v
```

### Удалить Terraform ресурсы

```bash
cd terraform
terraform destroy -auto-approve
cd ..
```

### Удалить Kind кластер

```bash
cd kubernetes/scripts
./stop-cluster.sh
cd ../..
```

---

## Troubleshooting

### Порты заняты

```bash
# Проверить порты
lsof -i :3000  # Grafana
lsof -i :3001  # Grafana K8s
lsof -i :8123  # ClickHouse HTTP
lsof -i :9000  # ClickHouse Native

# Остановить процессы
sudo kill -9 <PID>
```

### Docker не работает

```bash
# Проверить Docker
docker --version
docker ps

# Перезапустить Docker
# macOS: Docker Desktop → Restart
# Linux: sudo systemctl restart docker
```

### ClickHouse недоступен

```bash
# Проверить статус
docker ps | grep clickhouse

# Проверить логи
docker-compose logs clickhouse

# Перезапустить
docker-compose restart clickhouse
```

### Grafana не показывает данные

```bash
# 1. Проверить datasource
# Grafana UI → Configuration → Data Sources

# 2. Проверить данные в ClickHouse
docker exec -it clickhouse clickhouse-client --password changeme
SELECT count() FROM web_events;

# 3. Проверить логи Grafana
docker-compose logs grafana | grep -i error
```

---

## Следующие шаги

1. 📖 Изучите [README.md](README.md) для детального обзора
2. 🔧 Попробуйте [TERRAFORM.md](TERRAFORM.md) для IaC подхода
3. 💻 Изучите [GRAFONNET.md](GRAFONNET.md) для программируемых дашбордов
4. ☸️ Ознакомьтесь с [kubernetes/README.md](kubernetes/README.md) для GitOps
5. 🎯 Создайте свои собственные дашборды

---

## Полезные ссылки

- [Главный README](README.md)
- [Terraform документация](TERRAFORM.md)
- [Grafonnet документация](GRAFONNET.md)
- [Kubernetes документация](kubernetes/README.md)
- [ClickHouse документация](https://clickhouse.com/docs/)
- [Grafana документация](https://grafana.com/docs/)
