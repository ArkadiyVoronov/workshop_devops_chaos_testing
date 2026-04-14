#!/usr/bin/env bash
set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${YELLOW}КЕЙС 3: DB SLOW (медленная БД)${NC}                      ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Параметры
DB_DELAY=3
CONCURRENT=20
echo -e "${BLUE}ПАРАМЕТРЫ:${NC}"
echo -e "  • Задержка БД: ${YELLOW}${DB_DELAY} сек${NC}"
echo -e "  • Concurrent запросов: ${YELLOW}${CONCURRENT}${NC}"
echo -e "  • Ожидаемый результат: ${YELLOW}Active Transactions ~${CONCURRENT}${NC}"
echo ""

# 1. Проверка baseline
echo -ne "${BLUE}[1/5]${NC} Проверка baseline... "
ACTIVE_BEFORE=$(curl -s 'http://localhost:9090/api/v1/query' --data-urlencode 'query=fintech_active_transactions' | python3 -c "import sys,json; d=json.load(sys.stdin); r=d['data']['result']; print(int(float(r[0]['value'][1]))) if r else print(0)" 2>/dev/null || echo "0")
echo -e "${GREEN}✓${NC} Active Transactions: ${ACTIVE_BEFORE}"
echo ""

# 2. Инъекция
echo -ne "${BLUE}[2/5]${NC} Инъекция DB slow (${DB_DELAY} сек задержка)... "
curl -s -X POST http://localhost:5000/api/failures \
  -H 'Content-Type: application/json' \
  -d '{"db_slow": true}' > /dev/null
echo -e "${GREEN}✓${NC} Выполнено"
echo ""

# 3. Генерация трафика
echo -e "${BLUE}[3/5]${NC} Генерация concurrent трафика...${NC}"
echo -e "   ${CYAN}Запросов: ${CONCURRENT} (параллельно)${NC}"
echo -e "   ${CYAN}Каждый держит транзакцию ${DB_DELAY} сек${NC}"
echo ""

# Запускаем concurrent запросы
PIDS=""
for i in $(seq 1 $CONCURRENT); do
  curl -s -o /dev/null http://localhost:5000/api/balance &
  PIDS="$PIDS $!"
done

# Мониторинг в реальном времени
echo -e "   ${BLUE}Мониторинг active transactions:${NC}"
for i in {1..6}; do
  sleep 1
  ACTIVE=$(curl -s 'http://localhost:9090/api/v1/query' --data-urlencode 'query=fintech_active_transactions' | python3 -c "import sys,json; d=json.load(sys.stdin); r=d['data']['result']; print(int(float(r[0]['value'][1]))) if r else print(0)" 2>/dev/null || echo "0")
  
  if [ "$ACTIVE" -ge 15 ]; then
    echo -e "   ${RED}●${NC} Секунда $i: Active Transactions = ${RED}${ACTIVE}${NC}"
  elif [ "$ACTIVE" -ge 5 ]; then
    echo -e "   ${YELLOW}●${NC} Секунда $i: Active Transactions = ${YELLOW}${ACTIVE}${NC}"
  else
    echo -e "   ${GREEN}●${NC} Секунда $i: Active Transactions = ${GREEN}${ACTIVE}${NC}"
  fi
done

# Ждём завершения
wait $PIDS 2>/dev/null || true
echo -e "   ${GREEN}✓${NC} Все запросы завершены"
echo ""

# 4. Проверка после
echo -ne "${BLUE}[4/5]${NC} Проверка после завершения... "
sleep 2
ACTIVE_AFTER=$(curl -s 'http://localhost:9090/api/v1/query' --data-urlencode 'query=fintech_active_transactions' | python3 -c "import sys,json; d=json.load(sys.stdin); r=d['data']['result']; print(int(float(r[0]['value'][1]))) if r else print(0)" 2>/dev/null || echo "0")
echo -e "${GREEN}✓${NC} Active Transactions: ${ACTIVE_AFTER}"
echo ""

# Итог
echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${YELLOW}РЕЗУЛЬТАТ${NC}                                              ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Active Transactions:  ${ACTIVE_BEFORE} → ${ACTIVE_AFTER}"
echo -e "  ${BLUE}(во время выполнения: до ~${CONCURRENT})${NC}"
echo ""
echo -e "  ${BLUE}📊 Что смотреть в Grafana:${NC}"
echo -e "     → Панель #3: ${YELLOW}Active Transactions (DB Queue)${NC}"
echo -e "     → Алерт: ${YELLOW}DBSlow Alert${NC} (панель #12)"
echo ""
echo -e "  ${BLUE}🔧 Для сброса:${NC}"
echo -e "     ${YELLOW}bash scripts/reset.sh${NC}"
echo ""
