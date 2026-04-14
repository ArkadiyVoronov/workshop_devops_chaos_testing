# 🚀 Fintech Workshop — Unified Dashboard v2

## ✅ Обновления дашборда

### 1. Частота обновления (Refresh Rate)
- **Обновление**: каждые **2 секунды** (было 5s)
- **Доступные интервалы**: 2s, 5s, 10s, 30s, 1m, 5m, 15m, 30m, 1h
- Можно изменить в выпадающем списке справа от временного диапазона

### 2. Панель по умолчанию
При открытии Grafana автоматически загружается:
- **Название**: 🚀 Fintech Workshop — Unified Dashboard v2
- **UID**: `fintech-unified-dashboard-v2`
- **Временной диапазон**: последние 15 минут (`now-15m` → `now`)

### 3. Все кейсы видны в одном дашборде!

**Не нужно ходить в Prometheus или cAdvisor!** Всё собрано в одном месте:

| Кейс | Что инжектим | Панели на дашборде | Алерт |
|------|--------------|-------------------|-------|
| **Case 1: Latency** | `latency_ms: 2000` | Panel 3: ⏱️ Latency P95/P99 | 🟠 HighLatency |
| **Case 2: Error Rate** | `error_rate: 30` | Panel 4: 🔥 Error Rate % (gauge) | 🔴 HighErrorRate |
| **Case 3: DB Slow** | `db_slow: true` | Panel 5: 💾 Active Transactions<br>Panel 10: Active TX History | 🟡 DBSlowTransactions |
| **Case 4: Memory Leak** | `memory_leak_mb: 5` | Panel 6: 🧠 Memory Usage<br>Panel 9: Memory History | 🟣 MemoryPressure |
| **Case 5: Chaos Mix** | Всё вместе | Все панели выше + Panel 12: Alert Table | Все 4 алерта |

## 📊 Структура дашборда (12 панелей)

### Row 1: ALERTS (y=0, h=4)
- **Panel 1**: 🚨 ACTIVE ALERTS (Firing) — цветовая индикация всех активных алертов

### Row 2: RPS + Latency (y=4, h=8)
- **Panel 2**: 📊 Requests per Second (RPS) — общий трафик
- **Panel 3**: ⏱️ Latency P95/P99 — **Case 1**

### Row 3: KPI Stats (y=12, h=5)
- **Panel 4**: 🔥 Error Rate % — **Case 2** (gauge 0-100%)
- **Panel 5**: 💾 Active Transactions — **Case 3**
- **Panel 6**: 🧠 Memory Usage — **Case 4**
- **Panel 7**: 🔄 Container Restarts

### Row 4: HTTP + Memory (y=17, h=8)
- **Panel 8**: 📈 HTTP Status Codes (2xx vs 5xx)
- **Panel 9**: 🧠 Memory History — **Case 4** (график)

### Row 5: DB + Containers (y=25, h=8)
- **Panel 10**: 💾 Active Transactions History — **Case 3** (график)
- **Panel 11**: 💾 All Containers Memory

### Row 6: Alert Details (y=33, h=8)
- **Panel 12**: 📋 Alert Details Table — полная таблица всех алертов

## 🔄 Как тестировать

### 1. Запустить стек
```bash
cd /workspace
docker compose up -d
```

### 2. Открыть Grafana
- URL: http://localhost:3000
- Логин: `admin`
- Пароль: `workshop`
- **Дашборд загрузится автоматически!**

### 3. Запустить кейсы
```bash
# Case 1: Latency
bash scripts/run_latency.sh

# Case 2: Error Rate
bash scripts/run_error_rate.sh

# Case 3: DB Slow
bash scripts/run_db_slow.sh

# Case 4: Memory Leak
bash scripts/run_memory_leak.sh

# Case 5: Всё вместе (Chaos Mix)
bash scripts/run_chaos_mix.sh
```

### 4. Наблюдать
- Через **2-5 секунд** увидите изменения на графиках
- Через **1-2 минуты** сработают алерты (см. Panel 1)
- Алерты окрасятся в цвета severity:
  - 🟠 Orange: HighLatency (warning)
  - 🔴 Red: HighErrorRate (critical)
  - 🟡 Yellow: DBSlowTransactions (warning)
  - 🟣 Purple: MemoryPressure (critical)

### 5. Сбросить состояние
```bash
curl -X POST http://localhost:5000/api/reset
```

## 🎯 Согласованность

Все PromQL запросы в дашборде **полностью соответствуют**:
- Запросам в документации кейсов
- Алертам в `prometheus.rules.yml`
- Метрикам, которые генерирует приложение

**Пример:**
- Кейс 1 инжектит `latency_ms: 2000` → Panel 3 показывает P95 > 2s → Алерт HighLatency firing
- Кейс 2 инжектит `error_rate: 30` → Panel 4 показывает 30% → Алерт HighErrorRate firing

## 📁 Файлы

- Дашборд: `/workspace/config/grafana/provisioning/dashboards/unified-dashboard.json`
- Провижининг: `/workspace/config/grafana/provisioning/dashboards/dashboard.yaml`
- Алерты: `/workspace/config/prometheus.rules.yml`
- Скрипты: `/workspace/scripts/run_*.sh`
