#!/usr/bin/env bash
set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${YELLOW}КЕЙС 5: CHAOS MIX (комбинированный отказ)${NC}         ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Параметры
LATENCY_MS=800
ERROR_RATE=10
DB_SLOW=true
DURATION=30

echo -e "${BLUE}ПАРАМЕТРЫ:${NC}"
echo -e "  • Задержка: ${YELLOW}${LATENCY_MS} мс${NC}"
echo -e "  • Error Rate: ${YELLOW}${ERROR_RATE}%${NC}"
echo -e "  • DB Slow: ${YELLOW}${DB_SLOW} (3 сек)${NC}"
echo -e "  • Длительность: ${YELLOW}${DURATION} сек${NC}"
echo ""
echo -e "  ${RED}⚠ Ожидаемый эффект:${NC}"
echo -e "     → Рост latency (P95)"
echo -e "     → Ошибки 500 (~${ERROR_RATE}%)"
echo -e "     → Очередь транзакций в БД"
echo -e "     → Все 4 алерта могут сработать"
echo ""

# 1. Проверка baseline
echo -ne "${BLUE}[1/6]${NC} Проверка baseline... "
P95_BEFORE=$(curl -s 'http://localhost:9090/api/v1/query' --data-urlencode 'query=histogram_quantile(0.95, rate(fintech_request_latency_seconds_bucket[1m]))' | python3 -c "import sys,json; d=json.load(sys.stdin); r=d['data']['result']; print(f\"{float(r[0]['value'][1]*1000):.0f} мс\") if r else print('0 мс')" 2>/dev/null || echo "0 мс")
ERRORS_BEFORE=$(curl -s 'http://localhost:9090/api/v1/query' --data-urlencode 'query=sum(rate(fintech_requests_total{status="500"}[1m]))' | python3 -c "import sys,json; d=json.load(sys.stdin); r=d['data']['result']; print(f\"{float(r[0]['value'][1]):.2f}\") if r else print('0')" 2>/dev/null || echo "0")
ACTIVE_BEFORE=$(curl -s 'http://localhost:9090/api/v1/query' --data-urlencode 'query=fintech_active_transactions' | python3 -c "import sys,json; d=json.load(sys.stdin); r=d['data']['result']; print(int(float(r[0]['value'][1]))) if r else print(0)" 2>/dev/null || echo "0")
echo -e "${GREEN}✓${NC}"
echo -e "   P95 Latency:        ${P95_BEFORE}"
echo -e "   Errors/sec:         ${ERRORS_BEFORE}"
echo -e "   Active Transactions: ${ACTIVE_BEFORE}"
echo ""

# 2. Инъекция
echo -ne "${BLUE}[2/6]${NC} Инъекция chaos mix... "
curl -s -X POST http://localhost:5000/api/failures \
  -H 'Content-Type: application/json' \
  -d "{\"latency_ms\": ${LATENCY_MS}, \"error_rate\": ${ERROR_RATE}, \"db_slow\": true}" > /dev/null
echo -e "${GREEN}✓${NC} Выполнено"
echo ""

# 3. Генерация трафика
echo -e "${BLUE}[3/6]${NC} Генерация трафика (${DURATION} сек)...${NC}"
echo -e "   ${CYAN}Запросов в секунду: ~10${NC}"
echo ""

START_TIME=$(date +%s)
TOTAL=0
SUCCESS=0
FAILED=0
SLOW=0

while true; do
  CURRENT_TIME=$(date +%s)
  ELAPSED=$((CURRENT_TIME - START_TIME))
  
  if [ $ELAPSED -ge $DURATION ]; then
    break
  fi
  
  # Отправляем запрос и замеряем время
  START_REQ=$(date +%s%N)
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/api/balance || echo "000")
  END_REQ=$(date +%s%N)
  
  DURATION_NS=$((END_REQ - START_REQ))
  DURATION_MS=$((DURATION_NS / 1000000))
  
  TOTAL=$((TOTAL + 1))
  
  if [ "$HTTP_CODE" = "200" ]; then
    SUCCESS=$((SUCCESS + 1))
  else
    FAILED=$((FAILED + 1))
  fi
  
  if [ $DURATION_MS -ge ${LATENCY_MS} ]; then
    SLOW=$((SLOW + 1))
  fi
  
  # Обновляем строку статуса
  if [ $FAILED -gt 0 ] || [ $SLOW -gt 0 ]; then
    echo -ne "\r   ${RED}●${NC} Запросов: ${TOTAL} | ${GREEN}OK: ${SUCCESS}${NC} | ${RED}500: ${FAILED}${NC} | Медленных: ${SLOW} | Время: ${ELAPSED}/${DURATION} сек"
  else
    echo -ne "\r   ${GREEN}●${NC} Запросов: ${TOTAL} | ${GREEN}OK: ${SUCCESS}${NC} | ${RED}500: ${FAILED}${NC} | Медленных: ${SLOW} | Время: ${ELAPSED}/${DURATION} сек"
  fi
  
  sleep 0.1
done

echo ""
echo -e "   ${GREEN}✓${NC} Трафик завершён"
echo ""

