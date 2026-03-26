# Кейс 2: Рост error rate

Этот кейс моделирует ситуацию с ухудшением качества запросов под нагрузкой, когда доля 5xx увеличивается.

## Цель
Проанализировать влияние ошибок на доступность и обнаружить причину.

## Baseline
- Посмотреть `rate(fintech_requests_total{status=~"5.."}[5m])` и общий трафик.
- Убедиться, что алерты не в firing.

## Inject
```bash
bash scripts/run_error_rate.sh
```

## Как наблюдаем
- `rate(fintech_requests_total{status=~"5.."}[5m]) / rate(fintech_requests_total[5m])`
- `ALERTS{alertname="HighErrorRate"}`

## Реакция
1. Проверить логи приложения `docker compose logs app --tail 50`.
2. Обсудить пути смягчения (retry, fallback, throttling).
3. Сброс `/api/reset`.

## Постмортем
- Какие зависимости (DB, external) могли вызвать ошибочный ответ?
- Что меняем в продакшене, чтобы уменьшить 5xx?

