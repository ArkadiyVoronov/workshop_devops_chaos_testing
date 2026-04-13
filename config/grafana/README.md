# Grafana Dashboard Guide

## 📋 Обзор

Этот документ описывает процесс импорта, создания и редактирования дашбордов Grafana для проекта Fintech Workshop.

## 🗂️ Структура файлов

```
config/grafana/
├── dashboards/
│   └── unified-dashboard.json          # Основной объединённый дашборд
└── provisioning/
    ├── dashboards/
    │   ├── dashboard.yaml              # Конфигурация автозагрузки дашбордов
    │   └── unified-dashboard.json      # Копия дашборда для автозагрузки
    └── datasources/
        └── prometheus.yaml             # Конфигурация источника данных Prometheus
```

## 🚀 Быстрый старт

### Импорт дашборда

1. **Автоматический импорт (рекомендуется)**
   - Дашборды автоматически загружаются при старте Grafana из папки `/etc/grafana/provisioning/dashboards`
   - Файл `dashboard.yaml` настроен на автоматическое обновление каждые 10 секунд
   - Просто поместите JSON-файл дашборда в эту папку

2. **Ручной импорт через UI**
   - Откройте Grafana в браузере (обычно http://localhost:3000)

   - Войдите под учётной записью admin/workshop
=======
   - Войдите под учётной записью admin/admin

   - Перейдите: **Dashboards** → **Import**
   - Загрузите файл `unified-dashboard.json` или вставьте его содержимое
   - Выберите источник данных Prometheus
   - Нажмите **Import**

### Проверка работы

После импорта убедитесь, что:
- ✅ Дашборд отображается в списке
- ✅ Графики показывают данные (не пустые)
- ✅ Источник данных Prometheus подключён
- ✅ Метрики обновляются в реальном времени

## 📊 Описание дашборда

### Unified Dashboard (`fintech-unified-dashboard`)

Объединённый дашборд содержит **11 панелей** для мониторинга:

| № | Панель | Описание | Метрики |
|---|--------|----------|---------|
| 1 | **Request Rate (RPS)** | Запросы в секунду | `rate(fintech_requests_total[1m])` |
| 2 | **Latency p95/p99** | Задержки ответа | `histogram_quantile(0.95/0.99, rate(fintech_request_latency_seconds_bucket[5m]))` |
| 3 | **Error Rate** | Процент ошибок | `rate(fintech_requests_total{status=~"5.."}[5m]) / rate(fintech_requests_total[5m])` |
| 4 | **Active Transactions** | Активные транзакции | `fintech_active_transactions` |
| 5 | **Container CPU Usage** | Использование CPU контейнерами | `rate(container_cpu_usage_seconds_total[1m]) * 100` |
| 6 | **Container Memory Usage** | Использование памяти | `container_memory_usage_bytes` |
| 7 | **HTTP Status Codes** | Статусы HTTP ответов | `sum by (status) (rate(fintech_requests_total[5m]))` |
| 8 | **Container Restarts** | Перезапуски контейнеров | `container_last_seen` |
| 9 | **Network Traffic** | Сетевой трафик | `container_network_receive/transmit_bytes_total` |
| 10 | **Service Health** | Статус сервисов | `up{job="app/db"}` |
| 11 | **Alerts Summary** | Сводка алертов | `ALERTS` |

## 🛠️ Создание нового дашборда

### Через UI

1. **Начать создание**
   - Перейдите: **Dashboards** → **New Dashboard** → **Add visualization**
   - Выберите источник данных (Prometheus)

2. **Добавить панель**
   - Введите PromQL запрос в редакторе
   - Настройте визуализацию (Graph, Gauge, Stat, Table и т.д.)
   - Настройте позицию и размер (Grid Pos)

3. **Сохранить дашборд**
   - Нажмите **Save** (Ctrl+S)
   - Укажите название и UID (уникальный идентификатор)
   - Добавьте теги для категоризации

### Через JSON (программно)

1. **Экспортировать существующий дашборд**
   - Откройте дашборд в UI
   - Нажмите **Dashboard settings** (шестерёнка)
   - Выберите **JSON Model**
   - Скопируйте JSON

2. **Редактировать JSON**
   - Измените необходимые поля (title, panels, targets и т.д.)
   - Убедитесь, что UID уникален
   - Проверьте ссылки на datasource

3. **Импортировать обратно**
   - Используйте ручной импорт через UI или
   - Поместите файл в папку provisioning

## ✏️ Редактирование дашборда

### Основные операции

| Действие | Как выполнить |
|----------|---------------|
| Добавить панель | Click **Add panel** → **Add new panel** |
| Редактировать панель | Hover over panel → Click **Edit** |
| Переместить панель | Drag & drop за заголовок |
| Изменить размер | Drag за нижний правый угол |
| Дублировать панель | Panel menu → **Duplicate** |
| Удалить панель | Panel menu → **Remove** |

### Настройка панелей

#### Timeseries (графики)
- **Query**: PromQL запрос к Prometheus
- **Legend**: Формат легенды (используйте `{{label}}`)
- **Thresholds**: Пороговые значения для цветов
- **Unit**: Единицы измерения (reqps, s, percent, bytes и т.д.)

#### Stat (числовые индикаторы)
- **Value**: Отображаемое значение (last, max, min, sum)
- **Gauge mode**: Показать как спидометр
- **Color mode**: Background/Text/Value

#### Gauge (датчики)
- **Min/Max**: Диапазон значений
- **Show threshold labels**: Показать пороги
- **Show threshold tick marks**: Показать метки порогов

#### Table (таблицы)
- **Columns**: Выберите метрики для отображения
- **Sort**: Сортировка по колонкам
- **Filter**: Фильтрация данных

## 🔧 Конфигурация Provisioning

### dashboard.yaml

```yaml
apiVersion: 1

providers:
  - name: 'Workshop Dashboards'
    orgId: 1
    folder: ''
    folderUid: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /etc/grafana/provisioning/dashboards
```

**Параметры:**
- `disableDeletion: false` — позволяет удалять дашборды через UI
- `updateIntervalSeconds: 10` — проверка изменений каждые 10 сек
- `allowUiUpdates: true` — разрешает редактирование через UI с последующей синхронизацией

### prometheus.yaml

```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
    jsonData:
      timeInterval: "5s"
```

**Параметры:**
- `access: proxy` — запросы через сервер Grafana
- `isDefault: true` — используется по умолчанию
- `timeInterval: "5s"` — минимальный интервал для запросов

## 🎯 Best Practices

### Организация дашбордов
1. **Один дашборд — одна цель**: Не смешивайте разные типы метрик
2. **Используйте переменные**: Для фильтрации по namespace, pod, container
3. **Группируйте панели**: Логически связанные метрики размещайте рядом
4. **Добавляйте описания**: Text panels с объяснением метрик

### Оптимизация запросов
1. **Избегайте `*` в label matcher**: Указывайте конкретные значения
2. **Используйте range queries**: `[5m]`, `[1h]` вместо instant
3. **Кэшируйте результаты**: Повторно используйте переменные
4. **Ограничивайте время**: Не запрашивайте слишком большие диапазоны

### Визуализация
1. **Выбирайте правильный тип**: 
   - Timeseries для трендов
   - Gauge для текущих значений
   - Table для детальной информации
2. **Используйте цвета осмысленно**: Красный = проблема, зелёный = OK
3. **Добавляйте thresholds**: Визуальная индикация проблем
4. **Настройте refresh**: 5s для real-time, 30s+ для overview

## 🐛 Troubleshooting

### Дашборд не отображается
- Проверьте путь к файлу в `dashboard.yaml`
- Убедитесь, что JSON валиден (используйте jsonlint.com)
- Проверьте логи Grafana: `docker logs grafana`

### Нет данных на графиках
- Проверьте подключение к Prometheus: **Configuration** → **Data sources**
- Убедитесь, что метрики существуют: Explore → Prometheus → Query browser
- Проверьте временной диапазон: возможно данные за другой период

### Ошибки PromQL
- Используйте **Explore** для тестирования запросов
- Проверяйте названия метрик и лейблов
- Убедитесь в правильности агрегаций (`rate`, `sum`, `avg`)

### Конфликты UID
- Каждый дашборд должен иметь уникальный UID
- При импорте выберите "Overwrite" если UID существует
- Или измените UID в JSON перед импортом

## 📚 Дополнительные ресурсы

- [Official Grafana Docs](https://grafana.com/docs/)
- [PromQL Cheat Sheet](https://promlabs.com/promql-cheat-sheet/)
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)
- [Community Plugins](https://grafana.com/grafana/plugins/)

## 🔄 Обновление дашбордов

Для обновления существующего дашборда:

1. **Через UI** (если `allowUiUpdates: true`):
   - Внесите изменения в дашборд
   - Сохраните (Ctrl+S)
   - Изменения автоматически применятся

2. **Через файлы**:
   - Отредактируйте JSON файл
   - Grafana обнаружит изменения в течение 10 секунд
   - Или перезапустите контейнер Grafana

3. **Export/Import**:
   - Экспортируйте текущую версию
   - Внесите изменения в JSON
   - Импортируйте с тем же UID (overwrite)

---

**Версия документации**: 1.0  
**Последнее обновление**: 2024  
**Проект**: Fintech Workshop
