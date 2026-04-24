# Кейс 4: Утечка памяти

Этот кейс моделирует накопительный ресурсный инцидент, актуальный для долгих праздничных пиков.

## Цель
Проверить, как накапливающиеся ресурсы влияют на стабильность контейнера и что вызывает рестарты.

## Baseline
- Просмотреть `container_memory_usage_bytes` для контейнера app.

## Inject
```bash
bash scripts/04_run_memory_leak.sh
```

## Нагрузка
```bash
# Нагрузка генерируется внутри скрипта
```

## Как наблюдаем
- `container_memory_usage_bytes` (растет с 100 MB до 400-500 MB)
- `container_restart_count`
- `ALERTS{alertname="MemoryPressure"}`

## Пример Prometheus запросов
```sql
-- Память контейнера (в байтах)
container_memory_usage_bytes{container="app"}

-- Прирост памяти за последние 5 минут
rate(container_memory_usage_bytes[5m])

-- Счетчик перезапусков (если есть)
increase(container_restart_count[5m])
```

## Реакция
1. Сброс состояния `/api/reset`.
2. Перезапустить контейнер (если требуется).
3. Обсудить лимиты памяти (-m flag в Docker), OOM-kill и мониторинг утечек в коде.

