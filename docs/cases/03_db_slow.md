# Кейс 3: Медленная БД

Этот кейс моделирует нагрузочный сценарий, в котором БД начинает медленно обрабатывать транзакции и увеличивается очередь.

## Цель
Понять, как отклонения в БД отражаются в метриках и как находить узкие места.

## Baseline
- `fintech_active_transactions`
- Время ответа API

## Inject
```bash
bash scripts/03_run_db_slow.sh
```

## Как наблюдаем
- `fintech_active_transactions` (растет выше 10)
- RPS и latency (оба падают)
- `ALERTS{alertname="DBSlowTransactions"}`

## Пример Prometheus запросов
```sql
-- Активные транзакции растут
fintech_active_transactions

-- Latency растет из-за очереди в БД
histogram_quantile(0.95, rate(fintech_request_latency_seconds_bucket[5m]))

-- Полные транзакции в секунду падают
rate(fintech_requests_total{endpoint="/api/transfer"}[5m])
```

## Реакция
1. Остановить инъекцию через `/api/reset`.
2. Проверить, уменьшилось ли количество активных транзакций.
3. Обсудить меры: индексирование, пул соединений, кэш, read replicas.

