# Кейс 5: Комбинированный отказ (Chaos Mix)

Этот кейс моделирует развитие нескольких проблем одновременно, как на реальном пике трафика.

## Цель
Проверить, как система справляется с несколькими проблемами одновременно, и потренировать быстрое обнаружение.

## Baseline
- Снять метрики latency, error_rate, активные транзакции.

## Inject
```bash
bash scripts/05_run_chaos_mix.sh
```

## Как наблюдаем
- p95/p99 latency (скачет на 2-3 сек)
- error rate (растет до 30-50%)
- `fintech_active_transactions` (растет выше 10)
- `ALERTS` для HighLatency, HighErrorRate и DBSlowTransactions одновременно

## Пример Prometheus запросов
```sql
-- Все основные метрики в одном запросе (добавить на дашборд)
histogram_quantile(0.95, rate(fintech_request_latency_seconds_bucket[5m]))  -- P95
rate(fintech_requests_total{status=~"5.."}[5m])  -- Ошибки в секунду
fintech_active_transactions  -- Активные транзакции
rate(fintech_requests_total[5m])  -- RPS здоровых запросов
```

## Реакция
1. Снять текущее состояние (скриншот дашборда для обсуждения).
2. Обсудить, какие сигналы появились первыми (primary signal).
3. Сброс `/api/reset`.
4. Вывод: какие одиночные кейсы обнаруживаются быстрее, чем комбинированный? Почему?


