# Скриншоты и визуальные примеры

Все скриншоты находятся в папке `/docs/screenshots/`. Здесь описание каждого и где они используются.

---

## 📊 Скриншоты кейсов отказов

Эти скриншоты показывают дашборды Grafana **до** и **после** запуска каждого кейса инъекции.

### Кейс 1: Рост latency
- **Файл**: `case1_latency.png`
- **Используется в**: `docs/monitoring.md` (таблица "Ожидаемые результаты")
- **Показывает**: 
  - P95/P99 latency скачет на 2–3 сек
  - RPS падает (система перегружена)
  - Histogram quantile в Grafana растет

**Как создать:**
```bash
bash scripts/run_latency.sh
# Открыть Grafana → Screenshot дашборда с видимым скачком P95/P99
```

---

### Кейс 2: Рост error rate
- **Файл**: `case2_error_rate.png`
- **Используется в**: `docs/monitoring.md` (таблица "Ожидаемые результаты")
- **Показывает**:
  - Error Rate растет (красная линия на графике)
  - Status 5xx ↑ (количество ошибок сервера)
  - RPS может упасть

**Как создать:**
```bash
bash scripts/run_error_rate.sh
# Открыть Grafana → Screenshot дашборда с видимыми ошибками (красная область)
```

---

### Кейс 3: Медленная БД
- **Файл**: `case3_db_slow.png`
- **Используется в**: `docs/monitoring.md` (таблица "Ожидаемые результаты")
- **Показывает**:
  - Active Transactions растут выше 10 (красная линия)
  - Latency растет из-за очереди в БД
  - RPS падает

**Как создать:**
```bash
bash scripts/run_db_slow.sh
# Открыть Grafana → Screenshot дашборда с видимым ростом Active Transactions
```

---

### Кейс 4: Утечка памяти
- **Файл**: `case4_memory_leak.png`
- **Используется в**: `docs/monitoring.md` (таблица "Ожидаемые результаты")
- **Показывает**:
  - Container Memory растет с 100 MB до 400-500 MB
  - Линия памяти идет вверх (никогда не падает)
  - Может быть рестарт контейнера

**Как создать:**
```bash
bash scripts/run_memory_leak.sh
# Открыть Grafana → Screenshot дашборда с видимым ростом памяти контейнера
```

---

### Кейс 5: Хаос-микс
- **Файл**: `case5_chaos_mix.png`
- **Используется в**: `docs/monitoring.md` (таблица "Ожидаемые результаты")
- **Показывает**:
  - Все метрики нарушены одновременно:
    - P95/P99 latency ↑
    - Error Rate ↑
    - Active Transactions ↑
    - Memory может расти
  - Реалистичный инцидент при множественных отказах

**Как создать:**
```bash
bash scripts/run_chaos_mix.sh
# Открыть Grafana → Screenshot дашборда со ВСЕМИ нарушенными метриками
```

---

## 🏗️ Архитектурные и настроечные скриншоты

### Главная диаграмма архитектуры
- **Файл**: `architecture_diagram.png` (1.2 MB)
- **Используется в**: 
  - `docs/architecture.md` (в начале)
  - `README.md` (общая схема)
- **Показывает**: Общая архитектура Flask + PostgreSQL + Prometheus + Grafana

---

### Grafana Home Screen
- **Файл**: `grafana_home_screen.png` (116 KB)
- **Используется в**: `docs/monitoring.md`
- **Показывает**: Главный экран Grafana с доступными дашбордами

---

### Grafana на порту 3000
- **Файл**: `grafana_on_3000_port.png` (127 KB)
- **Используется в**: `docs/monitoring.md`
- **Показывает**: Как выглядит Grafana при правильной настройке

---

### Docker Compose статус
- **Файл**: `docker_ps_screenshot_then_all_start_and_ports_open.png` (37 KB)
- **Используется в**: `docs/coach-guide.md`
- **Показывает**: Вывод `docker compose ps` со всеми запущенными сервисами и портами

---

### GitHub Codespaces начало
- **Файл**: `codespaces_2.png` (68 KB)
- **Используется в**: `README.md` (секция "GitHub Codespaces")
- **Показывает**: Как запустить воркшоп в Codespaces за 3 минуты

---

### Workflow "Start application"
- **Файл**: `start_application_screen.png` (10 KB)
- **Используется в**: `docs/workshop.md`
- **Показывает**: Экран запуска приложения в Replit

---

## 📋 Чеклист скриншотов

| Скриншот | Статус | Размер | Используется |
|----------|--------|--------|--------------|
| `case1_latency.png` | ⚠️ **Заглушка** | 69 B | monitoring.md |
| `case2_error_rate.png` | ⚠️ **Заглушка** | 69 B | monitoring.md |
| `case3_db_slow.png` | ⚠️ **Заглушка** | 69 B | monitoring.md |
| `case4_memory_leak.png` | ⚠️ **Заглушка** | 69 B | monitoring.md |
| `case5_chaos_mix.png` | ⚠️ **Заглушка** | 69 B | monitoring.md |
| `architecture_diagram.png` | ✅ **Готов** | 1.2 M | architecture.md, README.md |
| `grafana_home_screen.png` | ✅ **Готов** | 116 K | monitoring.md |
| `grafana_on_3000_port.png` | ✅ **Готов** | 127 K | monitoring.md |
| `docker_ps_screenshot_then_all_start_and_ports_open.png` | ✅ **Готов** | 37 K | coach-guide.md |
| `codespaces_2.png` | ✅ **Готов** | 68 K | README.md |
| `start_application_screen.png` | ✅ **Готов** | 10 K | workshop.md |

---

## 🔗 Где используются скриншоты

| Файл | Ссылки на скриншоты |
|------|-------------------|
| `docs/architecture.md` | `/docs/screenshots/architecture_diagram.png` |
| `docs/monitoring.md` | `case1_latency.png`, `case2_error_rate.png`, `case3_db_slow.png`, `case4_memory_leak.png`, `case5_chaos_mix.png` |
| `docs/coach-guide.md` | `docker_ps_screenshot_then_all_start_and_ports_open.png` |
| `README.md` | `/docs/screenshots/architecture_diagram.png`, `codespaces_2.png` |
| `docs/checklist.md` | `case1_latency.png`, `case2_error_rate.png`, `case3_db_slow.png`, `case4_memory_leak.png`, `case5_chaos_mix.png` |

---

## 📸 Как сделать скриншоты кейсов

1. **Запустить систему**:
   ```bash
   docker compose up -d --build
   ```

2. **Открыть Grafana**:
   - URL: `http://localhost:3000`
   - Login: `admin` / `admin`

3. **Для каждого кейса** (1-5):
   ```bash
   bash scripts/run_[name].sh
   # Подождать 2-4 сек пока Prometheus обновит метрики
   # Взять скриншот дашборда (должны быть видны изменения)
   # Сохранить в docs/screenshots/case[N]_[name].png
   ```

4. **После каждого кейса**:
   ```bash
   curl -X POST http://localhost:5000/api/reset
   # Подождать 10-15 сек пока система вернется в норму
   ```

---

**Статус**: 5 из 11 скриншотов нужно заполнить (кейсы 1-5 пока что заглушки).
