# Настройка мониторинга

## Prometheus

### Доступ

- URL: http://localhost:9090
- Конфигурация: `config/prometheus.yml`

Prometheus развёрнут как сервис `prometheus` в `docker-compose.yml` и скрейпит метрики приложения:

```yaml
global:
  scrape_interval: 5s

scrape_configs:
  - job_name: 'fintech-api'
    static_configs:
      - targets: ['app:5000']
    metrics_path: '/metrics'
```


### Полезные запросы (PromQL)

```promql
# RPS (requests per second)
rate(fintech_requests_total[5m])

# P95 latency
histogram_quantile(
  0.95,
  rate(fintech_request_latency_seconds_bucket[5m])
)

# Error rate (доля 5xx)
rate(fintech_requests_total{status="500"}[5m]) / rate(fintech_requests_total[5m])

# Active transactions
fintech_active_transactions
```

### Запись правил (recording rules)

```promql
job:fintech_request_rate:1m
job:fintech_p95_latency:5m
job:fintech_error_rate:5m
```

Эти метрики определены в `app.py`:

- `fintech_requests_total` — счётчик с лейблами `method`, `endpoint`, `status`.
- `fintech_request_latency_seconds` — гистограмма с лейблом `endpoint`.
- `fintech_active_transactions` — gauge активных транзакций.

---

## Алертинг в Prometheus

В этой версии настроены правила алертов (в `config/prometheus.rules.yml`):

- `HighLatency` — p95 > 2s
- `HighErrorRate` — доля 5xx > 10%
- `DBSlowTransactions` — активных транзакций > 10
- `MemoryPressure` — использование памяти > 450 MB

### Проверка алертов

- В Prometheus: `http://localhost:9090/alerts`
- Метрика для алертов: `ALERTS{alertname="HighLatency"}`

### Как использовать

1. Запустить кейс (инъекция отказа).
2. Открыть `http://localhost:9090/alerts`, увидеть статус `firing`.
3. В Grafana добавить панель на основе `ALERTS` или `ALERTS_FOR_STATE`.

---

## Grafana: визуализация метрик

### Доступ

- **URL:** http://localhost:3000
- **Логин:** `admin`
- **Пароль:** `workshop`

Grafana подключена к Prometheus автоматически через provisioning (`config/grafana/provisioning/datasources/prometheus.yaml`).

### Проверка подключения (первый запуск)

1. Откройте http://localhost:3000
2. Залогинитесь `admin/workshop`
3. Перейдите **Configuration → Data sources** (или просто меню слева)
4. Убедитесь, что есть datasource `Prometheus` с статусом `✅ OK`
   - Если ошибка → подождите 30 сек (Prometheus может ещё стартовать)
   - Нажмите **Save & test**

**Ожидаемый результат**: зелёный чек ✅ рядом с `Prometheus` (это значит всё подключено правильно)

### Быстрое создание дашборда (копи-паста запросы)

**Вариант 1: С нуля (за 5 мин)**
1. **Dashboards → New → New dashboard**
2. Добавьте 4 панели (нажимаем **Add panel** 4 раза):
   - **Панель 1: RPS** (запросов в сек)
   - **Панель 2: P95 Latency** (задержка 95% пользователей)
   - **Панель 3: Error Rate** (доля ошибок)
   - **Панель 4: Active Transactions** (текущие запросы)

**Вариант 2: Импорт готового объединённого дашборда (рекомендуется)**
Готовый объединённый дашборд уже в репо: `config/grafana/provisioning/dashboards/unified-dashboard.json`

В Grafana это работает автоматически (provisioning), но если нужен ручной импорт:
1. Откройте Grafana → **Dashboards → Import**
2. Загрузите файл `config/grafana/provisioning/dashboards/unified-dashboard.json`
3. Выберите datasource `Prometheus` → нажмите **Import**

Дашборд содержит 11 панелей с всеми ключевыми метриками и алертами. Подробная документация: `config/grafana/README.md`

### Рекомендуемые панели (copy-paste в Grafana)

**Панель 1: RPS (Requests Per Second)**
```promql
rate(fintech_requests_total[5m])
```
- Что смотрим: линия вверх → нагрузка растёт, вниз → система справляется медленнее

**Панель 2: P95 Latency (задержка для 95% пользователей)**
```promql
histogram_quantile(0.95, rate(fintech_request_latency_seconds_bucket[5m]))
```
- Что смотрим: если > 1 сек → пользователи будут жаловаться на медленность

**Панель 3: Error Rate (доля ошибок в %)**
```promql
rate(fintech_requests_total{status="500"}[5m]) / rate(fintech_requests_total[5m]) * 100
```
- Что смотрим: если > 1% → это уже инцидент, нужно срочно разбираться

**Панель 4: Active Transactions (очередь в системе)**
```promql
fintech_active_transactions
```
- Что смотрим: резкий рост → БД не справляется или очередь растёт → медленнее обрабатывать

### Что должно быть на дашборде во время демо

| Этап | Что видим | Скриншоты в docs/screenshots.md |
| :-- | :-- | :-- |
| **Базовое состояние** | RPS ≈ 0, Latency < 100ms, Error Rate = 0% | Смотрите на дашборде перед кейсом |
| **После кейса Latency** | Latency скачет на 2–3 сек (P95) | `case1_latency.png` |
| **После кейса Error Rate** | Error Rate растёт до 30-50%, RPS может упасть | `case2_error_rate.png` |
| **После кейса DB Slow** | Active Transactions растут выше 10 | `case3_db_slow.png` |
| **После кейса Memory Leak** | Container Memory растёт, может быть рестарт | `case4_memory_leak.png` |
| **После кейса Chaos Mix** | Все метрики нарушены одновременно | `case5_chaos_mix.png` |

```
