# Kubernetes с Grafana Operator

Этот модуль демонстрирует GitOps подход к управлению дашбордами Grafana через Kubernetes и Grafana Operator.

## Обзор

- **Kind** - локальный Kubernetes кластер в Docker
- **Grafana Operator** - управление Grafana через Kubernetes Custom Resources
- **Декларативная конфигурация** - дашборды и datasources как YAML манифесты

## Предварительные требования

### Необходимые инструменты

1. **Docker** - для запуска Kind кластера
2. **Kind** >= 0.20.0 - Kubernetes in Docker
3. **kubectl** >= 1.28 - CLI для Kubernetes

### Установка

#### macOS
```bash
brew install kind kubectl
```

#### Linux (Ubuntu/Debian)
```bash
# Kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

#### Проверка установки
```bash
kind version
kubectl version --client
docker --version
```

## Быстрый старт

### 1. Создание Kind кластера

```bash
cd kubernetes/scripts
chmod +x *.sh
./start-cluster.sh
```

Этот скрипт:
- Создает Kind кластер с именем `grafana-demo`
- Настраивает проброс портов (30300 -> 3001)
- Проверяет готовность узлов

### 2. Установка Grafana Operator и ресурсов

```bash
./deploy-all.sh
```

Этот скрипт устанавливает:
- Namespace `grafana-system`
- Custom Resource Definitions (CRDs)
- Grafana Operator
- Grafana инстанс с плагином ClickHouse
- ClickHouse datasource
- API Requests дашборд

**Примечание:** Установка занимает 2-3 минуты (загрузка образов и плагинов).

### 3. Доступ к Grafana

Kind автоматически пробрасывает порт через NodePort:

```bash
# Grafana доступна по адресу
open http://localhost:3001

# Логин: admin
# Пароль: admin123
```

Альтернативно, используйте port-forward:

```bash
./port-forward.sh
```

### 4. Удаление кластера

```bash
./stop-cluster.sh
```

## Структура проекта

```
kubernetes/
├── kind-config.yaml              # Конфигурация Kind кластера
├── namespace.yaml                # Namespace grafana-system
├── grafana-crds.yaml            # Custom Resource Definitions
├── grafana-operator.yaml        # Grafana Operator deployment
├── grafana-instance.yaml        # Grafana инстанс
├── clickhouse-datasource.yaml   # Datasource как CR
├── api-requests-dashboard.yaml  # Dashboard как CR
├── scripts/
│   ├── start-cluster.sh         # Создание кластера
│   ├── deploy-all.sh            # Установка всех компонентов
│   ├── stop-cluster.sh          # Удаление кластера
│   └── port-forward.sh          # Проброс портов
└── README.md                     # Эта документация
```

## Создаваемый дашборд

### API Requests Monitoring (K8s Operator)

Дашборд для мониторинга API запросов из таблицы `api_requests`:

**Панели:**

1. **Requests per Second** - RPS по HTTP методам (time series)
2. **Status Codes Distribution** - распределение статус кодов (bar chart)
3. **Response Time Percentiles** - перцентили времени ответа p50, p90, p95, p99
4. **Slowest Endpoints** - самые медленные endpoints (table)
5. **Error Rate by Endpoint** - процент ошибок по endpoints (stat panels)
6. **Статистика (нижний ряд):**
   - Total Requests (24h)
   - Avg Response Time
   - Error Rate (24h)
   - Success Rate (24h)

**Характеристики:**
- Период: последние 24 часа
- Автообновление: каждые 30 секунд
- Теги: kubernetes, api, monitoring
- UID: k8s-api-requests

## Работа с ресурсами

### Просмотр ресурсов Grafana

```bash
# Все ресурсы в namespace
kubectl get all -n grafana-system

# Grafana Custom Resources
kubectl get grafana -n grafana-system
kubectl get grafanadatasource -n grafana-system
kubectl get grafanadashboard -n grafana-system

