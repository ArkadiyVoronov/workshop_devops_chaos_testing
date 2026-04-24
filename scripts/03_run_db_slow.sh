#!/usr/bin/env bash
set -euo pipefail

# ==========================================
# НАСТРОЙКИ СЦЕНАРИЯ "DB SLOW"
# ==========================================
# URL эндпоинта, нагружающего БД
API_URL="http://localhost:5000/api/balance"
BULK_URL="http://localhost:5000/api/balance-bulk"

# ==========================================
# ЦВЕТА И ФОРМАТИРОВАНИЕ
# ==========================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

# ==========================================
# ФУНКЦИИ
# ==========================================

# Параллельная генерация трафика — запускает N фоновых curl каждую итерацию
parallel_traffic() {
  local duration=$1
  local batch_size=${2:-3}     # Сколько curl запускать за раз
  local interval=${3:-0.15}    # Интервал между батчами
  local start_time=$(date +%s)
  local total_reqs=0
  local total_ok=0
  local total_err=0

  echo -e "${CYAN}🚀 Параллельная нагрузка: ${batch_size} запросов/батч...${NC}"

  while true; do
    local current_time=$(date +%s)
    local elapsed=$((current_time - start_time))

    if [ $elapsed -ge $duration ]; then
      break
    fi

    # Запускаем batch_size параллельных curl
    for ((i=0; i<batch_size; i++)); do
      (
        local code=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL" --connect-timeout 3 --max-time 10)
        # Пишем в общий файл-счётчик
        if [[ "$code" =~ ^2 ]]; then
          echo "ok" >> /tmp/db_slow_counts.$$
        else
          echo "err" >> /tmp/db_slow_counts.$$
        fi
      ) &
    done
    # Ждём завершения батча
    wait

    # Подсчёт результатов
    if [ -f /tmp/db_slow_counts.$$ ]; then
      local ok_count=$(grep -c "ok" /tmp/db_slow_counts.$$ 2>/dev/null || echo 0)
      local err_count=$(grep -c "err" /tmp/db_slow_counts.$$ 2>/dev/null || echo 0)
      total_ok=$((total_ok + ok_count))
      total_err=$((total_err + err_count))
      total_reqs=$((total_reqs + ok_count + err_count))
      rm -f /tmp/db_slow_counts.$$
    fi

    # Прогресс-бар
    local percent=$((elapsed * 100 / duration))
    local bar_len=$((percent / 5))
    local bar=$(printf "%0.s#" $(seq 1 $bar_len 2>/dev/null || true))
    local space=$(printf "%0.s." $(seq 1 $((20 - bar_len)) 2>/dev/null || true))
    
    printf "\r${YELLOW}[%s%s] %d%% | Запросов: %d | ✅: %d | ❌: %d | Время: %02d:%02d${NC} " \
      "$bar" "$space" $percent $total_reqs $total_ok $total_err $((elapsed / 60)) $((elapsed % 60))

    sleep $interval
  done

  echo -e "\n${GREEN}✅ Фаза завершена: $total_reqs запросов (ok=$total_ok, err=$total_err)${NC}"
}

