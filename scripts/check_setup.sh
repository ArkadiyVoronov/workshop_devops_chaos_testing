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
NC='\033[0m' # No Color
BOLD='\033[1m'

# ==========================================
# НАСТРОЙКИ ПРОВЕРКИ
# ==========================================
MAX_RETRIES=5       # Сколько раз пробуем подключиться
RETRY_DELAY=3       # Пауза между попытками (сек)
TIMEOUT=5           # Таймаут одного запроса (сек)

# ==========================================
# ФУНКЦИИ
# ==========================================

# Функция ожидания сервиса с ретраями
wait_for_service() {
  local name=$1
  local url=$2
  local attempt=1

  echo -ne "${CYAN} Проверка $name...${NC}"
  
  while [ $attempt -le $MAX_RETRIES ]; do
    # Получаем код ответа, игнорируя ошибки соединения
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time $TIMEOUT "$url" 2>/dev/null || echo "000")

    if [[ "$http_code" =~ ^2 ]]; then
      echo -e " ${GREEN}✅ OK (HTTP $http_code)${NC}"
      return 0
    fi

    sleep $RETRY_DELAY
    attempt=$((attempt + 1))
    echo -ne "\r${CYAN} Проверка $name... (попытка $attempt/$MAX_RETRIES)${NC}"
  done

  echo -e " ${RED}❌ FAIL (HTTP $http_code или таймаут)${NC}"
  return 1
}

# Функция вывода заголовка секции
print_header() {
  echo -e "\\n${BOLD}==========================================${NC}"
  echo -e "${BOLD}$1${NC}"
  echo -e "${BOLD}==========================================${NC}"
}

# ==========================================
# ОСНОВНОЙ СЦЕНАРИЙ
# ==========================================

echo -e "\\n${BOLD}️  FINTECH WORKSHOP: DIAGNOSTIC CHECK${NC}"
echo -e "${CYAN}Проверяем готовность инфраструктуры к хаос-экспериментам...${NC}\\n"

ERRORS_FOUND=0

# --- 1. Docker Compose Status ---
print_header "1️⃣  Статус контейнеров"

# Проверяем, запущены ли вообще сервисы
if ! docker compose ps --services | grep -q .; then
  echo -e "${RED}️  Сервисы не найдены или docker compose не работает.${NC}"
  echo -e "${YELLOW}💡 Решение: Выполните 'docker compose up -d --build'${NC}"
  ERRORS_FOUND=1
else
  # Выводим таблицу статусов
  echo -e "${BLUE}Текущий статус сервисов:${NC}"
  docker compose ps --format "table {{.Name}}\t{{.Status}}" | sed 's/^/   /'
  
  # Проверяем, есть ли хотя бы один работающий (Up)
  if docker compose ps | grep -q "Up"; then
    echo -e "${GREEN}✅ Контейнеры запущены.${NC}"
  else
    echo -e "${RED}⚠️  Контейнеры существуют, но не работают (Exited/Restarting).${NC}"
    echo -e "${YELLOW}💡 Проверьте логи: docker compose logs${NC}"
    ERRORS_FOUND=1
  fi
fi

# --- 2. Application API ---
print_header "2️  Проверка Fintech API (Port 5000)"

# Используем отдельные вызовы вместо цикла с парсингом через ':', чтобы избежать ошибок с URL
ENDPOINTS=(
  "http://localhost:5000/health:Health Check"
  "http://localhost:5000/api/failures:Failures API"
  "http://localhost:5000/metrics:Prometheus Metrics"
)

for item in "${ENDPOINTS[@]}"; do
  # Разделяем URL и описание вручную, так как в URL есть двоеточия
  # Берем всё до последнего ":Description", но проще сделать так:
  # Мы знаем формат: URL:Description. Описание всегда одно слово или несколько после последнего двоеточия? 
  # Нет, надежнее использовать массив ассоциативный или просто вызвать функцию явно.
  
  # Простой хак: заменяем последний ':' на уникальный разделитель, потом делим
  # Или просто вызываем проверку для каждого известного эндпоинта явно (надежнее):
  
  case "$item" in
    *"health"*)
      wait_for_service "Health Check" "http://localhost:5000/health" || ERRORS_FOUND=1
      ;;
    *"failures"*)
      wait_for_service "Failures API" "http://localhost:5000/api/failures" || ERRORS_FOUND=1
      ;;
    *"metrics"*)
      wait_for_service "Prometheus Metrics" "http://localhost:5000/metrics" || ERRORS_FOUND=1
      ;;
  esac
