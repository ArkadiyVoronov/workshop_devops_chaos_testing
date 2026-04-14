# Resource Limits - Защита хост-машины

## Обзор

Все контейнеры в воркшопе имеют ограничения ресурсов, чтобы предотвратить влияние на хост-машину во время тестирования хаоса.

## Лимиты ресурсов

| Сервис | CPU Limit | Memory Limit | Memory Swap |
|--------|-----------|--------------|-------------|
| **app** | 1.0 core | 512 MB | 512 MB |
| **db** (PostgreSQL) | 1.0 core | 512 MB | 512 MB |
| **prometheus** | 0.5 core | 256 MB | 256 MB |
| **grafana** | 0.5 core | 256 MB | 256 MB |
| **cadvisor** | 0.3 core | 128 MB | 128 MB |
| **ИТОГО** | ~3.3 cores | ~1.7 GB | ~1.7 GB |

## Конфигурация

Ограничения настроены в `docker-compose.yml` через директиву `deploy.resources`:

```yaml
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 128M
    memswap_limit: 512M
```

## Проверка лимитов

```bash
# Проверка конфигурации контейнера
docker inspect <container_name> --format '{{.HostConfig.Memory}} {{.HostConfig.NanoCpus}}'

# Мониторинг использования в реальном времени
docker stats

# Проверка через cAdvisor
curl http://localhost:8080/api/v1.2/containers/docker
```

## Почему это важно

### 1. **Memory Leak тестирование**
Кейс #4 (Memory Leak) намеренно создаёт утечку памяти. Без лимитов:
- Контейнер мог бы потребить всю RAM хоста
- Возможны OOM-killer срабатывания
- Риск падения хост-машины

С лимитами:
- Контейнер ограничен 512 MB
- При превышении будет OOM внутри контейнера
- Хост-машина защищена

### 2. **CPU-intensive тесты**
При нагрузочном тестировании:
- Контейнеры не могут использовать 100% CPU хоста
- Остальные процессы на хосте продолжают работать

### 3. **Production-like среда**
В production контейнеры всегда имеют лимиты:
- Kubernetes: `resources.limits`
- Docker Swarm: `--limit-cpu`, `--limit-memory`
- ECS: task definitions

## Мониторинг

### Grafana Dashboard
Откройте "Fintech Workshop Dashboard" → панели:
- **Container Memory Usage** — показывает потребление памяти каждым контейнером
- **Container CPU Usage** — показывает использование CPU

### Prometheus Queries
```promql
# Memory usage по контейнерам
container_memory_usage_bytes{id=~"/docker/.*"}

# CPU usage по контейнерам
rate(container_cpu_usage_seconds_total{id=~"/docker/.*"}[1m])

# Проверка接近 лимита
container_memory_usage_bytes / 512000000  # % от лимита 512MB
```

### Alerts (будущее расширение)
```yaml
# Пример алерта для memory limit
- alert: ContainerMemoryHigh
  expr: container_memory_usage_bytes / 512000000 > 0.9
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "Container {{ $labels.id }} memory usage > 90%"
```

## Troubleshooting

### Контейнер упирается в лимит CPU
```bash
# Проверка throttling
docker exec <container> cat /sys/fs/cgroup/cpu/cpu.stat

# Вывод: throttled_usec показывает время ожидания CPU
```

### Контейнер упирается в лимит памяти
```bash
# Проверка OOM событий
docker inspect <container> --format '{{.State.OOMKilled}}'

# Если true — контейнер был убит за превышение лимита
```

### Увеличение лимитов (если нужно)
Отредактируйте `docker-compose.yml`:
```yaml
deploy:
  resources:
    limits:
      cpus: '2.0'      # увеличить CPU
      memory: 1024M    # увеличить RAM
```

Затем:
```bash
docker compose up -d
```

## Best Practices

1. **Всегда устанавливайте лимиты** — даже для dev/test сред
2. **Мониторьте использование** — через Grafana/cAdvisor
3. **Тестируйте с лимитами** — как в production
4. **Оставляйте запас** — лимиты должны быть выше нормального потребления на 30-50%
5. **Документируйте** — почему выбраны именно такие значения

---

**Примечание:** Для кейса "Memory Leak" лимит в 512 MB достаточен, чтобы продемонстрировать проблему, но недостаточен для падения хоста.
