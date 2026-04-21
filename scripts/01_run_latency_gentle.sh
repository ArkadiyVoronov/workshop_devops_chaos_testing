# DB lock simulation for queue effect
#!/usr/bin/env bash
# Gentle version - gradual latency increase
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${YELLOW}КЕЙС 1: LATENCY (плавный рост)${NC}                      ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Плавное увеличение: 200ms → 400ms → 600ms → 800ms → 1000ms
STAGES=(200 400 600 800 1000)
DURATION_PER_STAGE=10

echo -e "${BLUE}ПАРАМЕТРЫ:${NC}"
echo -e "  • Этапов: ${YELLOW}${#STAGES[@]}${NC}"
echo -e "  • Задержка на этап: ${YELLOW}${STAGES[*]} мс${NC}"
echo -e "  • Длительность этапа: ${YELLOW}${DURATION_PER_STAGE} сек${NC}"
echo -e "  • Общая длительность: ${YELLOW}$(( ${#STAGES[@]} * DURATION_PER_STAGE )) сек${NC}"
echo ""

for i in "${!STAGES[@]}"; do
  LATENCY=${STAGES[$i]}
  STAGE_NUM=$((i + 1))
  
  echo -ne "${BLUE}[${STAGE_NUM}/${#STAGES[@]}]${NC} Инъекция задержки ${LATENCY} мс... "
  curl -s -X POST http://localhost:5000/api/failures \
    -H 'Content-Type: application/json' \
    -d "{\"latency_ms\": ${LATENCY}}" > /dev/null
  echo -e "${GREEN}✓${NC}"
  
  echo -e "   Мониторинг (${DURATION_PER_STAGE} сек):"
  
  START_TIME=$(date +%s)
  SAMPLE_COUNT=0
  TOTAL_LATENCY=0
  
  while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    
    if [ $ELAPSED -ge $DURATION_PER_STAGE ]; then
      break
    fi
    
    # Замеряем latency (каждую секунду)
    if [ $((ELAPSED % 2)) -eq 0 ]; then
      START_REQ=$(date +%s%N)
      curl -s -o /dev/null http://localhost:5000/api/balance || true
      END_REQ=$(date +%s%N)
      DURATION_MS=$(( (END_REQ - START_REQ) / 1000000 ))
      
      TOTAL_LATENCY=$((TOTAL_LATENCY + DURATION_MS))
      SAMPLE_COUNT=$((SAMPLE_COUNT + 1))
      AVG_LATENCY=$((TOTAL_LATENCY / SAMPLE_COUNT))
      
      # Определяем цвет на основе отклонения от цели
      if [ $AVG_LATENCY -ge $((LATENCY * 120 / 100)) ]; then
        COLOR=$RED
      elif [ $AVG_LATENCY -ge $((LATENCY * 80 / 100)) ]; then
        COLOR=$YELLOW
      else
        COLOR=$GREEN
      fi
      
      echo -ne "\r   ${COLOR}●${NC} Средняя задержка: ${AVG_LATENCY} мс (цель: ${LATENCY} мс) | Время: ${ELAPSED}/${DURATION_PER_STAGE} сек"
    fi
    
    sleep 1
  done
  echo ""
done

echo ""
echo -e "${BLUE}Проверка метрик...${NC}"
sleep 2
P95=$(curl -s 'http://localhost:9090/api/v1/query' --data-urlencode 'query=histogram_quantile(0.95, rate(fintech_request_latency_seconds_bucket[1m]))' | python3 -c "import sys,json; d=json.load(sys.stdin); r=d['data']['result']; print(f\"{float(r[0]['value'][1]*1000):.0f} мс\") if r else print('0 мс')" 2>/dev/null || echo "0 мс")
echo -e "   P95 Latency: ${YELLOW}${P95}${NC}"
echo ""

echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${YELLOW}РЕЗУЛЬТАТ${NC}                                              ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Плавный рост latency от 200 мс до 1000 мс"
echo -e "  Текущий P95: ${P95}"
echo ""
echo -e "  ${BLUE}📊 Что смотреть в Grafana:${NC}"
echo -e "     → Панель #2: ${YELLOW}Request Latency (P95/P99)${NC}"
echo -e "     → Плавный рост кривой"
echo ""
echo -e "  ${BLUE}🔧 Для сброса:${NC}"
echo -e "     ${YELLOW}bash scripts/reset.sh${NC}"
echo ""
