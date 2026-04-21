# DB lock simulation for queue effect
#!/usr/bin/env bash
set -euo pipefail

echo "1) Проверяем Docker Compose сервисы..."
docker compose ps

echo "2) Проверяем API приложения..."
for url in "http://localhost:5000/health" "http://localhost:5000/api/failures" "http://localhost:5000/metrics"; do
  status=$(curl -o /dev/null -s -w "%{http_code}" "$url")
  if [[ "$status" != "200" ]]; then
    echo "ERROR: $url вернул $status" >&2
    exit 1
  fi
  echo "  $url -> $status"
done

echo "3) Проверяем Prometheus..."
status=$(curl -o /dev/null -s -w "%{http_code}" http://localhost:9090/-/ready)
if [[ "$status" != "200" ]]; then
  echo "ERROR: Prometheus readiness вернул $status" >&2
  exit 1
fi

echo "  Prometheus ready -> $status"

echo "4) Проверяем Grafana..."
status=$(curl -o /dev/null -s -w "%{http_code}" http://localhost:3000/api/health)
if [[ "$status" != "200" ]]; then
  echo "ERROR: Grafana health вернул $status" >&2
  exit 1
fi

echo "  Grafana health -> $status"

# Проверка базовых метрик
if ! curl -s http://localhost:5000/metrics | grep -q "fintech_requests_total"; then
  echo "ERROR: в /metrics не найден fintech_requests_total" >&2
  exit 1
fi

echo "5) Проверка успешна: всё настроено для кейсов!"

echo "Запуск:
  docker compose up -d --build
  bash scripts/check_setup.sh
  bash scripts/run_latency.sh (или другой кейс)"
