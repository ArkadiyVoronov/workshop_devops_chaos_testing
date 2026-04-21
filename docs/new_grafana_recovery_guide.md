# Руководство по восстановлению Grafana дашбордов

Версия: v2.0 (для презентации)
Дата: 2026-04-20

## 1. Быстрое восстановление Grafana

### 1.1 Проверка статуса
```bash
# Статус контейнера
docker compose ps grafana

# Логи Grafana
docker logs workshop_devops_chaos_testing-grafana-1 -f

# Health check
curl -f http://localhost:3000/api/health || echo "Grafana down"
```

### 1.2 Перезапуск Grafana
```bash
# Быстрый перезапуск
docker compose restart grafana

# Полный рестарт с проверкой
docker compose stop grafana
sleep 5
docker compose up -d grafana
sleep 10
docker compose ps grafana
```

### 1.3 Восстановление данных
```bash
# Если потеряны дашборды - восстановление из provisioning
docker compose down grafana
docker volume rm workshop_devops_chaos_testing_grafana_data
docker compose up -d grafana

# Дашборды восстановятся из ./config/grafana/provisioning
```

## 2. Проверка дашбордов

### 2.1 Доступность
```
URL: http://localhost:3000
Логин: admin
Пароль: workshop

Проверить:
✅ Login работает
✅ 16 дашбордов отображаются  
✅ Prometheus datasource подключен
✅ Метрики обновляются (каждые 3-5 секунд)
```

### 2.2 Основные дашборды для демонстрации:

#### Dashboard 1: System Overview
```
Метрики:
- CPU usage (host + containers)
- Memory usage (host + containers) 
- Disk I/O (sda)
- Network throughput

Пороги:
- CPU >80%: Красный
- Memory >70%: Желтый
- I/O Wait >20%: Желтый
```

#### Dashboard 2: Application Metrics
```
Метрики app:5000:
- HTTP requests/sec
- Response time (p50, p95, p99)
- Error rate (4xx, 5xx)
- Active connections

Пороги:
- Error rate >1%: Красный
- p99 >500ms: Желтый
- Requests/sec >100: Зеленый
```

#### Dashboard 3: Database Metrics
```
PostgreSQL метрики:
- Connections (active, idle)
- Query latency
- Transactions/sec
- Cache hit ratio

Пороги:
- Connections >80%: Желтый
- Cache hit <95%: Красный
- Query latency >100ms: Желтый
```

### 2.3 Настройка дашбордов (если нужно)

#### Добавление нового дашборда:
```
1. Grafana UI → Dashboards → New → Import
2. JSON файл из ./config/grafana/dashboards/
3. Или создать вручную через UI
```

#### Изменение переменных:
```
В Grafana UI:
Dashboards → Settings → Variables
- instance: выбор контейнера
- job: выбор сервиса
- interval: время обновления (5s для demo)
```

## 3. Проверка алертов

### 3.1 Существующие алерты:

#### Alert 1: High CPU Usage
```
Условие: CPU > 80% в течение 2 минут
Действие: Отправка в Slack/Email
Метрики: host_cpu_usage, container_cpu_usage
```

#### Alert 2: High Memory Usage
```
Условие: Memory > 90% в течение 1 минуты
Действие: Critical alert
Метрики: host_memory_usage, container_memory_usage
```

#### Alert 3: High Error Rate
```
Условие: HTTP errors > 5% в течение 30 секунд
Действие: Warning → Critical
Метрики: http_requests_total{status=~"4..|5.."}
```

#### Alert 4: Database Connection Issues
```
Условие: DB connections > 90% max
Действие: Warning
Метрики: pg_stat_database_connections
```

### 3.2 Тестирование алертов:

#### Тест 1: CPU Alert
```bash
# Создать нагрузку на CPU
stress --cpu 2 --timeout 120s &

# Проверить alert в Grafana Alerting
# Ожидается: Warning alert через 2 минуты
```

#### Тест 2: Memory Alert
```bash
# Нагрузить память
stress --vm 1 --vm-bytes 6G --timeout 60s &

# Проверить: Critical alert через 1 минуту
```

#### Тест 3: Error Rate Alert
```bash
# Создать ошибки в app
curl -X POST http://localhost:5000/api/error-endpoint -d '{}' &

# Проверить: Warning alert через 30 секунд
```

### 3.3 Настройка алертов (если нужно):

#### В Grafana UI:
```
1. Alerting → Alert rules → New rule
2. Выбрать datasource (Prometheus)
3. Условие: Query → A > threshold
4. Labels: severity=warning/critical
5. Annotations: summary="High CPU detected"
```

#### Пример Prometheus Alert rule:
```yaml
groups:
- name: cpu_alerts
  rules:
  - alert: HighCPUUsage
    expr: host_cpu_usage > 80
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: "High CPU usage on {{ $labels.instance }}"
      description: "CPU usage is above 80% for more than 2 minutes"
```

## 4. Troubleshooting

### 4.1 Grafana не запускается:
```bash
# Логи
docker logs workshop_devops_chaos_testing-grafana-1

# Проверка порта
netstat -tulpn | grep 3000

# Перезапуск
docker compose restart grafana
```

### 4.2 Дашборды пустые:
```bash
# Проверить Prometheus datasource
curl http://localhost:9090/api/v1/targets

# Проверить scrape targets
curl http://localhost:9090/api/v1/status/config

# Перезагрузить дашборды из provisioning
docker compose restart grafana
```

### 4.3 Метрики не обновляются:
```bash
# Проверить интервал сбора
curl http://localhost:9090/api/v1/status/config | jq '.global.scrape_interval'

# Проверить, что app экспортирует метрики
curl http://localhost:5000/metrics

# Перезапустить Prometheus
docker compose restart prometheus
```

### 4.4 Алерт не срабатывает:
```bash
# Проверить alert rules
curl http://localhost:9090/api/v1/alerts

# Проверить уведомления
docker logs workshop_devops_chaos_testing-grafana-1 | grep alert

# Тест алерта вручную
curl -X POST http://localhost:9090/-/reload
```

## 5. Быстрая проверка перед презентацией

### 5.1 Checklist:
```
[ ] Grafana доступна: http://localhost:3000
[ ] Все 16 дашбордов отображаются
[ ] Prometheus datasource green
[ ] Метрики обновляются (проверить CPU график)
[ ] Алерт rules активны (Alerting → Alert rules)
[ ] Health checks работают (docker compose ps)
[ ] Нет ошибок в логах (docker logs)
```

### 5.2 Быстрый тест:
```bash
# 1. Проверить все сервисы
docker compose ps

# 2. Проверить метрики
curl http://localhost:5000/metrics | head -10

# 3. Проверить Grafana
curl -u admin:workshop -H "Accept: application/json" \
  http://localhost:3000/api/dashboards/home

# 4. Проверить алерты
curl http://localhost:9090/api/v1/alerts | jq '.[] | select(.state=="firing")'
```

---

*Руководство для быстрого восстановления Grafana в workshop_devops_chaos_testing*
*Версия 2.0 | 2026-04-20*