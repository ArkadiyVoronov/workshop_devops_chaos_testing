#!/usr/bin/env bash
set -euo pipefail

# Настройки
STAGES=5
STAGE_DURATION=5
BASE_ERROR_RATE=10
ERROR_STEP=10
TRAFFIC_RATE=0.2
API_URL="http://localhost:5000/api/balance"

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Функция инъекции
inject_error_rate() {
  local error_rate=$1
  echo -e "${RED}Инъекция: %d%%${NC}" $error_rate
  response=$(curl -s -w "HTTP %{http_code}" -X POST http://localhost:5000/api/failures \
    -H 'Content-Type: application/json' \
    -d "{\"error_rate\": $error_rate}")
  http_code=${response: -3}
  if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✓ Применено${NC}"
  else
    echo -e "${RED}✗ Ошибка: $http_code${NC}"
    exit 1
  fi
}

# Функция трафика (одна строка обновления)
generate_traffic() {
  local stage=$1
  local duration=$2
  local start_time=$(date +%s)
  local requests=0
  local failures=0

  echo -e "${BLUE}Трафик...${NC}"
  while true; do
    local current_time=$(date +%s)
    local elapsed=$((current_time - start_time))
    local percent=$((elapsed * 100 / duration))
    
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" $API_URL)
    if [ "$http_code" = "200" ]; then
      requests=$((requests + 1))
    else
      failures=$((failures + 1))
    fi
    
    # Бар + всё на одной строке (\\r overwrite)
    local bar=$(printf "${GREEN}█%.0s${NC}${YELLOW}░%.0s${NC}" $(seq 1 $percent) $(seq 1 $((100 - percent))))
    printf "\\r${YELLOW}%s | Стадия %d: %d%% | Запросов: %d | Ошибок: %d | Код: %s | Время: %02d:%02d${NC} " \
      "$bar" $stage $percent $requests $failures $http_code $((elapsed / 60)) $((elapsed % 60))
    
    if [ $elapsed -ge $duration ]; then
      break
    fi
    sleep $TRAFFIC_RATE
  done
  # Финальный статус (новая строка)
  echo -e "\\n${GREEN}Стадия завершена: %d запросов, %d ошибок.${NC}" $((requests + failures)) $failures
}

# Сброс
echo -e "\\n${YELLOW}Сброс...${NC}"
response=$(curl -s -w "HTTP %{http_code}" -X POST http://localhost:5000/api/reset \
  -H 'Content-Type: application/json' \
  -d '{"error_rate": 0}')
http_code=${response: -3}
if [ "$http_code" = "200" ]; then
  echo -e "${GREEN}✓ Сброшено${NC}"
else
  echo -e "${RED}✗ Ошибка: $http_code${NC}"
fi

# Цикл (заголовок новой строкой, прогресс одной)
echo -e "\\n${BLUE}=== ТЕСТ ОШИБОК (5 стадий) ===${NC}"
echo "Смотри Grafana. Ctrl+C для остановки."

for ((stage=1; stage<=STAGES; stage++)); do
  ERROR_RATE=$((BASE_ERROR_RATE + (stage - 1) * ERROR_STEP))
  echo -e "\\n${YELLOW}=== Стадия $stage/$STAGES: %d%% ($STAGE_DURATION сек) ===${NC}" $ERROR_RATE  # Новая строка для заголовка
  inject_error_rate $ERROR_RATE
  sleep 1
  generate_traffic $stage $STAGE_DURATION  # Прогресс одной строкой
  sleep 2
done

echo -e "\\n${GREEN}Тест завершён!${NC}"
