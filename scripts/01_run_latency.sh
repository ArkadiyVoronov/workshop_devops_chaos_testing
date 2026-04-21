# DB lock simulation for queue effect
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
echo -e "${CYAN}║${NC}  ${YELLOW}КЕЙС 1: LATENCY (задержка)${NC}                          ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Параметры
LATENCY_MS=2000
DURATION=30
echo -e "${BLUE}ПАРАМЕТРЫ:${NC}"
echo -e "  • Задержка: ${YELLOW}${LATENCY_MS} мс${NC}"
echo -e "  • Длительность: ${YELLOW}${DURATION} сек${NC}"
echo -e "  • Ожидаемый результат: ${YELLOW}P95 ~${LATENCY_MS} мс${NC}"
echo ""

# 1. Проверка baseline
echo -ne "${BLUE}[1/5]${NC} Проверка baseline... "
P95_BEFORE=$(curl -s 'http://localhost:9090/api/v1/query' --data-urlencode 'query=histogram_quantile(0.95, rate(fintech_request_latency_seconds_bucket[1m]))' | python3 -c "import sys,json; d=json.load(sys.stdin); r=d['data']['result']; print(f\"{float(r[0]['value'][1]*1000):.0f} мс\") if r else print('0 мс')" 2>/dev/null || echo "0 мс")
echo -e "${GREEN}✓${NC} P95 Latency: ${P95_BEFORE}"
echo ""

# 2. Инъекция
echo -ne "${BLUE}[2/5]${NC} Инъекция задержки (${LATENCY_MS} мс)... "
curl -s -X POST http://localhost:5000/api/failures \
  -H 'Content-Type: application/json' \
  -d "{\"latency_ms\": ${LATENCY_MS}}" > /dev/null
echo -e "${GREEN}✓${NC} Выполнено"
echo ""

# 3. Генерация трафика
echo -e "${BLUE}[3/5]${NC} Генерация трафика (${DURATION} сек)...${NC}"
echo -e "   ${CYAN}Запросов в секунду: ~10${NC}"
echo ""

START_TIME=$(date +%s)
TOTAL=0
SLOW=0

while true; do
  CURRENT_TIME=$(date +%s)
  ELAPSED=$((CURRENT_TIME - START_TIME))
  
  if [ $ELAPSED -ge $DURATION ]; then
    break
  fi
  
  # Отправляем запрос и замеряем время
  START_REQ=$(date +%s%N)
  curl -s -o /dev/null http://localhost:5000/api/balance || true
  END_REQ=$(date +%s%N)
  
  DURATION_NS=$((END_REQ - START_REQ))
  DURATION_MS=$((DURATION_NS / 1000000))
  
  TOTAL=$((TOTAL + 1))
  
  if [ $DURATION_MS -ge $LATENCY_MS ]; then
    SLOW=$((SLOW + 1))
  fi
  
  # Обновляем строку статуса
  if [ $DURATION_MS -ge 1500 ]; then
    echo -ne "\r   ${RED}●${NC} Запросов: ${TOTAL} | Медленных (>${LATENCY_MS}мс): ${SLOW} | Время: ${ELAPSED}/${DURATION} сек | Последний: ${RED}${DURATION_MS} мс${NC}"
  elif [ $DURATION_MS -ge 500 ]; then
    echo -ne "\r   ${YELLOW}●${NC} Запросов: ${TOTAL} | Медленных (>${LATENCY_MS}мс): ${SLOW} | Время: ${ELAPSED}/${DURATION} сек | Последний: ${YELLOW}${DURATION_MS} мс${NC}"
  else
    echo -ne "\r   ${GREEN}●${NC} Запросов: ${TOTAL} | Медленных (>${LATENCY_MS}мс): ${SLOW} | Время: ${ELAPSED}/${DURATION} сек | Последний: ${GREEN}${DURATION_MS} мс${NC}"
  fi
  
  sleep 0.1
done

echo ""
echo -e "   ${GREEN}✓${NC} Трафик завершён"
echo ""

# 4. Статистика
echo -e "${BLUE}[4/5]${NC} Статистика...${NC}"
if [ $TOTAL -gt 0 ]; then
  SLOW_PCT=$((SLOW * 100 / TOTAL))
  echo ""
  echo -e "   Всего запросов:   ${TOTAL}"
  echo -e "   Медленных запросов: ${SLOW} (${SLOW_PCT}%)"
  echo ""
fi

# 5. Проверка метрик
echo -ne "${BLUE}[5/5]${NC} Проверка метрик... "
sleep 2
P95_AFTER=$(curl -s 'http://localhost:9090/api/v1/query' --data-urlencode 'query=histogram_quantile(0.95, rate(fintech_request_latency_seconds_bucket[1m]))' | python3 -c "import sys,json; d=json.load(sys.stdin); r=d['data']['result']; print(f\"{float(r[0]['value'][1]*1000):.0f} мс\") if r else print('0 мс')" 2>/dev/null || echo "0 мс")
echo -e "${GREEN}✓${NC} P95 Latency: ${P95_AFTER}"
echo ""

# Итог
echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${YELLOW}РЕЗУЛЬТАТ${NC}                                              ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  P95 Latency:  ${P95_BEFORE} → ${P95_AFTER}"
echo -e "  Медленных:    ${SLOW} из ${TOTAL} (${SLOW_PCT}%)"
echo ""
echo -e "  ${BLUE}📊 Что смотреть в Grafana:${NC}"
echo -e "     → Панель #2: ${YELLOW}Request Latency (P95/P99)${NC}"
echo -e "     → Алерт: ${YELLOW}HighLatency Alert${NC} (панель #10)"
echo ""
echo -e "  ${BLUE}🔧 Для сброса:${NC}"
echo -e "     ${YELLOW}bash scripts/reset.sh${NC}"
echo ""
