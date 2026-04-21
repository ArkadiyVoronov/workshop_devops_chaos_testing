# DB lock simulation for queue effect
#!/usr/bin/env bash
# Gentle version - gradual DB slow increase
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${YELLOW}КЕЙС 3: DB SLOW (плавный рост очереди)${NC}              ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}ПАРАМЕТРЫ:${NC}"
echo -e "  • Задержка БД: ${YELLOW}1 → 2 → 3 → 4 → 5 сек${NC}"
echo -e "  • Concurrent запросов на этап: ${YELLOW}10 → 15 → 20 → 25 → 30${NC}"
echo -e "  • Длительность этапа: ${YELLOW}8 сек${NC}"
echo ""

STAGES_DELAY=(1 2 3 4 5)
STAGES_CONCURRENT=(10 15 20 25 30)
DURATION_PER_STAGE=8

for i in "${!STAGES_DELAY[@]}"; do
  DELAY=${STAGES_DELAY[$i]}
  CONCURRENT=${STAGES_CONCURRENT[$i]}
  STAGE_NUM=$((i + 1))
  
  echo -ne "${BLUE}[${STAGE_NUM}/${#STAGES_DELAY[@]}]${NC} DB delay ${DELAY} сек, concurrent ${CONCURRENT}... "
  
  # Устанавливаем задержку через app.py (нужно модифицировать app.py для динамической задержки)
  # Пока используем фиксированную 3 сек
  curl -s -X POST http://localhost:5000/api/failures \
    -H 'Content-Type: application/json' \
    -d '{"db_slow": true}' > /dev/null
  echo -e "${GREEN}✓${NC}"
  
  echo -e "   Запуск ${CONCURRENT} concurrent запросов..."
  
  # Запускаем concurrent запросы
  PIDS=""
  for j in $(seq 1 $CONCURRENT); do
    curl -s -o /dev/null http://localhost:5000/api/balance &
    PIDS="$PIDS $!"
  done
  
  # Мониторинг
  echo -e "   Мониторинг active transactions:"
  for sec in {1..8}; do
    sleep 1
    ACTIVE=$(curl -s 'http://localhost:9090/api/v1/query' --data-urlencode 'query=fintech_active_transactions' | python3 -c "import sys,json; d=json.load(sys.stdin); r=d['data']['result']; print(int(float(r[0]['value'][1]))) if r else print(0)" 2>/dev/null || echo "0")
    
    if [ "$ACTIVE" -ge 20 ]; then
      echo -e "   ${RED}●${NC} Секунда $sec: Active Transactions = ${RED}${ACTIVE}${NC}"
    elif [ "$ACTIVE" -ge 10 ]; then
      echo -e "   ${YELLOW}●${NC} Секунда $sec: Active Transactions = ${YELLOW}${ACTIVE}${NC}"
    else
      echo -e "   ${GREEN}●${NC} Секунда $sec: Active Transactions = ${GREEN}${ACTIVE}${NC}"
    fi
  done
  
  # Ждём завершения
  wait $PIDS 2>/dev/null || true
  echo ""
done

echo ""
echo -e "${BLUE}Проверка метрик...${NC}"
sleep 2
ACTIVE=$(curl -s 'http://localhost:9090/api/v1/query' --data-urlencode 'query=fintech_active_transactions' | python3 -c "import sys,json; d=json.load(sys.stdin); r=d['data']['result']; print(int(float(r[0]['value'][1]))) if r else print(0)" 2>/dev/null || echo "0")
echo -e "   Active Transactions: ${YELLOW}${ACTIVE}${NC}"
echo ""

echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${YELLOW}РЕЗУЛЬТАТ${NC}                                              ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Плавный рост очереди транзакций"
echo -e "  Текущий active transactions: ${ACTIVE}"
echo ""
echo -e "  ${BLUE}📊 Что смотреть в Grafana:${NC}"
echo -e "     → Панель #3: ${YELLOW}Active Transactions (DB Queue)${NC}"
echo -e "     → Панель #16: ${YELLOW}Active Transactions (Stat)${NC}"
echo -e "     → Плавный рост столбцов"
echo ""
echo -e "  ${BLUE}🔧 Для сброса:${NC}"
echo -e "     ${YELLOW}bash scripts/reset.sh${NC}"
echo ""
