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
echo -e "\\n${BOLD}🛡️  FINTECH WORKSHOP: ENVIRONMENT CHECK${NC}"
echo -e "${CYAN}Анализируем вашу систему перед запуском...${NC}\\n"

OS_TYPE="unknown"
IS_WINDOWS_SUBSYSTEM=false

# Определяем ОС
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
  OS_TYPE="Windows Native (CMD/PowerShell)"
elif [[ "$OSTYPE" == "linux-gnu" ]]; then
  # Проверяем, не WSL ли это
  if grep -qi microsoft /proc/version 2>/dev/null; then
    OS_TYPE="WSL (Windows Subsystem for Linux)"
    IS_WINDOWS_SUBSYSTEM=true
  else
    OS_TYPE="Linux (Native)"
  fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
  OS_TYPE="macOS"
else
  OS_TYPE="Unknown ($OSTYPE)"
fi

echo -e "${BLUE}Обнаружена система: ${OS_TYPE}${NC}"

# Логика для разных ОС
if [[ "$OS_TYPE" == "Windows Native (CMD/PowerShell)" ]]; then
  echo -e "\\n${RED}⚠️  ВНИМАНИЕ: Вы запускаете скрипт из обычной PowerShell или CMD.${NC}"
  echo -e "${YELLOW}Этот воркшоп требует Linux-окружения для работы Bash-скриптов и Docker Compose.${NC}"
  echo -e "\\n${MAGENTA}💡 РЕШЕНИЕ:${NC}"
  echo -e "1. Установите **WSL 2** (Windows Subsystem for Linux)."
  echo -e "   Команда в PowerShell (Admin): ${CYAN}wsl --install${NC}"
  echo -e "2. Перезагрузите компьютер."
  echo -e "3. Откройте терминал **Ubuntu** (или WSL) и перейдите в папку проекта."
  echo -e "4. Запустите этот скрипт снова внутри WSL."
  echo -e "\\n${YELLOW}Или используйте GitHub Codespaces (работает в браузере без установки).${NC}"
  exit 1
fi

if [[ "$IS_WINDOWS_SUBSYSTEM" == true ]]; then
  echo -e "${GREEN}✅ Отлично! Вы используете WSL. Это рекомендуемая среда для Windows.${NC}"
  echo -e "${YELLOW}Примечание: Убедитесь, что Docker Desktop запущен и интегрирован с WSL.${NC}"
  sleep 2
fi

# ==========================================
# 1. ПРОВЕРКА DOCKER COMPOSE
# ==========================================
print_header "1️⃣  Статус контейнеров"

if ! command -v docker &> /dev/null; then
  echo -e "${RED}❌ Docker не найден в системе.${NC}"
  echo -e "${YELLOW} Решение: Установите Docker Desktop и перезапустите терминал.${NC}"
  exit 1
fi

if ! docker compose ps --services | grep -q . 2>/dev/null; then
  echo -e "${RED}⚠️  Сервисы не найдены или docker compose не работает.${NC}"
  echo -e "${YELLOW} Решение: Выполните 'docker compose up -d --build'${NC}"
  ERRORS_FOUND=1
else
  echo -e "${BLUE}Текущий статус сервисов:${NC}"
  docker compose ps --format "table {{.Name}}\t{{.Status}}" | sed 's/^/   /'
  
  if docker compose ps | grep -q "Up"; then
    echo -e "${GREEN}✅ Контейнеры запущены и работают.${NC}"
    ERRORS_FOUND=0
  else
    echo -e "${RED}⚠️  Контейнеры существуют, но не работают (Exited/Restarting).${NC}"
    echo -e "${YELLOW}💡 Проверьте логи: docker compose logs${NC}"
    ERRORS_FOUND=1
  fi
fi

# ==========================================
# 2. ПРОВЕРКА API
# ==========================================
print_header "2️⃣  Проверка Fintech API (Port 5000)"

ENDPOINTS=(
  "http://localhost:5000/health:Health Check"
  "http://localhost:5000/api/failures:Failures API"
  "http://localhost:5000/metrics:Prometheus Metrics"
)

for item in "${ENDPOINTS[@]}"; do
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

echo -ne "${CYAN} Поиск метрики 'fintech_requests_total'...${NC} "
if curl -s --max-time $TIMEOUT http://localhost:5000/metrics | grep -q "fintech_requests_total"; then
  echo -e "${GREEN}✅ Найдена${NC}"
else
  echo -e "${RED}❌ Не найдена${NC}"
  echo -e "${YELLOW}💡 Возможно, приложение еще не приняло запросов.${NC}"
  ERRORS_FOUND=1
fi

# ==========================================
# 3. PROMETHEUS & GRAFANA
# ==========================================
print_header "3️⃣  Проверка Prometheus (Port 9090)"
if ! wait_for_service "Prometheus Ready" "http://localhost:9090/-/ready"; then
  echo -e "${YELLOW}⏳ Prometheus может загружаться. Подождите 15 сек и попробуйте снова.${NC}"
  ERRORS_FOUND=1
fi

print_header "4️  Проверка Grafana (Port 3000)"
if ! wait_for_service "Grafana Health" "http://localhost:3000/api/health"; then
  echo -e "${YELLOW}⏳ Grafana может стартовать дольше других.${NC}"
  ERRORS_FOUND=1
else
  echo -e "${GREEN}📊 Доступна: http://localhost:3000 (admin/workshop)${NC}"
fi

print_header "5️⃣  Проверка cAdvisor (Port 8080)"
if ! wait_for_service "cAdvisor" "http://localhost:8080"; then
  echo -e "${YELLOW}⚠️  cAdvisor недоступен. Графики ресурсов (CPU/RAM) могут быть пустыми.${NC}"
else
  echo -e "${GREEN}✅ cAdvisor работает.${NC}"
fi

# ==========================================
# ИТОГ
# ==========================================
print_header "🏁 ИТОГ ДИАГНОСТИКИ"

if [ ${ERRORS_FOUND:-0} -eq 0 ]; then
  echo -e "${BOLD}${GREEN}🎉 ВСЁ ГОТОВО К ЭКСПЕРИМЕНТАМ!${NC}"
  echo -e "${CYAN}Запускайте кейсы:${NC}"
  echo -e "    ${GREEN}bash scripts/01_run_latency.sh${NC}"
  echo -e "   💥 ${GREEN}bash scripts/02_run_error_rate.sh${NC}"
  echo -e "    ${GREEN}bash scripts/03_run_db_slow.sh${NC}"
  echo -e "   💾 ${GREEN}bash scripts/04_run_memory_leak.sh${NC}"
  echo -e "   🌪️ ${GREEN}bash scripts/05_run_chaos_mix.sh${NC}"
  echo -e "\\n${BLUE}Открывайте Grafana и наблюдайте за хаосом!${NC}"
  exit 0
else
  echo -e "${BOLD}${RED}️  ОБНАРУЖЕНЫ ПРОБЛЕМЫ${NC}"
  echo -e "${YELLOW}Проверьте логи:${NC}"
  echo -e "   ${CYAN}docker compose logs app${NC}"
  echo -e "   ${CYAN}docker compose logs prometheus${NC}"
  echo -e "\\n${BLUE}После исправления запустите проверку снова:${NC}"
  echo -e "   🔁 ${CYAN}bash scripts/check_setup.sh${NC}"
  exit 1
fi