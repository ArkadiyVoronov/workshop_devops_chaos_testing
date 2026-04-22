#!/usr/bin/env bash
set -euo pipefail

# Настройки
STAGES=5
STAGE_DURATION=5
BASE_LATENCY=500
LATENCY_STEP=500
TRAFFIC_RATE=0.2

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Функция прогресса
show_progress() {
  local stage=$1
  local duration=$2
  local start_time=$(date +%s)
  local requests=0

  echo -e "${BLUE}Запуск трафика...${NC}"
  while true; do
    local current_time=$(date +%s)
    local elapsed=$((current_time - start_time))
    local percent=$((elapsed * 100 / duration))
    local time_left=$((duration - elapsed))
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/health)
    if [ "$http_code" = "200" ]; then
      requests=$((requests + 1))
    fi
    printf "\\r${YELLOW}Стадия %d: %d%% (%d/%ds) | Запросов: %d | Время: %02d:%02d${NC} " \
      $stage $percent $elapsed $duration $requests $((elapsed / 60)) $((elapsed % 60))
    if [ $elapsed -ge $duration ]; then
      break
    fi
    sleep $TRAFFIC_RATE
  done
  echo -e "\\n${GREEN}Стадия $stage завершена: $requests запросов, задержка ~$((BASE_LATENCY + (stage - 1) * LATENCY_STEP))мс${NC}"
}

# Функция инъекции
inject_latency() {
  local latency=$1
  echo -e "${RED}Инъекция: $latency мс${NC}"
  local response=$(curl -s -w "HTTP %{http_code}" -X POST http://localhost:5000/api/failures \
    -H 'Content-Type: application/json' \
    -d "{\"latency_ms\": $latency}")
  local http_code=${response: -3}
  if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✓ Применено${NC}"
  else
    echo -e "${RED}✗ Ошибка: $http_code${NC}"
    exit 1
  fi
}

# Сброс (global)
echo -e "\\n${YELLOW}Сброс...${NC}"
response=$(curl -s -w "HTTP %{http_code}" -X POST http://localhost:5000/api/reset)
http_code=${response: -3}
if [ "$http_code" = "200" ]; then
  echo -e "${GREEN}✓ Сброшено${NC}"
else
  echo -e "${RED}✗ Ошибка: $http_code${NC}"
fi

# Цикл
echo -e "\\n${BLUE}=== ТЕСТ ЗАДЕРЖКИ (5 стадий) ===${NC}"
echo "Смотри Grafana: p95, RPS. Ctrl+C для остановки."

for ((stage=1; stage<=STAGES; stage++)); do
  LATENCY=$((BASE_LATENCY + (stage - 1) * LATENCY_STEP))
  echo -e "\\n${YELLOW}=== Стадия $stage/$STAGES: $LATENCY мс ($STAGE_DURATION сек) ===${NC}"
  inject_latency $LATENCY
  sleep 1
  show_progress $stage $STAGE_DURATION
  echo -e "\\n${GREEN}Стадия $stage: Проверь p95 spike в Grafana.${NC}"
  sleep 2
done

echo -e "\\n${GREEN}🎉 Тест 100%! Графики за $((STAGES * STAGE_DURATION)) сек.${NC}"
echo "Сброс: bash scripts/reset.sh"
