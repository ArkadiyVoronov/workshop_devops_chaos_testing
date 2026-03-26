# Кейс 1: Рост latency

Этот кейс моделирует ситуацию, когда во время пикового трафика система начинает медленно отвечать из-за задержек в сервисах.

## Цель
Проверить, как система реагирует на увеличенную задержку и как быстро это видно в метриках.

## Baseline
1. Проверьте `curl http://localhost:5000/health`.
2. Откройте Grafana и посмотрите p95/p99 latency.

## Inject
```bash
bash scripts/run_latency.sh
```

## Как наблюдаем
- `histogram_quantile(0.95, rate(fintech_request_latency_seconds_bucket[5m]))`
- `rate(fintech_requests_total[5m])`
- `ALERTS{alertname="HighLatency"}`

## Реакция
1. Сброс через `/api/reset`.
2. Проверьте, что latency вернулся к норме.
3. Задайте вопрос: какой уровень P95 допустим в вашем SLO?

## Постмортем
- Что было первичным сигналом: рост latency или падение RPS?
- Как снизить impact (кеширование, таймауты, circuit breakers)?

