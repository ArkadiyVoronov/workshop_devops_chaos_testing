#!/usr/bin/env bash
set -euo pipefail

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

# Функция для имитации "очистки" (анимация)
show_cleanup_animation() {
  local steps=("Сброс задержек..." "Очистка очереди ошибок..." "Высвобождение памяти..." "Перезапуск пула БД..." "Калибровка метрик...")
  
  for step in "${steps[@]}"; do
    echo -ne "\r${CYAN}🧹 $step ${NC}"
    sleep 0.4
    # Добавляем немного случайности для реалистичности
    sleep 0.1
  done
  echo -e "\r${CYAN}🧹 Очистка завершена!          ${NC}"
}

# Проверка здоровья системы после сброса
check_health() {
  echo -e "\\n${BLUE}🏥 Проверка состояния системы...${NC}"
  
  local health_url="http://localhost:5000/health"
  local metrics_url="http://localhost:5000/metrics"
  
  # Проверяем Health endpoint
  if curl -s -f "$health_url" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ API: Здоров${NC}"
  else
    echo -e "${RED}❌ API: Не отвечает (возможно, перезагружается)${NC}"
    return 1
  fi

  # Проверяем наличие базовых метрик
  if curl -s "$metrics_url" | grep -q "fintech_requests_total"; then
    echo -e "${GREEN}✅ Метрики: Активны${NC}"
  else
    echo -e "${YELLOW}⚠️  Метрики: Пока не доступны (подождите пару секунд)${NC}"
  fi
  
  return 0
}

# ==========================================
# ОСНОВНОЙ СЦЕНАРИЙ
# ==========================================

echo -e "\\n${BOLD}🔄 ВОССТАНОВЛЕНИЕ СИСТЕМЫ (RESET)${NC}"
echo -e "${YELLOW}Отменяем все инъекции хаоса и возвращаемся к Baseline...${NC}\\n"

# 1. Отправка команды сброса
echo -e "${MAGENTA} Отправка команды сброса на сервер...${NC}"
response=$(curl -s -w "HTTP %{http_code}" -X POST http://localhost:5000/api/reset)
http_code=${response: -3}

if [ "$http_code" = "200" ]; then
  echo -e "${GREEN}✓ Команда принята сервером${NC}"
else
  echo -e "${RED}✗ Ошибка связи с сервером (HTTP $http_code). Попробуйте перезагрузить контейнер app.${NC}"
  exit 1
fi

# 2. Анимация очистки
show_cleanup_animation

# 3. Пауза для стабилизации
sleep 1

# 4. Проверка здоровья
if check_health; then
  echo -e "\\n${BOLD}🎉 СИСТЕМА ВОССТАНОВЛЕНА!${NC}"
  echo -e "${GREEN}Все параметры сброшены к заводским настройкам.${NC}"
  echo -e "${CYAN}Готов к следующему эксперименту! ${NC}"
else
  echo -e "\\n${YELLOW}⚠️ Система восстановлена, но требует внимания.${NC}"
  echo -e "${CYAN}Попробуйте подождать 5 секунд или перезапустить сервис app.${NC}"
fi

echo ""