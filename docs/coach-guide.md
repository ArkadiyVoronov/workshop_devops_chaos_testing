# Руководство для тренера (1,5 часа)

## Быстрый старт (5 мин)
```bash
docker compose up -d --build
bash scripts/check_setup.sh
# Проверить: http://localhost:9090 (Prometheus), http://localhost:3000 (Grafana: admin/workshop)
```

## План (90 мин)

| Раздел | Время | Что делать |
|--------|-------|-----------|
| Введение | 10 м | Архитектура, цели, метрики |
| Запуск | 10 м | Docker + проверка сервисов |
| Кейсы 1-5 | 60 м | По 12 мин: baseline → inject → detect → respond → recover |
| Итоги | 10 м | Выводы + вопросы |

## Цикл для каждого кейса (12 мин)

1. **BASELINE** — Смотрим на дашборд (RPS=0, P95<100ms, Error=0%)
2. **INJECT** — Запускаем `bash scripts/run_[case].sh`
3. **DETECT** — Наблюдаем метрики (Prometheus обновляет каждые 2 сек)
4. **RESPOND** — Обсуждаем: "circuit breaker? retry? timeout?"
5. **RECOVER** — `curl -X POST /api/reset` (вернётся за 10-15 сек)

## Ключевые метрики

| Метрика | Нормально | Проблема | Действие |
|---------|----------|---------|---------|
| P95/P99 latency | <100ms | >2 сек | Оптимизировать код/БД |
| Error Rate | 0% | >10% | Найти источник ошибок |
| Active Transactions | <5 | >10 | Увеличить пул/оптимизировать запросы |
| Container Memory | 100-200 MB | >450 MB | Перезапустить/искать утечку |
| Алерты | ❌ | 🔴 | **Действуй сразу!** |

## Скрипты кейсов

```bash
# Кейс 1: Latency (медленный API)
bash scripts/run_latency.sh
# Смотрим: P95/P99 скачет на 2+ сек, RPS может упасть

# Кейс 2: Error Rate (много ошибок)
bash scripts/run_error_rate.sh
# Смотрим: Error % = 30-50%, красные графики

# Кейс 3: DB Slow (БД не справляется)
bash scripts/run_db_slow.sh
# Смотрим: Active Transactions > 10, latency растет

# Кейс 4: Memory Leak (утечка памяти)
bash scripts/run_memory_leak.sh
# Смотрим: Memory 100MB → 500MB, может рестарт

# Кейс 5: Chaos Mix (несколько проблем сразу)
bash scripts/run_chaos_mix.sh
# Смотрим: Все метрики ломаются одновременно
```

## Что спросить у участников

- "Какой первый сигнал проблемы?" (P95? Error Rate? Active Transactions?)
- "Как вы реагируете?" (Circuit breaker? Retry? Fallback?)
- "Как долго восстанавливается?" (10 сек? 1 мин? 5 мин?)
- "В проде вы даже бы узнали об этом?" (автоматизировать? алерты?)

## Полезные команды

```bash
# Одновременно запустить latency и наблюдать
# Терминал 1:
bash scripts/run_latency.sh

# Терминал 2:
curl http://localhost:9090/api/v1/query?query=fintech_requests_total

# Сброс всегда после кейса:
curl -X POST http://localhost:5000/api/reset
```

## После воркшопа

- Участники получат: понимание BASELINE→INJECT→DETECT→RESPOND→RECOVER
- Главный урок: **метрики = язык инцидентов**
- Runbook для вашей системы: "когда P95 > X, делаем Y"