# Детальная информация
kubectl describe grafana grafana-k8s -n grafana-system
```

### Просмотр логов

```bash
# Логи Grafana Operator
kubectl logs -n grafana-system -l app=grafana-operator -f

# Логи Grafana
kubectl logs -n grafana-system -l app=grafana -f
```

### Редактирование ресурсов

```bash
# Редактировать dashboard
kubectl edit grafanadashboard api-requests-dashboard -n grafana-system

# Редактировать datasource
kubectl edit grafanadatasource clickhouse-datasource -n grafana-system

# Применить изменения из файла
kubectl apply -f api-requests-dashboard.yaml
```

### Удаление ресурсов

```bash
# Удалить dashboard
kubectl delete grafanadashboard api-requests-dashboard -n grafana-system

# Удалить datasource
kubectl delete grafanadatasource clickhouse-datasource -n grafana-system

# Удалить всё
kubectl delete namespace grafana-system
```

## Создание собственных дашбордов

### Способ 1: YAML манифест

Создайте файл `my-dashboard.yaml`:

```yaml
apiVersion: grafana.integreatly.org/v1beta1
kind: GrafanaDashboard
metadata:
  name: my-dashboard
  namespace: grafana-system
spec:
  instanceSelector:
    matchLabels:
      dashboards: "grafana-k8s"
  json: |
    {
      "title": "My Custom Dashboard",
      "panels": [...]
    }
```

Примените:

```bash
kubectl apply -f my-dashboard.yaml
```

### Способ 2: Экспорт из Grafana UI

1. Создайте дашборд в Grafana UI
2. Экспортируйте JSON (Settings → JSON Model)
3. Создайте YAML манифест с этим JSON
4. Примените через kubectl

### Способ 3: ConfigMap

```yaml
apiVersion: grafana.integreatly.org/v1beta1
kind: GrafanaDashboard
metadata:
  name: dashboard-from-configmap
  namespace: grafana-system
spec:
  instanceSelector:
    matchLabels:
      dashboards: "grafana-k8s"
  configMapRef:
    name: my-dashboard-configmap
    key: dashboard.json
```

## Подключение к внешнему ClickHouse

Если ClickHouse работает не в Docker, а в другом месте:

Отредактируйте `clickhouse-datasource.yaml`:

```yaml
jsonData:
  server: your-clickhouse-host.com
  port: 9000
  protocol: native
  secure: false  # или true для TLS
  username: default
  defaultDatabase: default
secureJsonData:
  password: your-password
```

Примените изменения:

```bash
kubectl apply -f clickhouse-datasource.yaml
```

## GitOps workflow

### Базовый workflow

1. Изменить YAML манифесты в Git
2. Применить через kubectl:
   ```bash
   kubectl apply -f kubernetes/
   ```
3. Operator автоматически обновит Grafana

### С ArgoCD

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: grafana-dashboards
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/your-repo
    targetRevision: HEAD
    path: kubernetes
  destination:
    server: https://kubernetes.default.svc
    namespace: grafana-system
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### С Flux CD

```yaml
apiVersion: source.toolkit.fluxcd.io/v1beta1
kind: GitRepository
metadata:
  name: grafana-dashboards
  namespace: flux-system
spec:
  interval: 1m
  url: https://github.com/your-org/your-repo
  ref:
    branch: main
---
apiVersion: kustomize.toolkit.fluxcd.io/v1beta1
kind: Kustomization
metadata:
  name: grafana-dashboards
  namespace: flux-system
spec:
  interval: 5m
  path: ./kubernetes
  prune: true
  sourceRef:
    kind: GitRepository
    name: grafana-dashboards
```

## Мониторинг Operator

### Метрики Operator

Operator предоставляет метрики на порту 8080:

```bash
# Port-forward для метрик
kubectl port-forward -n grafana-system \
  deploy/grafana-operator 8080:8080

# Получить метрики
curl http://localhost:8080/metrics
```

### Health checks

```bash
# Liveness probe
kubectl port-forward -n grafana-system \
  deploy/grafana-operator 8081:8081