# Инъекция состояния в API
inject_config() {
  local payload=$1
  echo -e "${RED}⚙️ Инъекция: ${payload}${NC}"
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

# Батчевый запрос к /api/balance-bulk (создаёт очередь внутри приложения)
inject_bulk() {
  local count=$1
  echo -e "${MAGENTA}📦 Батч-запрос: $count параллельных транзакций...${NC}"
  local response=$(curl -s -X POST "$BULK_URL" \
    -H 'Content-Type: application/json' \
    -d "{\"count\": $count}" \
    --connect-timeout 3 --max-time 20)
  echo -e "${GREEN}✓ Батч завершён: $response${NC}"
}

# Сброс
reset_state() {
  echo -e "\n${YELLOW}🧹 Сброс состояния системы...${NC}"
  local response=$(curl -s -w "HTTP %{http_code}" -X POST http://localhost:5000/api/reset)
  local http_code=${response: -3}
  if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✓ Система очищена${NC}"
  else
    echo -e "${RED}✗ Ошибка сброса: $http_code${NC}"
  fi
}

# ==========================================
# ОСНОВНОЙ СЦЕНАРИЙ — 4 ФАЗЫ
# ==========================================

echo -e "\n${BOLD}🐢 ТЕСТ МЕДЛЕННОЙ БД (DB SLOW / QUEUE BUILDUP)${NC}"
echo -e "${CYAN}Цель: Показать, как задержки в БД создают очередь активных транзакций.${NC}"
echo -e "${YELLOW}Смотри Grafana → Дашборд 'DB Slow (Кейс 3)': панель Active Transactions.${NC}\n"

# Сброс перед началом
reset_state
sleep 2

# ===== ФАЗА 1: BASELINE (нормальная работа) =====
echo -e "\n${BOLD}${BLUE}═══ ФАЗА 1: BASELINE (нормальная БД) ═══${NC}"
echo -e "${CYAN}Показываем нормальный уровень активных транзакций (1-3)${NC}"
inject_config '{"db_slow": false, "latency_ms": 0, "error_rate": 0}'
sleep 1
parallel_traffic 10 3 0.2
echo -e "${GREEN}📊 active_transactions должен быть 0-3${NC}"
sleep 3

# ===== ФАЗА 2: DB SLOW (очередь растёт) =====
echo -e "\n${BOLD}${RED}═══ ФАЗА 2: DB SLOW НАЧИНАЕТСЯ ═══${NC}"
echo -e "${CYAN}Включаем замедление БД + параллельная нагрузка → очередь растёт${NC}"
inject_config '{"db_slow": true, "latency_ms": 0, "error_rate": 0}'
sleep 1
parallel_traffic 20 5 0.15
echo -e "${YELLOW}📊 active_transactions должен вырасти до 5-8+${NC}"
sleep 3

# ===== ФАЗА 3: PEAK (пиковая нагрузка) =====
echo -e "\n${BOLD}${MAGENTA}═══ ФАЗА 3: ПИКОВАЯ НАГРУЗКА ═══${NC}"
echo -e "${CYAN}Максимальная нагрузка: больше запросов + батчи → очередь >10${NC}"
inject_config '{"db_slow": true, "latency_ms": 200, "error_rate": 0}'
sleep 1
# Одновременно: параллельный трафик + батчевые запросы
parallel_traffic 15 8 0.1 &
PID_TRAFFIC=$!
# Через 3с добавляем батчи
sleep 3
inject_bulk 12
sleep 3
inject_bulk 15
wait $PID_TRAFFIC 2>/dev/null || true
echo -e "${RED}🔥 active_transactions должен превысить 10 — алерт DBSlowTransactions сработал!${NC}"
sleep 3

# ===== ФАЗА 4: RECOVERY (восстановление) =====
echo -e "\n${BOLD}${GREEN}═══ ФАЗА 4: ВОССТАНОВЛЕНИЕ ═══${NC}"
echo -e "${CYAN}Выключаем замедление — очередь должна схлопнуться${NC}"
inject_config '{"db_slow": false, "latency_ms": 0, "error_rate": 0}'
sleep 1
parallel_traffic 10 2 0.2
echo -e "${GREEN}✅ active_transactions должен вернуться к 0-3${NC}"

# ==========================================
# ФИНАЛ
# ==========================================
echo -e "\n${BOLD}🎉 ТЕСТ ЗАВЕРШЕН!${NC}"
echo -e "${YELLOW}График Active Transactions должен показать:${NC}"
echo -e "  1. Baseline (активность 0-3)"
echo -e "  2. Рост до 5-8 (DB Slow)"
echo -e "  3. Пик >10 (с алертом)"
echo -e "  4. Спад до 0-3 (Recovery)"

# Интерактивный сброс
echo ""
read -p "Сбросить состояние системы сейчас? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  reset_state
fi

echo -e "\n${GREEN}Готово. Удачного анализа!${NC}"
