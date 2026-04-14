#!/usr/bin/env bash
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${YELLOW}КЕЙС 2: ERROR RATE${NC}                                    ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Параметры
ERROR_RATE=50
DURATION=30
echo -e "${BLUE}ПАРАМЕТРЫ:${NC}"
echo -e "  • Error Rate: ${YELLOW}${ERROR_RATE}%${NC}"
echo -e "  • Длительность: ${YELLOW}${DURATION} сек${NC}"
echo -e "  • Ожидаемый результат: ${YELLOW}~50% запросов вернут 500${NC}"
echo ""

# 1. Проверка baseline
echo -ne "${BLUE}[1/5]${NC} Проверка baseline... "
ERRORS_BEFORE=$(curl -s 'http://localhost:9090/api/v1/query' --data-urlencode 'query=sum(rate(fintech_requests_total{status="500"}[1m]))' | python3 -c "import sys,json; d=json.load(sys.stdin); r=d['data']['result']; print(f\"{float(r[0]['value'][1]):.2f}\") if r else print('0')" 2>/dev/null || echo "0")
echo -e "${GREEN}✓${NC} Errors/sec: ${ERRORS_BEFORE}"
echo ""

# 2. Инъекция
echo -ne "${BLUE}[2/5]${NC} Инъекция error rate (${ERROR_RATE}%)... "
curl -s -X POST http://localhost:5000/api/failures \
  -H 'Content-Type: application/json' \
  -d "{\"error_rate\": ${ERROR_RATE}}" > /dev/null
echo -e "${GREEN}✓${NC} Выполнено"
echo ""

# 3. Генерация трафика
echo -e "${BLUE}[3/5]${NC} Генерация трафика (${DURATION} сек)...${NC}"
echo -e "   ${CYAN}Запросов в секунду: ~10${NC}"
echo ""

START_TIME=$(date +%s)
TOTAL=0
SUCCESS=0
FAILED=0

while true; do
  CURRENT_TIME=$(date +%s)
  ELAPSED=$((CURRENT_TIME - START_TIME))
  
  if [ $ELAPSED -ge $DURATION ]; then
    break
  fi
  
  # Отправляем запрос
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/api/balance || echo "000")
  TOTAL=$((TOTAL + 1))
  
  if [ "$HTTP_CODE" = "200" ]; then
    SUCCESS=$((SUCCESS + 1))
    echo -ne "\r   ${GREEN}●${NC} Запросов: ${TOTAL} | ${GREEN}200 OK: ${SUCCESS}${NC} | ${RED}500 Error: ${FAILED}${NC} | Время: ${ELAPSED}/${DURATION} сек"
  else
    FAILED=$((FAILED + 1))
    echo -ne "\r   ${RED}●${NC} Запросов: ${TOTAL} | ${GREEN}200 OK: ${SUCCESS}${NC} | ${RED}500 Error: ${FAILED}${NC} | Время: ${ELAPSED}/${DURATION} сек"
  fi
  
  sleep 0.1
done

echo ""
echo -e "   ${GREEN}✓${NC} Трафик завершён"
echo ""

# 4. Статистика
echo -e "${BLUE}[4/5]${NC} Статистика...${NC}"
if [ $TOTAL -gt 0 ]; then
  ERROR_PCT=$((FAILED * 100 / TOTAL))
  echo ""
  echo -e "   Всего запросов:  ${TOTAL}"
  echo -e "   ${GREEN}✓ 200 OK:${NC}      ${SUCCESS} ($(echo "scale=1; $SUCCESS * 100 / $TOTAL" | bc)%)"
  echo -e "   ${RED}✗ 500 Error:${NC}   ${FAILED} ($(echo "scale=1; $FAILED * 100 / $TOTAL" | bc)%)"
  echo ""
fi

# 5. Проверка метрик
echo -ne "${BLUE}[5/5]${NC} Проверка метрик... "
sleep 2
ERRORS_AFTER=$(curl -s 'http://localhost:9090/api/v1/query' --data-urlencode 'query=sum(rate(fintech_requests_total{status="500"}[1m]))' | python3 -c "import sys,json; d=json.load(sys.stdin); r=d['data']['result']; print(f\"{float(r[0]['value'][1]):.2f}\") if r else print('0')" 2>/dev/null || echo "0")
echo -e "${GREEN}✓${NC} Errors/sec: ${ERRORS_AFTER}"
echo ""

# Итог
echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${YELLOW}РЕЗУЛЬТАТ${NC}                                              ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${RED}✗ Error Rate:${NC}  ${ERROR_PCT}% (ожидалось ~${ERROR_RATE}%)"
echo -e "  Errors/sec:     ${ERRORS_BEFORE} → ${ERRORS_AFTER}"
echo ""
echo -e "  ${BLUE}📊 Что смотреть в Grafana:${NC}"
echo -e "     → Панель #4: ${YELLOW}Error Rate (5xx)${NC}"
echo -e "     → Алерт: ${YELLOW}HighErrorRate Alert${NC} (панель #11)"
echo ""
echo -e "  ${BLUE}🔧 Для сброса:${NC}"
echo -e "     ${YELLOW}bash scripts/reset.sh${NC}"
echo ""
