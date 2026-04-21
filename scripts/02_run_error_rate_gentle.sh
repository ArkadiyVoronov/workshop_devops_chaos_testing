# DB lock simulation for queue effect
#!/usr/bin/env bash
# Gentle version - gradual error rate increase
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${YELLOW}КЕЙС 2: ERROR RATE (плавный рост)${NC}                   ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Плавное увеличение: 5% → 10% → 20% → 30% → 50%
STAGES=(5 10 20 30 50)
DURATION_PER_STAGE=8

echo -e "${BLUE}ПАРАМЕТРЫ:${NC}"
echo -e "  • Этапов: ${YELLOW}${#STAGES[@]}${NC}"
echo -e "  • Error Rate на этап: ${YELLOW}${STAGES[*]}%${NC}"
echo -e "  • Длительность этапа: ${YELLOW}${DURATION_PER_STAGE} сек${NC}"
echo -e "  • Общая длительность: ${YELLOW}$(( ${#STAGES[@]} * DURATION_PER_STAGE )) сек${NC}"
echo ""

for i in "${!STAGES[@]}"; do
  ERROR_RATE=${STAGES[$i]}
  STAGE_NUM=$((i + 1))
  
  echo -ne "${BLUE}[${STAGE_NUM}/${#STAGES[@]}]${NC} Инъекция error rate ${ERROR_RATE}%... "
  curl -s -X POST http://localhost:5000/api/failures \
    -H 'Content-Type: application/json' \
    -d "{\"error_rate\": ${ERROR_RATE}}" > /dev/null
  echo -e "${GREEN}✓${NC}"
  
  echo -e "   Мониторинг (${DURATION_PER_STAGE} сек):"
  
  START_TIME=$(date +%s)
  TOTAL=0
  FAILED=0
  
  while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    
    if [ $ELAPSED -ge $DURATION_PER_STAGE ]; then
      break
    fi
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/api/balance || echo "000")
    TOTAL=$((TOTAL + 1))
    
    if [ "$HTTP_CODE" != "200" ]; then
      FAILED=$((FAILED + 1))
    fi
    
    CURRENT_ERROR_RATE=$((FAILED * 100 / TOTAL))
    
    if [ $CURRENT_ERROR_RATE -ge 30 ]; then
      echo -ne "\r   ${RED}●${NC} Ошибок: ${FAILED}/${TOTAL} (${CURRENT_ERROR_RATE}%) | Цель: ${ERROR_RATE}% | Время: ${ELAPSED}/${DURATION_PER_STAGE} сек"
    elif [ $CURRENT_ERROR_RATE -ge 10 ]; then
      echo -ne "\r   ${YELLOW}●${NC} Ошибок: ${FAILED}/${TOTAL} (${CURRENT_ERROR_RATE}%) | Цель: ${ERROR_RATE}% | Время: ${ELAPSED}/${DURATION_PER_STAGE} сек"
    else
      echo -ne "\r   ${GREEN}●${NC} Ошибок: ${FAILED}/${TOTAL} (${CURRENT_ERROR_RATE}%) | Цель: ${ERROR_RATE}% | Время: ${ELAPSED}/${DURATION_PER_STAGE} сек"
    fi
    
    sleep 0.5
  done
  echo ""
done

echo ""
echo -e "${BLUE}Проверка метрик...${NC}"
sleep 2
ERRORS=$(curl -s 'http://localhost:9090/api/v1/query' --data-urlencode 'query=sum(rate(fintech_requests_total{status="500"}[1m]))' | python3 -c "import sys,json; d=json.load(sys.stdin); r=d['data']['result']; print(f\"{float(r[0]['value'][1]):.2f}\") if r else print('0')" 2>/dev/null || echo "0")
echo -e "   Errors/sec: ${YELLOW}${ERRORS}${NC}"
echo ""

echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${YELLOW}РЕЗУЛЬТАТ${NC}                                              ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Плавный рост error rate от 5% до 50%"
echo -e "  Текущий errors/sec: ${ERRORS}"
echo ""
echo -e "  ${BLUE}📊 Что смотреть в Grafana:${NC}"
echo -e "     → Панель #4: ${YELLOW}Error Rate (5xx)${NC}"
echo -e "     → Панель #14: ${YELLOW}Current Error Rate${NC}"
echo -e "     → Панель #15: ${YELLOW}Success vs Errors (stacked)${NC}"
echo -e "     → Плавный рост красной области"
echo ""
echo -e "  ${BLUE}🔧 Для сброса:${NC}"
echo -e "     ${YELLOW}bash scripts/reset.sh${NC}"
echo ""
