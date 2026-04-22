#!/usr/bin/env bash
set -euo pipefail

# ==========================================
# НАСТРОЙКИ СЦЕНАРИЯ (можно менять)
# ==========================================
# Количество стадий теста (постепенное увеличение нагрузки)
STAGES=5
# Длительность каждой стадии в секундах
STAGE_DURATION=8
# Интервал между запросами (сек)
TRAFFIC_INTERVAL=0.2
# Базовая задержка на первой стадии (мс)
BASE_LATENCY=200
# Шаг увеличения задержки на каждой стадии (мс)
LATENCY_STEP=400

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

# Функция вывода прогресса с красивой строкой состояния
show_progress() {
  local stage=$1
  local duration=$2
  local start_time=$(date +%s)
  local requests=0
  local errors=0

  echo -e "${CYAN}🚀 Генерация трафика (нагрузка на API)...${NC}"
  
  while true; do
    local current_time=$(date +%s)
    local elapsed=$((current_time - start_time))
    
    # Проверка окончания стадии
    if [ $elapsed -ge $duration ]; then
      break
    fi

    # Отправка запроса к health-эндпоинту
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/health)
    
    if [ "$http_code" = "200" ]; then
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
    printf "\r${YELLOW}[%s%s] %d%% | Запросов: %d | Ошибок: %d | Время: %02d:%02d${NC} " \
      "$bar" "$space" $percent $requests $errors $((elapsed / 60)) $((elapsed % 60))
    
    sleep $TRAFFIC_INTERVAL
  done
  
  echo -e "\\n${GREEN}✅ Стадия $stage завершена: выполнено $requests запросов.${NC}"
}

# Функция инъекции задержки
inject_latency() {
  local latency=$1
  echo -e "${RED}⚙️ Инъекция задержки: ${latency} мс${NC}"
  
  local response=$(curl -s -w "HTTP %{http_code}" -X POST http://localhost:5000/api/failures \
    -H 'Content-Type: application/json' \
    -d "{\"latency_ms\": $latency}")
  
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
  echo -e "\\n${YELLOW} Сброс состояния системы...${NC}"
  local response=$(curl -s -w "HTTP %{http_code}" -X POST http://localhost:5000/api/reset)
  local http_code=${response: -3}
  
  if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✓ Система очищена, задержки сброшены${NC}"
  else
    echo -e "${RED}✗ Ошибка сброса (HTTP $http_code)${NC}"
  fi
}

# ==========================================
# ОСНОВНОЙ СЦЕНАРИЙ
# ==========================================

echo -e "\\n${BOLD}⏱️ ТЕСТ РОСТА ЗАДЕРЖКИ (LATENCY SPIKE)${NC}"
echo -e "${CYAN}Цель: Показать, как постепенный рост latency влияет на P95/P99 и RPS.${NC}"
echo -e "${YELLOW}Смотри в Grafana: панель 'Latency (P95)' и 'Запросы в секунду'.${NC}"
echo -e "${RED}Внимание: Не закрывай терминал до завершения, иначе тест прервется.${NC}\\n"

# 1. Сброс перед началом
reset_state
sleep 2

# 2. Цикл по стадиям
echo -e "${BLUE}=== ЗАПУСК ЭСКАЛАЦИИ ЗАДЕРЖЕК ===${NC}"

for ((stage=1; stage<=STAGES; stage++)); do
  CURRENT_LATENCY=$((BASE_LATENCY + (stage - 1) * LATENCY_STEP))
  
  echo -e "\\n${BOLD}--- Стадия $stage/$STAGES ---${NC}"
  echo -e "${CYAN}Целевая задержка: ${CURRENT_LATENCY} мс${NC}"
  
  # Применяем задержку
  inject_latency $CURRENT_LATENCY
  
  sleep 1 # Пауза перед стартом трафика, чтобы метрики обновились
  
  # Запускаем генерацию трафика
  show_progress $stage $STAGE_DURATION
  
  echo -e "${GREEN}📈 Задержка должна расти ступеньками. Проверь график P95!${NC}"
  sleep 2
done

# 3. Финал
echo -e "\\n${BOLD}🎉 ТЕСТ ЗАВЕРШЕН!${NC}"
echo -e "${YELLOW}График latency должен показывать устойчивый тренд вверх.${NC}"
echo -e "${CYAN}Если алерт 'HighLatency' еще не сработал, подожди немного или запусти еще один цикл.${NC}"

# Интерактивный выбор
echo ""
read -p "Сбросить состояние системы сейчас? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  reset_state
else
  echo -e "${YELLOW}️ Система осталась в режиме высокой задержки. Не забудь выполнить 'bash scripts/reset.sh' позже!${NC}"
fi

echo -e "\\n${GREEN}Готово. Удачного мониторинга! 🚀${NC}"