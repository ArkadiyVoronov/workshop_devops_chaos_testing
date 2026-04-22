#!/usr/bin/env bash
set -euo pipefail

# ==========================================
# НАСТРОЙКИ СЦЕНАРИЯ "CHAOS MIX"
# ==========================================
# Длительность каждой фазы хаоса (секунды)
PHASE_DURATION=15
# Интервал между запросами (сек)
TRAFFIC_INTERVAL=0.15

# Параметры инъекций по фазам
# Фаза 1: Только задержка
LATENCY_MS=800
ERROR_RATE_1=0
DB_SLOW_1=false

# Фаза 2: Задержка + Ошибки
LATENCY_MS_2=800
ERROR_RATE_2=15
DB_SLOW_2=false

# Фаза 3: Полный хаос (Задержка + Ошибки + Медленная БД)
LATENCY_MS_3=1200
ERROR_RATE_3=25
DB_SLOW_3=true

# ==========================================
# ЦВЕТА И ФОРМАТИРОВАНИЕ
# ==========================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# ==========================================
# ФУНКЦИИ
# ==========================================

# Функция отправки конфигурации
apply_config() {
  local latency=$1
  local error_rate=$2
  local db_slow=$3
  
  local payload="{\"latency_ms\": $latency, \"error_rate\": $error_rate, \"db_slow\": $db_slow}"
  
  echo -e "${CYAN} Отправка конфигурации: ${payload}${NC}"
  local response=$(curl -s -w "HTTP %{http_code}" -X POST http://localhost:5000/api/failures \
    -H 'Content-Type: application/json' \
    -d "$payload")
  
  local http_code=${response: -3}
  if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✓ Конфигурация применена${NC}"
  else
    echo -e "${RED} Ошибка применения (HTTP $http_code)${NC}"
    return 1
  fi
}

# Функция прогресса с подсчетом ошибок
run_traffic_phase() {
  local phase_name=$1
  local duration=$2
  local start_time=$(date +%s)
  local requests=0
  local errors=0
  local success=0

  echo -e "\\n${MAGENTA}⚡ ФАЗА: $phase_name${NC}"
  echo -e "${BLUE}Генерация смешанного трафика...${NC}"
  
  while true; do
    local current_time=$(date +%s)
    local elapsed=$((current_time - start_time))
    
    if [ $elapsed -ge $duration ]; then
      break
    fi

    # Делаем запрос и ловим код ответа
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/api/balance)
    requests=$((requests + 1))
    
    if [[ "$http_code" =~ ^2 ]]; then
      success=$((success + 1))
    else
      errors=$((errors + 1))
    fi

    # Расчет процентов и прогресс-бара
    local percent=$((elapsed * 100 / duration))
    local bar_len=$((percent / 5))
    local bar=$(printf "%0.s#" $(seq 1 $bar_len 2>/dev/null || true))
    local space=$(printf "%0.s." $(seq 1 $((20 - bar_len)) 2>/dev/null || true))
    
    # Вывод в одну строку
    printf "\\r${CYAN}[%s%s] %d%% | Запросов: %d | ✅ Успех: %d | ❌ Ошибки: %d | Время: %02d:%02d${NC} " \
      "$bar" "$space" $percent $requests $success $errors $((elapsed / 60)) $((elapsed % 60))
    
    sleep $TRAFFIC_INTERVAL
  done
  
  echo -e "\\n${GREEN}✅ Фаза '$phase_name' завершена.${NC}"
  echo -e "   Итого: $requests запросов, Ошибок: $errors ($(( errors * 100 / (requests > 0 ? requests : 1) ))%)"
}

# Функция сброса
reset_state() {
  echo -e "\\n${YELLOW}🧹 Сброс состояния системы...${NC}"
  local response=$(curl -s -w "HTTP %{http_code}" -X POST http://localhost:5000/api/reset)
  local http_code=${response: -3}
  
  if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✓ Система очищена, все параметры сброшены${NC}"
  else
    echo -e "${RED}✗ Ошибка сброса (HTTP $http_code)${NC}"
  fi
}

# ==========================================
# ОСНОВНОЙ СЦЕНАРИЙ
# ==========================================

echo -e "\\n${BOLD}🌪️ ТЕСТ КОМБИНИРОВАННОГО ХАОСА (CHAOS MIX)${NC}"
echo -e "${CYAN}Цель: Смоделировать реалистичный инцидент с несколькими одновременными проблемами.${NC}"
echo -e "${YELLOW}Смотри в Grafana: Рост Latency, скачки Error Rate, очередь транзакций (Active Tx).${NC}"
echo -e "${RED}Внимание: Система будет деградировать поэтапно.${NC}\\n"

# 1. Сброс перед началом
reset_state
sleep 2

echo -e "${BOLD}=== ЗАПУСК ЭСКАЛАЦИИ ХАОСА ===${NC}"

# --- ФАЗА 1: Латентность ---
apply_config $LATENCY_MS $ERROR_RATE_1 $DB_SLOW_1
run_traffic_phase "Рост Latency ($LATENCY_MS мс)" $PHASE_DURATION

# --- ФАЗА 2: Латентность + Ошибки ---
apply_config $LATENCY_MS_2 $ERROR_RATE_2 $DB_SLOW_2
run_traffic_phase "Latency + Ошибки ($ERROR_RATE_2%)" $PHASE_DURATION

# --- ФАЗА 3: ПОЛНЫЙ ХАОС ---
apply_config $LATENCY_MS_3 $ERROR_RATE_3 $DB_SLOW_3
run_traffic_phase "ПОЛНЫЙ ХАОС (Latency + Errors + DB Slow)" $PHASE_DURATION

# 3. Финал
echo -e "\\n${BOLD}🎉 ТЕСТ ЗАВЕРШЕН!${NC}"
echo -e "${MAGENTA}Вы только что увидели каскадный отказ системы.${NC}"
echo -e "${CYAN}Проверьте дашборд 'Fintech Workshop - Мониторинг приложения'.${NC}"
echo -e "Там должны быть видны:${NC}"
echo -e "  🔴 Пик ошибок (Error Rate)"
echo -e "   Скачок задержки (P95/P99)"
echo -e "  🔵 Рост активных транзакций (из-за медленной БД)"

# Интерактивный выбор
echo ""
read -p "Сбросить состояние системы сейчас? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  reset_state
else
  echo -e "${YELLOW}️ Система осталась в режиме хаоса. Не забудьте выполнить 'bash scripts/reset.sh' позже!${NC}"
fi

echo -e "\\n${GREEN}Сеанс хаос-инженерии завершен. Удачного анализа! ${NC}"