curl http://localhost:8081/healthz
curl http://localhost:8081/readyz
```

## Troubleshooting

### Дашборд не появляется

```bash
# Проверить статус dashboard
kubectl get grafanadashboard -n grafana-system
kubectl describe grafanadashboard api-requests-dashboard -n grafana-system

# Проверить логи operator
kubectl logs -n grafana-system -l app=grafana-operator --tail=50
```

### Datasource не работает

```bash
# Проверить статус datasource
kubectl describe grafanadatasource clickhouse-datasource -n grafana-system

# Проверить, что ClickHouse доступен из кластера
kubectl run -it --rm debug --image=alpine --restart=Never -- sh
# В контейнере:
apk add curl
curl http://host.docker.internal:8123
```

### Grafana не стартует

```bash
# Проверить статус pod
kubectl get pods -n grafana-system
kubectl describe pod -n grafana-system -l app=grafana

# Логи Grafana
kubectl logs -n grafana-system -l app=grafana

# События в namespace
kubectl get events -n grafana-system --sort-by='.lastTimestamp'
```

### Оператор не работает

```bash
# Проверить CRDs
kubectl get crd | grep grafana

# Переустановить operator
kubectl delete -f grafana-operator.yaml
kubectl apply -f grafana-operator.yaml

# Проверить RBAC
kubectl auth can-i create grafanadashboards \
  --as=system:serviceaccount:grafana-system:grafana-operator \
  -n grafana-system
```

### Kind кластер не создается

```bash
# Проверить Docker
docker ps

# Удалить старые кластеры
kind get clusters
kind delete cluster --name grafana-demo

# Проверить порты
lsof -i :3001
lsof -i :30300
```

## Продвинутые сценарии

### Мультитенантность

Создайте отдельные Grafana инстансы для разных команд:

```yaml
apiVersion: grafana.integreatly.org/v1beta1
kind: Grafana
metadata:
  name: grafana-team-a
  namespace: team-a
spec:
  config:
    security:
      admin_user: team-a-admin
```

### Внешний доступ через Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana-ingress
  namespace: grafana-system
spec:
  rules:
    - host: grafana.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: grafana-service
                port:
                  number: 3000
```

### Персистентное хранилище

```yaml
apiVersion: grafana.integreatly.org/v1beta1
kind: Grafana
metadata:
  name: grafana-k8s
spec:
  persistentVolumeClaim:
    spec:
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 10Gi
```

### Автоматическое резервное копирование

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: grafana-backup
  namespace: grafana-system
spec:
  schedule: "0 2 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: backup
              image: appropriate/curl
              command:
                - /bin/sh
                - -c
                - |
                  curl -u admin:admin123 \
                    http://grafana-service:3000/api/dashboards/* \
                    > /backup/dashboards-$(date +%Y%m%d).json
```

## Сравнение методов

| Метод | Сложность | GitOps | CI/CD | Масштаб |
|-------|-----------|--------|-------|---------|
| JSON + Provisioning | Низкая | ✓ | ✓ | Малый |
| Terraform | Средняя | ✓ | ✓✓ | Средний |
| Grafonnet | Высокая | ✓✓ | ✓✓ | Большой |
| **K8s Operator** | **Средняя** | **✓✓✓** | **✓✓✓** | **Большой** |

## Полезные ссылки

- [Kind Documentation](https://kind.sigs.k8s.io/)
- [Grafana Operator](https://github.com/grafana-operator/grafana-operator)
- [Grafana Operator Documentation](https://grafana-operator.github.io/grafana-operator/)
- [Kubernetes CRDs](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/)
- [GitOps Principles](https://opengitops.dev/)

## Следующие шаги

1. Попробуйте создать свой дашборд через CRD
2. Настройте CI/CD для автоматического деплоя
3. Интегрируйте с ArgoCD или Flux
4. Добавьте мониторинг самого Operator
5. Настройте резервное копирование дашбордов
