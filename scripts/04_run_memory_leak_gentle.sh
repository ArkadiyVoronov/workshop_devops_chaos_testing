#!/usr/bin/env bash
# Gentle version - gradual memory leak
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${YELLOW}КЕЙС 4: MEMORY LEAK (плавный рост)${NC}                   ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Плавное увеличение: 2MB → 5MB → 10MB → 15MB → 20MB на запрос
STAGES_MB=(2 5 10 15 20)
REQUESTS_PER_STAGE=20
DURATION_PER_STAGE=10

echo -e "${BLUE}ПАРАМЕТРЫ:${NC}"
echo -e "  • Этапов: ${YELLOW}${#STAGES_MB[@]}${NC}"
echo -e "  • Утечка на запрос: ${YELLOW}${STAGES_MB[*]} MB${NC}"
echo -e "  • Запросов на этап: ${YELLOW}${REQUESTS_PER_STAGE}${NC}"
echo -e "  • Общая утечка: ~${YELLOW}$(( (2+5+10+15+20) * REQUESTS_PER_STAGE / 1024 )) MB${NC}"
echo ""

for i in "${!STAGES_MB[@]}"; do
  LEAK_MB=${STAGES_MB[$i]}
  STAGE_NUM=$((i + 1))
  
  echo -ne "${BLUE}[${STAGE_NUM}/${#STAGES_MB[@]}]${NC} Утечка ${LEAK_MB} MB/запрос... "
  curl -s -X POST http://localhost:5000/api/failures \
    -H 'Content-Type: application/json' \
    -d "{\"memory_leak_mb\": ${LEAK_MB}}" > /dev/null
  echo -e "${GREEN}✓${NC}"
  
  echo -e "   Генерация трафика (${REQUESTS_PER_STAGE} запросов):"
  
  for j in $(seq 1 $REQUESTS_PER_STAGE); do
    curl -s -o /dev/null http://localhost:5000/api/balance || true
    
    # Прогресс каждые 5 запросов
    if [ $((j % 5)) -eq 0 ]; then
      CURRENT_MEM=$(docker stats --no-stream workshop_devops_chaos_testing-app-1 --format '{{.MemUsage}}' | awk -F'/' '{gsub(/ /,"",$1); print $1}')
      PROCESS_MEM=$(curl -s 'http://localhost:9090/api/v1/query' --data-urlencode 'query=process_resident_memory_bytes{job="app"}' | python3 -c "import sys,json; d=json.load(sys.stdin); r=d['data']['result']; print(f\"{float(r[0]['value'][1])/1024/1024:.1f} MB\") if r else print('N/A')" 2>/dev/null || echo "N/A")
      echo -e "   ${PURPLE}●${NC} Запросов: ${j}/${REQUESTS_PER_STAGE} | Docker: ${CURRENT_MEM} | Process RSS: ${PROCESS_MEM}"
    fi
  done
  echo ""
done

echo ""
echo -e "${BLUE}Финальный замер...${NC}"
sleep 3
MEMORY_FINAL=$(docker stats --no-stream workshop_devops_chaos_testing-app-1 --format '{{.MemUsage}}' | awk -F'/' '{gsub(/ /,"",$1); print $1}')
PROCESS_FINAL=$(curl -s 'http://localhost:9090/api/v1/query' --data-urlencode 'query=process_resident_memory_bytes{job="app"}' | python3 -c "import sys,json; d=json.load(sys.stdin); r=d['data']['result']; print(f\"{float(r[0]['value'][1])/1024/1024:.1f} MB\") if r else print('N/A')" 2>/dev/null || echo "N/A")
echo -e "   Docker stats: ${MEMORY_FINAL}"
echo -e "   Process RSS:  ${PROCESS_FINAL}"
echo ""

echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${YELLOW}РЕЗУЛЬТАТ${NC}                                              ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Плавный рост памяти от 2 MB до 20 MB на запрос"
echo -e "  Docker stats: ${MEMORY_FINAL}"
echo -e "  Process RSS:  ${PROCESS_FINAL}"
echo ""
echo -e "  ${RED}⚠ ВАЖНО:${NC} Docker stats может не показывать рост!"
echo -e "          Используйте Process RSS из Prometheus"
echo ""
echo -e "  ${BLUE}📊 Что смотреть в Grafana:${NC}"
echo -e "     → Панель #7: ${YELLOW}Container Memory Usage${NC}"
echo -e "     → Панель #13: ${YELLOW}MemoryPressure Alert${NC}"
echo -e "     → Плавный рост кривой"
echo ""
echo -e "  ${BLUE}🔧 Для сброса:${NC}"
echo -e "     ${YELLOW}bash scripts/reset.sh${NC}"
echo ""
