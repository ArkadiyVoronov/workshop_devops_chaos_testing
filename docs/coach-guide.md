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


## 🎓 Для ведущего/Инструктора

### ⏱️ Временная раскладка (1,5 часа)

```
⏱️  5 мин  → Слайд 1: Почему финансовые системы должны быть надёжными?
   - Примеры: банк недоступен 1 час = 100 млн$ убытков
   - Наш сценарий: платёжная система FinCore перед "чёрной пятницей"

⏱️  5 мин  → Слайд 2: Что мы будем мониторить (метрики)
   - RPS (requests per second) — нагрузка
   - Latency (P95/P99) — задержка пользователя
   - Error Rate — доля ошибок
   - Active Transactions — очередь в БД

⏱️  5 мин  → Слайд 3: Архитектура (Flask → PostgreSQL → Prometheus → Grafana)
   - Показать диаграмму из docs/architecture.md
   - Рассказать про `/metrics` endpoint

⏱️ 10 мин → **Быстрая подготовка (live demo)**
   - Выполнить `docker compose up -d --build`
   - Проверить: `curl http://localhost:5000/health`
   - Открыть Grafana http://localhost:3000
   - Создать дашборд с 4 панелями (RPS, P95, Error Rate, Active Tx)

⏱️ 12 мин → **Кейс 1: Latency** 
   - Слайд 4: "Что если бэкенд медленный?"
   - Команда: `bash scripts/run_latency.sh`
   - Показать: P95 растёт, RPS падает, пользователи теряют доверие
   
⏱️ 12 мин → **Кейс 2: Error Rate**
   - Слайд 5: "Что если 30% платежей падают?"
   - Команда: `bash scripts/run_error_rate.sh`
   - Показать: Error Rate скачет, аудитория паникует 😅
   
⏱️ 12 мин → **Кейс 3: DB Slow**
   - Слайд 6: "Что если БД не справляется?"
   - Команда: `bash scripts/run_db_slow.sh`
   - Показать: Active Transactions растут → система "замораживается"
   
⏱️ 12 мин → **Кейс 4: Memory Leak**
   - Слайд 7: "Что если приложение ест всю ОЗУ?"
   - Команда: `bash scripts/run_memory_leak.sh`
   - Показать: Контейнер может упасть (очень редко во время демо)
   
⏱️ 12 мин → **Кейс 5: Chaos Mix** (если осталось время)
   - Слайд 8: "Всё ломается одновременно"
   - Команда: `bash scripts/run_chaos_mix.sh`
   - Показать полный коллапс системы

⏱️ 15 мин → **Q&A и выводы (Слайд 9)**
   - "Как вы реагировали бы на такое?"
   - "Какие паттерны спасают? (circuit breaker, retry, timeout)"
   - "Как настроить алерты в вашей системе?"
```

### 📋 Чек-лист ведущего перед демо

- [ ] **За час до начала:**
  ```bash
  docker compose up -d --build
  bash scripts/check_setup.sh      # должно вывести ✅ всё хорошо
  ```

- [ ] **За 10 мин:**
  - Открыть Grafana http://localhost:3000 в браузере
  - Залогиниться `admin/workshop`
  - Создать новый дашборд с 4 панелями (или использовать готовый)
  - Убедиться, что метрики приходят

- [ ] **Между кейсами:**
  ```bash
  bash scripts/reset.sh            # очистить состояние
  sleep 5                          # подождать 5 сек
  # затем начинать следующий кейс
  ```

- [ ] **Если что-то упало:**
  ```bash
  docker compose logs app          # посмотреть логи
  docker compose restart app       # перезагрузить контейнер
  ```

### 💬 Шпаргалка для рассказа (каждый кейс)

1. **BASELINE** → "Сейчас система здоровая. Посмотрите: P95 < 100ms, Error Rate = 0%, RPS стабилен"
2. **INJECT** → "Сейчас я запущу кейс. Что, по-вашему, произойдёт?" (спросить аудиторию)
3. **DETECT** → "Видите? P95 скачнул на 2 сек! Это означает, что 95% пользователей ждут 2 секунды"
4. **RESPOND** → "Если бы вы были SRE, что бы вы делали сейчас? (пауза для обсуждения)"
5. **RECOVER** → "Сейчас сбросим состояние. (выполнить reset) И система вернулась в норму"



---

## 🔧 Решение проблем (для ведущего)

### Проблемы при старте

| Проблема | Первый шаг | Решение |
|----------|-----------|---------|
| Контейнеры долго стартуют | Подождите 30–60 сек | `docker compose ps` — ждём `health: healthy` |
| `app` не запускается | `docker compose logs app` | Нужна Python 3.11+, Flask, psycopg2 |
| БД не подключается | `docker compose logs db` | Убедиться, что postgresql стартовал |
| Grafana не грузит метрики | Перезагрузить браузер | Проверить Grafana → Configuration → Data sources |
| Prometheus `Down` | Перезагрузить: `docker compose restart prometheus` | Проверить `docker compose ps` |

### Проблемы во время демо

| Проблема | Причина | Решение |
|----------|--------|---------|
| Метрики не растут после `run_latency.sh` | cAdvisor не обновляет метрики | Подождать 20–30 секунд |
| Контейнер упал (memory leak) | OOM kill | `docker compose logs app`, `docker compose up -d` |
| Нельзя сбросить состояние | `/api/reset` не отвечает | Перезагрузить контейнер: `docker compose restart app` |
| Порт 5000/3000 занят на хосте | Конфликт с локальным приложением | `lsof -i :5000` и завершить процесс, или изменить port в docker-compose.yml |

### Краткий runbook для ведущего
```bash
# 1) Проверка сервисов при старте
curl http://localhost:5000/health
curl -s http://localhost:9090/-/healthy
docker compose ps

# 2) Быстро посмотреть метрики в Prometheus
curl -s http://localhost:9090/api/v1/query?query=up

# 3) Быстро сбросить всё после демо
curl -X POST http://localhost:5000/api/reset

# 4) Посмотреть логи приложения
docker compose logs app --tail 50 -f
```


