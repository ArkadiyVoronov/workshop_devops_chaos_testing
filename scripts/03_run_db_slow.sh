#!/usr/bin/env bash
set -euo pipefail

# ==========================================
# НАСТРОЙКИ СЦЕНАРИЯ "DB SLOW"
# ==========================================
# Количество стадий теста
STAGES=5
# Длительность каждой стадии в секундах (чуть дольше, так как запросы медленные)
STAGE_DURATION=10
# Интервал между запросами (сек)
TRAFFIC_INTERVAL=0.3
# URL эндпоинта, нагружающего БД
API_URL="http://localhost:5000/api/balance"

# ==========================================
# ЦВЕТА И ФОРМАТИРОВАНИЕ
# ==========================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# ==========================================
# ФУНКЦИИ
# ==========================================

# Функция вывода прогресса с баром
show_progress() {
  local stage=$1
  local duration=$2
  local start_time=$(date +%s)
  local requests=0
  local errors=0

  echo -e "${CYAN}🚀 Генерация транзакций (нагрузка на БД)...${NC}"
  
  while true; do
    local current_time=$(date +%s)
    local elapsed=$((current_time - start_time))
    
    # Проверка окончания стадии
    if [ $elapsed -ge $duration ]; then
      break
    fi

    # Делаем запрос к балансу (он использует БД)
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL")
    
    if [[ "$http_code" =~ ^2 ]]; then
      requests=$((requests + 1))
    else
      errors=$((errors + 1))
    fi

    # Расчет процентов и прогресс-бара
    local percent=$((elapsed * 100 / duration))
    local bar_len=$((percent / 5))
    local bar=$(printf "%0.s#" $(seq 1 $bar_len 2>/dev/null || true))
    local space=$(printf "%0.s." $(seq 1 $((20 - bar_len)) 2>/dev/null || true))
    
    # Вывод в одну строку (обновляемая)
    printf "\r${YELLOW}[%s%s] %d%% | Запросов: %d | ✅ Успех: %d | ❌ Ошибки: %d | Время: %02d:%02d${NC} " \
      "$bar" "$space" $percent $requests $((requests - errors)) $errors $((elapsed / 60)) $((elapsed % 60))
    
    sleep $TRAFFIC_INTERVAL
  done
  
  echo -e "\\n${GREEN}✅ Стадия $stage завершена: выполнено $requests запросов.${NC}"
  if [ $errors -gt 0 ]; then
     echo -e "${RED}⚠️ Ошибок на стадии: $errors${NC}"
  fi
}

# Функция инъекции
inject_db_slow() {
  local is_slow=$1
  local mode_text="ВКЛ (тормозим БД)"
  if [ "$is_slow" = "false" ]; then
    mode_text="ВЫКЛ (норма)"
  fi
  
  echo -e "${RED}️ Режим DB Slow: ${mode_text}${NC}"
  
  local payload="{\"db_slow\": $is_slow}"
  local response=$(curl -s -w "HTTP %{http_code}" -X POST http://localhost:5000/api/failures \
    -H 'Content-Type: application/json' \
    -d "$payload")
  
  local http_code=${response: -3}
  if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✓ Конфигурация применена${NC}"
  else
    echo -e "${RED}✗ Ошибка API: $http_code${NC}"
    exit 1
  fi
}

# Функция сброса
reset_state() {
  echo -e "\\n${YELLOW} Сброс состояния системы...${NC}"
  local response=$(curl -s -w "HTTP %{http_code}" -X POST http://localhost:5000/api/reset)
  local http_code=${response: -3}
  
  if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✓ Система очищена, БД работает нормально${NC}"
  else
    echo -e "${RED} Ошибка сброса: $http_code${NC}"
  fi
}

# ==========================================
# ОСНОВНОЙ СЦЕНАРИЙ
# ==========================================

echo -e "\\n${BOLD}🐢 ТЕСТ МЕДЛЕННОЙ БД (DB SLOW / QUEUE BUILDUP)${NC}"
echo -e "${CYAN}Цель: Показать, как задержки в БД создают очередь активных транзакций.${NC}"
echo -e "${YELLOW}Смотри в Grafana: панель 'Active Transactions' и 'Latency'.${NC}"
echo -e "${RED}Внимание: Запросы будут выполняться медленнее обычного.${NC}\\n"

# 1. Сброс перед началом
reset_state
sleep 2

# 2. Цикл по стадиям
echo -e "${BLUE}=== ЗАПУСК ЭСКАЛАЦИИ НАГРУЗКИ НА БД ===${NC}"

for ((stage=1; stage<=STAGES; stage++)); do
  echo -e "\\n${BOLD}--- Стадия $stage/$STAGES ---${NC}"
  echo -e "${CYAN}Действие: Включаем искусственную задержку БД (2 сек на запрос)${NC}"
  
  # Включаем медленную БД
  inject_db_slow "true"
  
  sleep 1 # Пауза перед стартом трафика
  
  # Генерируем нагрузку
  show_progress $stage $STAGE_DURATION
  
  echo -e "${GREEN}📈 Очередь транзакций должна расти. Проверь график!${NC}"
  
  # Небольшая пауза перед следующей стадией
  sleep 2
done

# 3. Финал
echo -e "\\n${BOLD} ТЕСТ ЗАВЕРШЕН!${NC}"
echo -e "${YELLOW}График Active Transactions должен был показать устойчивый рост во время стадий.${NC}"
echo -e "${CYAN}Это демонстрирует риск таймаутов и исчерпания пула соединений при медленной БД.${NC}"

# Интерактивный выбор
echo ""
read -p "Сбросить состояние системы сейчас? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  reset_state
else
  echo -e "${YELLOW}️ Система осталась в режиме медленной БД. Не забудь выполнить 'bash scripts/reset.sh' позже!${NC}"
fi

echo -e "\\n${GREEN}Готово. Удачного анализа узких мест! ${NC}"