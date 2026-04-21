#!/bin/bash
# new_network_partition.sh - Демонстрация сетевого разделения
# Версия: v2.0 (для презентации)
# Описание: Симулирует сетевую задержку между frontend и backend

set -euo pipefail

echo "🚨 Демонстрация: Network Partition - Сбой связи между сервисами"

# 1. Baseline проверка
echo "📊 Baseline: Проверяем соединение frontend-backend"
curl -s -w "HTTP: %{http_code} | Time: %{time_total}s\n" \
  http://localhost:5000/api/health || echo "Baseline failed"

# 2. Симулируем сетевую задержку (5 секунд)
echo "💥 Вводим задержку 5 секунд между сервисами..."
# Используем tc для задержки на интерфейсе
sudo tc qdisc add dev lo root netem delay 5000ms 100ms

echo "⏳ Тестируем с задержкой..."
for i in {1..3}; do
  echo "Attempt $i:"
  curl -s -w "HTTP: %{http_code} | Time: %{time_total}s\n" \
    -m 3 http://localhost:5000/api/payment/process \
    -d '{"amount": 100, "currency": "USD"}' || echo "Attempt $i: Timeout (3s)"
done

# 3. Показать метрики
echo "📊 Метрики во время сетевого сбоя:"
docker stats --no-stream

# 4. Симулируем circuit breaker (если есть)
echo "🔌 Circuit breaker должен сработать (fallback mode)"
# Если в app.py реализован circuit breaker, он покажет fallback

# 5. Восстанавливаем сеть
echo "🛡️ Восстанавливаем сеть..."
sudo tc qdisc del dev lo root

sleep 2

# 6. Проверяем восстановление
echo "✅ Проверяем восстановление:"
curl -s -w "HTTP: %{http_code} | Time: %{time_total}s\n" \
  http://localhost:5000/api/payment/process \
  -d '{"amount": 100, "currency": "USD"}' || echo "Recovery failed"

# 7. Анализ
echo "📊 Результаты:"
echo "- Network delay: 5s + 100ms jitter"
echo "- Request timeout: 3s"
echo "- Circuit breaker: Должен сработать"
echo "- Recovery time: <2s"

echo "🎯 Демонстрация завершена!"
echo "📝 Обсуждение:"
echo "- Latency >3s = пользователь уйдет"
echo "- Circuit breakers критически важны"
echo "- Нужен adaptive timeout management"