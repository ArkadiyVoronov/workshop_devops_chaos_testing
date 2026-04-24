# Чек-лист участника

## Перед началом
- [ ] Открыли Codespaces и запустили терминал
- [ ] Хорошее настроение
- [ ] Склонировали репозиторий и запустили `docker compose up -d --build`
- [ ] Проверили `curl http://localhost:5000/health` (200 OK)
- [ ] Открыли Grafana (`http://localhost:3000`) и Prometheus (`http://localhost:9090`)

## Кейсы (заполняем после каждого)

### 1) Latency
- [ ] Запустили `bash scripts/01_run_latency.sh` в отдельном терминале
- [ ] Проверили p95/p99, RPS в Grafana
- [ ] Сделали скриншот: `docs/screenshots/case1_latency.png`
- [ ] Сбросили через `bash scripts/reset.sh`
- [ ] Заметки: __________________________

### 2) Error Rate
- [ ] Запустили `bash scripts/02_run_error_rate.sh`
- [ ] Проверили `error_count`, `error_rate`
- [ ] Сделали скриншот: `docs/screenshots/case2_error_rate.png`
- [ ] Сбросили через `bash scripts/reset.sh`
- [ ] Заметки: __________________________

### 3) DB Slow
- [ ] Запустили `bash scripts/03_run_db_slow.sh`
- [ ] Проверили `fintech_active_transactions`, задержки
- [ ] Сделали скриншот: `docs/screenshots/case3_db_slow.png`
- [ ] Сбросили через `bash scripts/reset.sh`
- [ ] Заметки: __________________________

### 4) Memory Leak
- [ ] Запустили `bash scripts/04_run_memory_leak.sh`
- [ ] Проверили `container_memory_usage_bytes`, `restarts`
- [ ] Сделали скриншот: `docs/screenshots/case4_memory_leak.png`
- [ ] Сбросили через `bash scripts/reset.sh`
- [ ] Заметки: __________________________

### 5) Chaos Mix
- [ ] Запустили `bash scripts/05_run_chaos_mix.sh`
- [ ] Проверили p95, error rate, active transactions
- [ ] Сделали скриншот: `docs/screenshots/case5_chaos_mix.png`
- [ ] Сбросили через `bash scripts/reset.sh`
- [ ] Заметки: __________________________

## Итог
- [ ] Описали уроки и Runbook
- [ ] Обсудили резервные меры (retry/circuit-breaker/rollback)
