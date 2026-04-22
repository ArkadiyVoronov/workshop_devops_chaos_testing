#!/usr/bin/env bash
set -euo pipefail

# ==========================================
# НАСТРОЙКИ СЦЕНАРИЯ (можно менять)
# ==========================================
# Количество стадий теста
STAGES=5
# Длительность каждой стадии в секундах
STAGE_DURATION=8
# Интервал между запросами (сек)
TRAFFIC_INTERVAL=0.15
# Базовый процент ошибок на первой стадии
BASE_ERROR_RATE=10
# Шаг увеличения ошибок на каждой стадии (%)
ERROR_STEP=10
# URL эндпоинта для тестирования (используем /api/balance, так как он нагружает БД)
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

# Функция вывода прогресса с красивым баром и счетчиками
show_progress() {
  local stage=$1
  local duration=$2
  local start_time=$(date +%s)
  local requests=0
  local successes=0
  local failures=0

  echo -e "${CYAN}🚀 Генерация трафика (нагрузка на API)...${NC}"
  
  while true; do
    local current_time=$(date +%s)
    local elapsed=$((current_time - start_time))
    
    # Проверка окончания стадии
    if [ $elapsed -ge $duration ]; then
      break
    fi

    # Отправка запроса
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL")
    requests=$((requests + 1))
    
    if [[ "$http_code" =~ ^2 ]]; then
      successes=$((successes + 1))
    else
      failures=$((failures + 1))
    fi

    # Расчет процентов и прогресс-бара
    local percent=$((elapsed * 100 / duration))
    local bar_len=$((percent / 5))
    local bar=$(printf "%0.s#" $(seq 1 $bar_len 2>/dev/null || true))
    local space=$(printf "%0.s." $(seq 1 $((20 - bar_len)) 2>/dev/null || true))
    
    # Вывод в одну строку (обновляемая)
    printf "\r${YELLOW}[%s%s] %d%% | Всего: %d | ✅ Успех: %d | ❌ Ошибки: %d | Время: %02d:%02d${NC} " \
      "$bar" "$space" $percent $requests $successes $failures $((elapsed / 60)) $((elapsed % 60))
    
    sleep $TRAFFIC_INTERVAL
  done
  
  echo -e "\\n${GREEN}✅ Стадия $stage завершена: выполнено $requests запросов.${NC}"
  if [ $failures -gt 0 ]; then
    local error_percent=$((failures * 100 / requests))
    echo -e "${RED}⚠️ Процент ошибок на стадии: ${error_percent}%${NC}"
  fi
}

# Функция инъекции ошибок
inject_error_rate() {
  local rate=$1
  echo -e "${RED}️ Инъекция ошибок: ${rate}%${NC}"
  
  local response=$(curl -s -w "HTTP %{http_code}" -X POST http://localhost:5000/api/failures \
    -H 'Content-Type: application/json' \
    -d "{\"error_rate\": $rate}")
  
  local http_code=${response: -3}
  
  if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✓ Конфигурация применена успешно${NC}"
  else
    echo -e "${RED}✗ Ошибка применения конфигурации (HTTP $http_code)${NC}"
    exit 1
  fi
}

# Функция сброса
reset_state() {
  echo -e "\\n${YELLOW}🧹 Сброс состояния системы...${NC}"
  local response=$(curl -s -w "HTTP %{http_code}" -X POST http://localhost:5000/api/reset)
  local http_code=${response: -3}
  
  if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✓ Система очищена, ошибки сброшены${NC}"
  else
    echo -e "${RED}✗ Ошибка сброса (HTTP $http_code)${NC}"
  fi
}

# ==========================================
# ОСНОВНОЙ СЦЕНАРИЙ
# ==========================================

echo -e "\\n${BOLD}❌ ТЕСТ РОСТА ОШИБОК (ERROR RATE SPIKE)${NC}"
echo -e "${CYAN}Цель: Показать, как рост доли 5xx ошибок влияет на доступность и доверие пользователей.${NC}"
echo -e "${YELLOW}Смотри в Grafana: панель 'Error Rate', 'Status 5xx', 'RPS'.${NC}"
echo -e "${RED}Внимание: Не закрывай терминал до завершения, иначе тест прервется.${NC}\\n"

# 1. Сброс перед началом
reset_state
sleep 2

# 2. Цикл по стадиям
echo -e "${BLUE}=== ЗАПУСК ЭСКАЛАЦИИ ОШИБОК ===${NC}"

for ((stage=1; stage<=STAGES; stage++)); do
  CURRENT_ERROR_RATE=$((BASE_ERROR_RATE + (stage - 1) * ERROR_STEP))
  
  echo -e "\\n${BOLD}--- Стадия $stage/$STAGES ---${NC}"
  echo -e "${CYAN}Целевой процент ошибок: ${CURRENT_ERROR_RATE}%${NC}"
  
  # Применяем ошибку
  inject_error_rate $CURRENT_ERROR_RATE
  
  sleep 1 # Пауза перед стартом трафика
  
  # Запускаем генерацию трафика
  show_progress $stage $STAGE_DURATION
  
  echo -e "${GREEN} Ошибки должны расти ступеньками. Проверь график Error Rate!${NC}"
  sleep 2
done

# 3. Финал
echo -e "\\n${BOLD}🎉 ТЕСТ ЗАВЕРШЕН!${NC}"
echo -e "${YELLOW}График Error Rate должен показывать устойчивый тренд вверх.${NC}"
echo -e "${CYAN}Если алерт 'HighErrorRate' еще не сработал, подожди немного или запусти еще один цикл.${NC}"

# Интерактивный выбор
echo ""
read -p "Сбросить состояние системы сейчас? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  reset_state
else
  echo -e "${YELLOW}⚠️ Система осталась в режиме генерации ошибок. Не забудь выполнить 'bash scripts/reset.sh' позже!${NC}"
fi

echo -e "\\n${GREEN}Готово. Удачного мониторинга! 🚀${NC}"