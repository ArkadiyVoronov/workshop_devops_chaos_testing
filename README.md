# Fintech DevOps Workshop

> Интерактивный воркшоп по тестированию отказоустойчивости финтех-приложений с использованием Docker, Prometheus и Grafana.

## Содержание

- [Быстрый старт](#быстрый-старт)
- [Доступные сервисы](#доступные-сервисы)
- [Структура воркшопа](#структура-воркшопа)
- [Практические кейсы](#практические-кейсы)
- [Управление инфраструктурой](#управление-инфраструктурой)
- [Дополнительная документация](#дополнительная-документация)
- [Требования](#требования)
- [Лицензия](#лицензия)

---

## ⚡ Быстрый старт

### 🚀 Способ 1: GitHub Codespaces (самый быстрый, 3 минуты)
Не нужно ничего устанавливать — всё работает в браузере:
1. Откройте репозиторий на GitHub
2. Нажмите **Code → Codespaces → Create codespace on main**
3. Дождитесь загрузки (первый раз ≈ 2 минуты)
4. В терминале выполните:
   ```bash
   docker compose up -d --build
   bash scripts/check_setup.sh
   ```
5. Откройте ссылки на Grafana (3000) и Prometheus (9090)

### 📦 Способ 2: Локально с Docker
```bash
git clone <repo>
cd workshop_devops_with_app
docker compose up -d --build
bash scripts/check_setup.sh
```

### 🎯 Способ 3: Replit (встроенная БД, без Docker)
Нажмите на кнопку **"Run"** в Replit — приложение запустится сразу на порту 5000.

---

## 🎬 Запуск первого кейса (5 минут)

### Базовая проверка
```bash
# Проверить здоровье сервисов
curl http://localhost:5000/health

# Открыть дашборды
# Prometheus:  http://localhost:9090
# Grafana:     http://localhost:3000 (admin/workshop)
# cAdvisor:    http://localhost:8080
```

### Инъекция отказа (пример: latency)
```bash
# Способ 1: через скрипт
bash scripts/run_latency.sh

# Способ 2: прямой curl (если нужна кастомизация)
curl -X POST http://localhost:5000/api/failures \
  -H "Content-Type: application/json" \
  -d '{"latency_ms": 3000}'
```

### Мониторинг в Grafana
- Откройте Grafana → просмотрите метрики latency (`fintech_request_latency_seconds_bucket`)
- Посмотрите p95/p99 в запросе:
  ```
  histogram_quantile(0.95, rate(fintech_request_latency_seconds_bucket[1m]))
  ```

### Сброс после кейса
```bash
bash scripts/reset.sh
# или: curl -X POST http://localhost:5000/api/reset
```
"Приложение специально написано без паттернов устойчивости (Circuit Breaker, Retry, Bulkhead), чтобы участники могли наблюдать 'голый' сбой и предлагать свои решения по защите."


## 📖 Информация

- **Архитектура**: `docs/architecture.md`  
- **Практические кейсы**: `docs/cases/`

---

## Доступные сервисы

| Сервис | URL | Назначение | Учётные данные |
| :-- | :-- | :-- | :-- |
| **Fintech API** | http://localhost:5000 | Основное приложение | — |
| **Prometheus** | http://localhost:9090 | Сбор и хранение метрик | — |
| **cAdviser** | http://localhost:8080 | Сбор и хранение метрик | — |
| **Grafana** | http://localhost:3000 | Визуализация метрик | `admin` / `workshop` |

---

![Схема приложения](/docs/screenshots/architecture_diagram.png)
---

## Структура проекта

```text
workshop_devops_with_app/
├── docs/
│   ├── architecture.md          # Цели, целевая аудитория, требования, методология
│   ├── coach-guide.md           # Подробное руководство для тренера
│   ├── presentation.md          # Описание воркшопа для презентации (план, кейсы, компоненты)
│   ├── monitoring.md            # Prometheus, Grafana, дашборды и запросы
│   ├── testing_philosophy.md    # Зачем observability и chaos engineering
│   ├── curl_guide.md            # Как использовать curl в кейсах
│   ├── api-endpoints.md         # Описание всех endpoint'ов API
│   ├── scripts.md               # Описание bash-скриптов для кейсов
│   ├── screenshots.md           # Каталог скриншотов и где их использовать
│   ├── cases/                   # 5 практических кейсов (01_latency.md .. 05_chaos_mix.md)
│   └── screenshots/             # Скриншоты для документации
├── config/
│   ├── prometheus.yml           # Конфигурация сборки метрик
│   ├── prometheus.rules.yml     # Правила алертов
│   └── grafana/                 # Provisioning datasources и дашбордов
├── scripts/
│   ├── check_setup.sh           # Проверка готовности всех сервисов
│   ├── run_latency.sh           # Кейс 1: инъекция latency
│   ├── run_error_rate.sh        # Кейс 2: инъекция error rate
│   ├── run_db_slow.sh           # Кейс 3: инъекция медленной БД
│   ├── run_memory_leak.sh       # Кейс 4: инъекция memory leak
│   ├── run_chaos_mix.sh         # Кейс 5: комбинированный отказ
│   └── reset.sh                 # Сброс всех инъекций
├── app.py                       # Flask API с инъекцией отказов
├── docker-compose.yml           # Конфигурация инфраструктуры
├── init.sql                     # Инициализация PostgreSQL
├── .env.example                 # Пример переменных окружения
└── README.md                    # Этот файл
```

---

## 💰 Почему это важно для финансовых систем?

Финансовые приложения (платежи, переводы, инвестиции) требуют **высокой надёжности**. Вот реальные проблемы, которые ежедневно происходят:

| Проблема | Что произойдёт | Убыток |
| :-- | :-- | :-- |
| **Медленные платежи** (latency) | Пользователь ждёт 10+ сек, думает что система упала, перезагружает → двойной платёж, потеря доверия | До 10% потери пользователей |
| **Ошибки в обработке** (error rate) | 5% переводов отклоняются, но деньги уже снялись со счёта → спор, претензия | Штраф от ЦБ, потеря репутации |
| **Очередь в БД** (DB slow) | База не справляется → новые запросы встают в очередь → система зависает | Техподдержка перегружена, выручка падает |
| **Утечка памяти** (memory leak) | Приложение ест всю ОЗУ и падает → *все* платежи невозможны | Даунтайм = потеря денег, штрафы за SLA |

**Наш воркшоп:** вы видите эти проблемы в реальном времени в Grafana и учитесь их решать.

---

## 📚 Практические кейсы

Пять готовых сценариев отказов с автоматическими скриптами. Каждый кейс демонстрирует реальный класс проблем в production.

| № | Кейс | Команда | Метрики для отслеживания |
| :-- | :-- | :-- | :-- |
| 1️⃣ | **Рост latency** | `bash scripts/run_latency.sh` | `p95/p99`, `RPS`, `active_transactions` |
| 2️⃣ | **Рост error rate** | `bash scripts/run_error_rate.sh` | `error_rate`, `status_5xx` |
| 3️⃣ | **Медленная БД** | `bash scripts/run_db_slow.sh` | `db_latency`, `active_transactions` (рост) |
| 4️⃣ | **Утечка памяти** | `bash scripts/run_memory_leak.sh` | `memory_usage`, `container_restarts` |
| 5️⃣ | **Хаос-микс** | `bash scripts/run_chaos_mix.sh` | Все сигналы сразу (реальный инцидент) |

**Для каждого кейса:**
1. Запустить скрипт → система начнёт "падать"
2. Открыть Grafana → наблюдать метрики в реальном времени
3. Выявить первичный сигнал → разобраться в причине
4. Выполнить `bash scripts/reset.sh` → вернуть baseline

**Детально:** см. раздел ниже «Практические кейсы»

---

## ⚙️ Управление инфраструктурой

```bash
# Остановка сервисов (данные сохраняются)
docker compose down

# Полная очистка (удаляет БД и метрики)
docker compose down -v

# Перезагрузка одного сервиса
docker compose restart prometheus
```

### Запуск скриптов (готовые сценарии)
Все кейсы доступны через скрипты в папке `scripts/`:
```bash
# Запуск любого кейса (выберите один)
bash scripts/run_latency.sh          # Кейс 1: Latency
bash scripts/run_error_rate.sh       # Кейс 2: Error Rate
bash scripts/run_db_slow.sh          # Кейс 3: DB Slow
bash scripts/run_memory_leak.sh      # Кейс 4: Memory Leak
bash scripts/run_chaos_mix.sh        # Кейс 5: Chaos Mix

# Сброс состояния после любого кейса
bash scripts/reset.sh

# Проверка готовности всех сервисов перед началом
bash scripts/check_setup.sh
```

---

## 📚 Дополнительная документация

- [Архитектура и методология](docs/architecture.md)
- [Описание воркшопа для презентации](docs/presentation.md)
- [Подробный гайд для тренера](docs/coach-guide.md)
- [Настройка мониторинга (Prometheus/Grafana)](docs/monitoring.md)
- [Скриншоты и примеры](docs/screenshots.md)
- [Философия тестирования и chaos engineering]()
- [Руководство по curl](docs/curl_guide.md)
- [Описание скриптов](docs/scripts.md)

Практические кейсы:

- [Кейс 1: рост latency](docs/cases/01_latency.md)
- [Кейс 2: рост error rate](docs/cases/02_error_rate.md)
- [Кейс 3: медленная БД](docs/cases/03_db_slow.md)
- [Кейс 4: утечка памяти](docs/cases/04_memory_leak.md)
- [Кейс 5: комбинированный хаос-сценарий](docs/cases/05_chaos_mix.md)
- [Гайд для тренера](docs/coach-guide.md)

> Примечание: часть переменных в `.env.example` зарезервирована под дополнительные сценарии (frontend-ошибки, security и т.д.).
> В текущей версии воркшопа они не используются напрямую в `app.py` и приведены для будущих расширений.

---

### Быстрые проверки перед демо
```bash
# 1. Всё ли работает?
bash scripts/check_setup.sh

# 2. Приложение отвечает?
curl -s http://localhost:5000/health | jq .

# 3. Prometheus собирает метрики?
curl -s http://localhost:9090/api/v1/query?query=up | jq '.data.result[0]'

# 4. Grafana видит Prometheus?
curl -s http://localhost:3000/api/datasources | jq '.[] | {name, url}'
```

---

## Лицензия

MIT
