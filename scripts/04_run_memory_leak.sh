#!/usr/bin/env bash
set -euo pipefail

# ==========================================
# НАСТРОЙКИ СЦЕНАРИЯ (можно менять)
# ==========================================
# Размер утечки памяти в МБ на один запрос (чем больше, тем быстрее растет график)
LEAK_SIZE_MB=5
# Количество стадий теста (постепенное увеличение нагрузки)
STAGES=5
# Длительность каждой стадии в секундах
STAGE_DURATION=10
# Интервал между запросами (сек)
TRAFFIC_INTERVAL=0.2

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

# Функция вывода прогресса
show_progress() {
  local stage=$1
  local duration=$2
  local start_time=$(date +%s)
  local requests=0

  echo -e "${BLUE}🚀 Генерация трафика для утечки памяти...${NC}"
  
  while true; do
    local current_time=$(date +%s)
    local elapsed=$((current_time - start_time))
    
    # Проверка окончания стадии
    if [ $elapsed -ge $duration ]; then
      break
    fi

    # Отправка запроса (вызываем эндпоинт, который тратит память)
    # Используем /api/balance, так как он вызывает inject_failures()
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/api/balance)
    
    if [ "$http_code" = "200" ]; then
      requests=$((requests + 1))
    fi

    # Вывод прогресса в одну строку (обновляемая)
    local percent=$((elapsed * 100 / duration))
    printf "\r${CYAN}Стадия %d/%d: [%-20s] %d%% | Запросов: %d | Время: %02d:%02d${NC} " \
      $stage $STAGES "$(printf '#%.0s' $(seq 1 $((percent / 5))))" $percent $requests $((elapsed / 60)) $((elapsed % 60))
    
    sleep $TRAFFIC_INTERVAL
  done
  
  echo -e "\\n${GREEN}✅ Стадия $stage завершена: выполнено $requests запросов.${NC}"
}

# Функция инъекции утечки
inject_memory_leak() {
  local size=$1
  echo -e "${YELLOW}⚙️ Настройка утечки: ${size} МБ на запрос${NC}"
  
  local response=$(curl -s -w "HTTP %{http_code}" -X POST http://localhost:5000/api/failures \
    -H 'Content-Type: application/json' \
    -d "{\"memory_leak_mb\": $size}")
  
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
    echo -e "${GREEN}✓ Система очищена, память освобождена${NC}"
  else
    echo -e "${RED}✗ Ошибка сброса (HTTP $http_code)${NC}"
  fi
}

# ==========================================
# ОСНОВНОЙ СЦЕНАРИЙ
# ==========================================

echo -e "\\n${BOLD}💾 ТЕСТ УТЕЧКИ ПАМЯТИ (MEMORY LEAK)${NC}"
echo -e "${CYAN}Цель: Показать рост потребления памяти контейнера и срабатывание алерта MemoryPressure.${NC}"
echo -e "${YELLOW}Смотри в Grafana: панель 'Использование памяти приложением' (container_memory_usage_bytes).${NC}"
echo -e "${RED}Внимание: Не закрывай терминал до завершения, иначе тест прервется.${NC}\\n"

# 1. Сброс перед началом
reset_state
sleep 2

# 2. Цикл по стадиям
echo -e "${BLUE}=== ЗАПУСК ТЕСТА ===${NC}"

for ((stage=1; stage<=STAGES; stage++)); do
  echo -e "\\n${BOLD}--- Стадия $stage/$STAGES ---${NC}"
  
  # Включаем утечку (можно увеличивать размер на каждой стадии, если нужно)
  # Сейчас оставляем константным, но можно сделать: CURRENT_LEAK=$((LEAK_SIZE_MB * stage))
  inject_memory_leak $LEAK_SIZE_MB
  
  sleep 1 # Пауза перед стартом трафика
  
  # Запускаем генерацию трафика
  show_progress $stage $STAGE_DURATION
  
  echo -e "${GREEN}📈 Память должна расти ступеньками. Проверь график!${NC}"
  sleep 2
done

# 3. Финал
echo -e "\\n${BOLD}🎉 ТЕСТ ЗАВЕРШЕН!${NC}"
echo -e "${YELLOW}График памяти должен показывать устойчивый тренд вверх.${NC}"
echo -e "${CYAN}Если алерт 'MemoryPressure' еще не сработал, подожди немного или запусти еще один цикл.${NC}"

# Автоматический сброс (раскомментируй, если хочешь автоматическую очистку)
read -p "Сбросить состояние сейчас? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  reset_state
else
  echo -e "${YELLOW}⚠️ Система осталась в режиме утечки. Не забудь выполнить 'bash scripts/reset.sh' позже!${NC}"
fi

echo -e "\\n${GREEN}Готово. Удачного мониторинга! 🚀${NC}"