done

# Проверка наличия конкретной метрики
echo -ne "${CYAN} Поиск метрики 'fintech_requests_total'...${NC} "
if curl -s --max-time $TIMEOUT http://localhost:5000/metrics | grep -q "fintech_requests_total"; then
  echo -e "${GREEN}✅ Найдена${NC}"
else
  echo -e "${RED}❌ Не найдена${NC}"
  echo -e "${YELLOW}💡 Возможно, приложение еще не приняло ни одного запроса или ошибка в коде.${NC}"
  ERRORS_FOUND=1
fi

# --- 3. Prometheus ---
print_header "3️⃣  Проверка Prometheus (Port 9090)"

if ! wait_for_service "Prometheus Ready" "http://localhost:9090/-/ready"; then
  echo -e "${YELLOW} Prometheus может загружать конфигурацию. Подождите 10-15 сек.${NC}"
  ERRORS_FOUND=1
fi

# --- 4. Grafana ---
print_header "4️⃣  Проверка Grafana (Port 3000)"

if ! wait_for_service "Grafana Health" "http://localhost:3000/api/health"; then
  echo -e "${YELLOW}💡 Grafana может стартовать дольше других сервисов.${NC}"
  ERRORS_FOUND=1
else
  echo -e "${GREEN}📊 Доступна по адресу: http://localhost:3000 (admin/workshop)${NC}"
fi

# --- 5. cAdvisor (Опционально, но желательно) ---
print_header "5️⃣  Проверка cAdvisor (Port 8080)"
if ! wait_for_service "cAdvisor" "http://localhost:8080"; then
  echo -e "${YELLOW}⚠️  cAdvisor недоступен. Графики ресурсов в Grafana могут быть пустыми.${NC}"
  # Не считаем это фатальной ошибкой для старта, но предупреждаем
else
  echo -e "${GREEN}✅ cAdvisor работает.${NC}"
fi

# ==========================================
# ИТОГОВЫЙ ОТЧЕТ
# ==========================================
print_header " ИТОГ ДИАГНОСТИКИ"

if [ $ERRORS_FOUND -eq 0 ]; then
  echo -e "${BOLD}${GREEN}🎉 ВСЁ ГОТОВО К ЭКСПЕРИМЕНТАМ!${NC}"
  echo -e "${CYAN}Вы можете смело запускать кейсы:${NC}"
  echo -e "   🚀 ${GREEN}bash scripts/01_run_latency.sh${NC}"
  echo -e "   💥 ${GREEN}bash scripts/02_run_error_rate.sh${NC}"
  echo -e "    ${GREEN}bash scripts/03_run_db_slow.sh${NC}"
  echo -e "   💾 ${GREEN}bash scripts/04_run_memory_leak.sh${NC}"
  echo -e "   🌪️ ${GREEN}bash scripts/05_run_chaos_mix.sh${NC}"
  echo -e "\\n${BLUE}Не забудьте открыть Grafana: http://localhost:3000${NC}"
  exit 0
else
  echo -e "${BOLD}${RED}️  ОБНАРУЖЕНЫ ПРОБЛЕМЫ${NC}"
  echo -e "${YELLOW}Система не полностью готова. Пожалуйста, проверьте логи:${NC}"
  echo -e "    ${CYAN}docker compose logs app${NC}"
  echo -e "   📝 ${CYAN}docker compose logs prometheus${NC}"
  echo -e "\\n${BLUE}После исправления запустите проверку снова:${NC}"
  echo -e "   🔁 ${CYAN}bash scripts/check_setup.sh${NC}"
  exit 1
fi