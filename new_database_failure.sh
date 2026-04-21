#!/bin/bash
# new_database_failure.sh - Скрипт для демонстрации сбоя базы данных
# Версия: v2.0 (улучшенная для презентации)
# Описание: Останавливает DB, симулирует нагрузку, показывает recovery

set -euo pipefail

echo "🚨 Демонстрация: Database Failure - Payment DB недоступна"

# 1. Показать текущее состояние
echo "📊 Текущее состояние системы:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"

# 2. Остановить Payment DB
echo "💥 Останавливаем Payment Database..."
docker compose stop db
sleep 2

# 3. Симулировать нагрузку на API
echo "📈 Симулируем нагрузку на Payment API (wrk)..."
wrk -t4 -c20 -d10s http://localhost:5000/api/payment/process &
WRK_PID=$!

# 4. Показать метрики в реальном времени
echo "📊 Метрики в реальном времени (Grafana: http://localhost:3000)"
echo "Ожидаемые эффекты:"
echo "- Payment API возвращает 503/500 ошибки"
echo "- Очереди транзакций растут"
echo "- Alerts срабатывают в Grafana"
echo "- CPU/DB I/O падает"

sleep 5

# 5. Показать ошибки API
echo "🔍 Проверка API ответов:"
curl -s -w "HTTP: %{http_code} | Time: %{time_total}s\n" \
  -H "Content-Type: application/json" \
  http://localhost:5000/api/payment/process \
  -d '{"amount": 100, "currency": "USD"}' || echo "API недоступен"

# 6. Восстановление
echo "🚒 Восстанавливаем Database..."
docker compose start db

# 7. Ждем восстановления
echo "⏳ Ожидаем восстановления DB (30 секунд)..."
sleep 30

# 8. Проверяем восстановление
echo "✅ Проверяем восстановление API:"
curl -s -w "HTTP: %{http_code} | Time: %{time_total}s\n" \
  -H "Content-Type: application/json" \
  http://localhost:5000/api/payment/process \
  -d '{"amount": 100, "currency": "USD"}' || echo "API все еще недоступен"

# 9. Останавливаем нагрузку
kill $WRK_PID 2>/dev/null || true

echo "🎯 Демонстрация завершена!"
echo "📝 Обсуждение:"
echo "- Recovery Time: ~30 секунд"
echo "- Impact: Payment processing остановлен"
echo "- Lessons: Нужно read-only mode, connection pooling"