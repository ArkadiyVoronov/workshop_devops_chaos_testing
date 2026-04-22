#!/usr/bin/env bash
set -euo pipefail

# Настройки
STAGES=5
STAGE_DURATION=8  # Чуть дольше, так как запросы будут медленнее
TRAFFIC_RATE=0.3  # Реже, чтобы не перегружать медленную БД сразу

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
  local errors=0

  echo -e "${BLUE}Генерация транзакций (нагрузка на БД)...${NC}"
  while true; do
    local current_time=$(date +%s)
    local elapsed=$((current_time - start_time))
    local percent=$((elapsed * 100 / duration))
    local time_left=$((duration - elapsed))
    
    # Делаем запрос к балансу (он использует БД)
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/api/balance)
    
    if [ "$http_code" = "200" ]; then
      requests=$((requests + 1))
    else
      errors=$((errors + 1))
    fi

    printf "\\r${YELLOW}Стадия %d: %d%% (%d/%ds) | Успешно: %d | Ошибки: %d | Время: %02d:%02d${NC} " \
      $stage $percent $elapsed $duration $requests $errors $((elapsed / 60)) $((elapsed % 60))
    
    if [ $elapsed -ge $duration ]; then
      break
    fi
    sleep $TRAFFIC_RATE
  done
  echo -e "\\n${GREEN}Стадия $stage завершена: $requests запросов, ошибок: $errors${NC}"
}

# Функция инъекции
inject_db_slow() {
  local is_slow=$1
  local mode_text="ВКЛ"
  if [ "$is_slow" = "false" ]; then
    mode_text="ВЫКЛ"
  fi
  
  echo -e "${RED}Режим DB Slow: $mode_text${NC}"
  
  local payload="{\"db_slow\": $is_slow}"
  local response=$(curl -s -w "HTTP %{http_code}" -X POST http://localhost:5000/api/failures \
    -H 'Content-Type: application/json' \
    -d "$payload")
  
  local http_code=${response: -3}
  if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✓ Конфигурация применена${NC}"
  else
    echo -e "${RED} Ошибка API: $http_code${NC}"
    exit 1
  fi
}

# Сброс состояния
echo -e "\\n${YELLOW}🧹 Сброс предыдущих состояний...${NC}"
response=$(curl -s -w "HTTP %{http_code}" -X POST http://localhost:5000/api/reset)
http_code=${response: -3}
if [ "$http_code" = "200" ]; then
  echo -e "${GREEN}✓ Система очищена${NC}"
else
  echo -e "${RED}✗ Ошибка сброса: $http_code${NC}"
fi

# Основной цикл
echo -e "\\n${BLUE}=== ТЕСТ МЕДЛЕННОЙ БД (5 стадий) ===${NC}"
echo "Смотри Grafana: fintech_active_transactions, Latency."
echo "Цель: увидеть рост очереди транзакций при включенном db_slow."
echo -e "${YELLOW}Нажми Ctrl+C для досрочной остановки.${NC}\\n"

for ((stage=1; stage<=STAGES; stage++)); do
  echo -e "\\n${YELLOW}=== Стадия $stage/$STAGES: Включаем тормоза БД ($STAGE_DURATION сек) ===${NC}"
  
  # Включаем медленную БД
  inject_db_slow "true"
  sleep 1
  
  # Генерируем нагрузку
  show_progress $stage $STAGE_DURATION
  
  echo -e "\\n${GREEN}✅ Стадия $stage: Проверь рост Active Transactions в Grafana.${NC}"
  
  # Небольшая пауза перед следующей стадией (можно убрать, если хотим резкий переход)
  sleep 2
done

echo -e "\\n${GREEN}🎉 Тест завершен! Очередь должна была расти.${NC}"
echo -e "${YELLOW}❗ Важно: Сбрасываем состояние, иначе БД останется медленной.${NC}"
echo "Выполни: bash scripts/reset.sh"

# Автоматический сброс в конце (опционально, можно закомментировать)
echo -e "\\n${BLUE}Автоматический сброс через 3 секунды...${NC}"
sleep 3
bash scripts/reset.sh