# 4. Статистика
echo -e "${BLUE}[4/6]${NC} Статистика...${NC}"
if [ $TOTAL -gt 0 ]; then
  ERROR_PCT=$((FAILED * 100 / TOTAL))
  SLOW_PCT=$((SLOW * 100 / TOTAL))
  echo ""
  echo -e "   Всего запросов:     ${TOTAL}"
  echo -e "   ${GREEN}✓ 200 OK:${NC}        ${SUCCESS} ($(echo "scale=1; $SUCCESS * 100 / $TOTAL" | bc)%)"
  echo -e "   ${RED}✗ 500 Error:${NC}     ${FAILED} ($(echo "scale=1; $FAILED * 100 / $TOTAL" | bc)%)"
  echo -e "   Медленных (>${LATENCY_MS}мс): ${SLOW} (${SLOW_PCT}%)"
  echo ""
fi

# 5. Проверка метрик
echo -ne "${BLUE}[5/6]${NC} Проверка метрик... "
sleep 3
P95_AFTER=$(curl -s 'http://localhost:9090/api/v1/query' --data-urlencode 'query=histogram_quantile(0.95, rate(fintech_request_latency_seconds_bucket[1m]))' | python3 -c "import sys,json; d=json.load(sys.stdin); r=d['data']['result']; print(f\"{float(r[0]['value'][1]*1000):.0f} мс\") if r else print('0 мс')" 2>/dev/null || echo "0 мс")
ERRORS_AFTER=$(curl -s 'http://localhost:9090/api/v1/query' --data-urlencode 'query=sum(rate(fintech_requests_total{status="500"}[1m]))' | python3 -c "import sys,json; d=json.load(sys.stdin); r=d['data']['result']; print(f\"{float(r[0]['value'][1]):.2f}\") if r else print('0')" 2>/dev/null || echo "0")
ACTIVE_AFTER=$(curl -s 'http://localhost:9090/api/v1/query' --data-urlencode 'query=fintech_active_transactions' | python3 -c "import sys,json; d=json.load(sys.stdin); r=d['data']['result']; print(int(float(r[0]['value'][1]))) if r else print(0)" 2>/dev/null || echo "0")
echo -e "${GREEN}✓${NC}"
echo -e "   P95 Latency:        ${P95_BEFORE} → ${P95_AFTER}"
echo -e "   Errors/sec:         ${ERRORS_BEFORE} → ${ERRORS_AFTER}"
echo -e "   Active Transactions: ${ACTIVE_BEFORE} → ${ACTIVE_AFTER}"
echo ""

# 6. Проверка алертов
echo -ne "${BLUE}[6/6]${NC} Проверка алертов... "
ALERTS_FIRING=$(curl -s 'http://localhost:9090/api/v1/query' --data-urlencode 'query=ALERTS{alertstate="firing"}' | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d['data']['result']))" 2>/dev/null || echo "0")
echo -e "${GREEN}✓${NC}"
if [ "$ALERTS_FIRING" -gt 0 ]; then
  echo -e "   ${RED}⚠ Алертов в состоянии FIRING: ${ALERTS_FIRING}${NC}"
  curl -s 'http://localhost:9090/api/v1/query' --data-urlencode 'query=ALERTS{alertstate="firing"}' | python3 -c "
import sys,json
d=json.load(sys.stdin)
for r in d['data']['result']:
    print(f\"      → {r['metric'].get('alertname','unknown')}\")
" 2>/dev/null || true
else
  echo -e "   ${GREEN}✓ Алертов в состоянии FIRING: 0${NC}"
fi
echo ""

# Итог
echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${YELLOW}РЕЗУЛЬТАТ${NC}                                              ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BLUE}Метрики:${NC}"
echo -e "     P95 Latency:  ${P95_BEFORE} → ${P95_AFTER}"
echo -e "     Errors/sec:   ${ERRORS_BEFORE} → ${ERRORS_AFTER}"
echo -e "     Active TX:    ${ACTIVE_BEFORE} → ${ACTIVE_AFTER}"
echo ""
echo -e "  ${BLUE}Статистика:${NC}"
echo -e "     Запросов:     ${TOTAL}"
echo -e "     Ошибок:       ${FAILED} (${ERROR_PCT}%)"
echo -e "     Медленных:    ${SLOW} (${SLOW_PCT}%)"
echo ""
echo -e "  ${BLUE}📊 Что смотреть в Grafana:${NC}"
echo -e "     → Панель #2:  ${YELLOW}Request Latency (P95/P99)${NC}"
echo -e "     → Панель #4:  ${YELLOW}Error Rate (5xx)${NC}"
echo -e "     → Панель #14: ${YELLOW}Current Error Rate${NC}"
echo -e "     → Панель #3:  ${YELLOW}Active Transactions${NC}"
echo -e "     → Панели #10-13: ${YELLOW}Алерты${NC}"
echo ""
echo -e "  ${BLUE}🔧 Для сброса:${NC}"
echo -e "     ${YELLOW}bash scripts/reset.sh${NC}"
echo ""
