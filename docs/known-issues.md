# Known Issues

## 1. Memory Leak кейс не показывает рост в docker stats

**Проблема:** При запуске `scripts/04_run_memory_leak.sh` память контейнера не растёт заметно.

**Причина:** 
- Python's garbage collector может освобождать память сразу после завершения запроса
- Flask возвращает память ОС через malloc/free
- Docker stats показывает resident memory, который не всегда отражает выделенную память

**Решение:**
1. Используйте метрику Prometheus `process_resident_memory_bytes` вместо docker stats
2. Увеличьте количество запросов (100+) для заметного эффекта
3. Увеличьте `memory_leak_mb` до 10-20 MB

**Альтернатива:** Добавьте endpoint для принудительного удержания памяти:

```python
@app.route('/api/leak', methods=['POST'])
def force_leak():
    data = request.get_json()
    mb = data.get('mb', 10)
    _leaked_memory.append(bytearray(mb * 1024 * 1024))
    return jsonify({"leaked_mb": mb, "total_leaks": len(_leaked_memory)})
```

---

## 2. Active Transactions показывает 0

**Проблема:** Метрика `fintech_active_transactions` всегда 0 даже при concurrent запросах.

**Причина:**
- Flask в режиме development может обрабатывать запросы последовательно
- Блокировка `_db_lock` слишком короткая

**Решение:**
1. Убедитесь, что `threaded=True` в app.run()
2. Используйте `scripts/03_run_db_slow.sh` который генерирует concurrent запросы
3. Увеличьте задержку БД до 5 секунд

---

## 3. Алерты не сбрасываются после reset

**Проблема:** После `bash scripts/reset.sh` алерты в Grafana остаются в состоянии FIRING.

**Причина:** 
- Prometheus оценивает алерты по окну времени (e.g., `[1m]`)
- Нужно время чтобы метрики вернулись к норме

**Решение:**
1. Подождите 1-2 минуты после reset
2. Принудительно обновите дашборд в Grafana (F5)
3. Проверьте что метрики вернулись к baseline:
   ```bash
   curl 'http://localhost:9090/api/v1/query?query=histogram_quantile(0.95,rate(fintech_request_latency_seconds_bucket[1m]))'
   ```

---

## 4. cAdvisor не показывает метрики контейнеров

**Проблема:** Панели Container Memory/CPU показывают "no data".

**Причина:**
- cAdvisor использует другие лейблы для метрик
- Лейбл `name` может отсутствовать

**Решение:**
1. Проверьте доступные метрики:
   ```bash
   curl 'http://localhost:9090/api/v1/label/__name__/values' | grep container
   ```
2. Обновите запрос в Grafana использовать правильный лейбл:
   - Вместо `name=~".*app.*"` используйте `container_label_com_docker_compose_service="app"`
   - Или используйте `id=~"/docker/.*"`

---

## 5. DB Slow не создаёт очередь транзакций

**Проблема:** `fintech_active_transactions` не растёт при запуске кейса 3.

**Причина:**
- Запросы выполняются быстрее чем 3 секунды (timeout)
- Concurrent запросы не успевают создаться

**Решение:**
1. Увеличьте количество concurrent запросов в скрипте
2. Уменьшите интервал между запросами
3. Проверьте что БД не кэширует запросы

```bash
# Быстрый тест
for i in {1..100}; do curl -s http://localhost:5000/api/balance & done
```
