# DB lock simulation for queue effect
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
echo -e "${CYAN}║${NC}  ${YELLOW}КЕЙС 4: MEMORY LEAK (утечка памяти)${NC}                 ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Параметры
LEAK_MB=10
REQUESTS=50
echo -e "${BLUE}ПАРАМЕТРЫ:${NC}"
echo -e "  • Утечка на запрос: ${YELLOW}${LEAK_MB} MB${NC}"
echo -e "  • Количество запросов: ${YELLOW}${REQUESTS}${NC}"
echo -e "  • Ожидаемый рост: ${YELLOW}~$((LEAK_MB * REQUESTS)) MB${NC} (но ограничен 256 MB лимитом)"
echo ""

# 1. Замер ДО
echo -ne "${BLUE}[1/5]${NC} Замер памяти ДО... "
MEMORY_BEFORE=$(docker stats --no-stream workshop_devops_chaos_testing-app-1 --format '{{.MemUsage}}' | awk -F'/' '{gsub(/ /,"",$1); print $1}')
PROCESS_BEFORE=$(curl -s 'http://localhost:9090/api/v1/query' --data-urlencode 'query=process_resident_memory_bytes{job="app"}' | python3 -c "import sys,json; d=json.load(sys.stdin); r=d['data']['result']; print(f\"{float(r[0]['value'][1])/1024/1024:.1f} MB\") if r else print('N/A')" 2>/dev/null || echo "N/A")
echo -e "${GREEN}✓${NC}"
echo -e "   Docker stats:     ${MEMORY_BEFORE}"
echo -e "   Process RSS:      ${PROCESS_BEFORE}"
echo ""

# 2. Инъекция
echo -ne "${BLUE}[2/5]${NC} Инъекция memory leak (${LEAK_MB} MB/запрос)... "
curl -s -X POST http://localhost:5000/api/failures \
  -H 'Content-Type: application/json' \
  -d "{\"memory_leak_mb\": ${LEAK_MB}}" > /dev/null
echo -e "${GREEN}✓${NC} Выполнено"
echo ""

# 3. Генерация трафика
echo -e "${BLUE}[3/5]${NC} Генерация трафика (${REQUESTS} запросов)...${NC}"
echo ""

for i in $(seq 1 $REQUESTS); do
  curl -s -o /dev/null -w "" http://localhost:5000/api/balance || true
  
  # Прогресс
  if [ $((i % 10)) -eq 0 ]; then
    CURRENT_MEM=$(docker stats --no-stream workshop_devops_chaos_testing-app-1 --format '{{.MemUsage}}' | awk -F'/' '{gsub(/ /,"",$1); print $1}')
    echo -e "   ${PURPLE}●${NC} Запросов: ${i}/${REQUESTS} | Память: ${CURRENT_MEM}"
  fi
done

echo -e "   ${GREEN}✓${NC} ${REQUESTS} запросов завершено"
echo ""

# 4. Замер ПОСЛЕ
echo -ne "${BLUE}[4/5]${NC} Замер памяти ПОСЛЕ... "
sleep 3
MEMORY_AFTER=$(docker stats --no-stream workshop_devops_chaos_testing-app-1 --format '{{.MemUsage}}' | awk -F'/' '{gsub(/ /,"",$1); print $1}')
PROCESS_AFTER=$(curl -s 'http://localhost:9090/api/v1/query' --data-urlencode 'query=process_resident_memory_bytes{job="app"}' | python3 -c "import sys,json; d=json.load(sys.stdin); r=d['data']['result']; print(f\"{float(r[0]['value'][1])/1024/1024:.1f} MB\") if r else print('N/A')" 2>/dev/null || echo "N/A")
echo -e "${GREEN}✓${NC}"
echo -e "   Docker stats:     ${MEMORY_AFTER}"
echo -e "   Process RSS:      ${PROCESS_AFTER}"
echo ""

# 5. Расчёт
echo -ne "${BLUE}[5/5]${NC} Анализ... "
if [[ "$PROCESS_BEFORE" != "N/A" && "$PROCESS_AFTER" != "N/A" ]]; then
  BEFORE_NUM=$(echo "$PROCESS_BEFORE" | sed 's/ MB//')
  AFTER_NUM=$(echo "$PROCESS_AFTER" | sed 's/ MB//')
  DIFF=$(echo "$AFTER_NUM - $BEFORE_NUM" | bc)
  echo -e "${GREEN}✓${NC} Рост: ${YELLOW}${DIFF} MB${NC}"
else
  echo -e "${YELLOW}⚠${NC} Не удалось вычислить разницу"
fi
echo ""

# Итог
echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${YELLOW}РЕЗУЛЬТАТ${NC}                                              ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BLUE}Docker stats:${NC}  ${MEMORY_BEFORE} → ${MEMORY_AFTER}"
echo -e "  ${BLUE}Process RSS:${NC}   ${PROCESS_BEFORE} → ${PROCESS_AFTER}"
echo ""
echo -e "  ${RED}⚠ ВАЖНО:${NC} Docker stats может не показывать рост!"
echo -e "          Используйте Process RSS из Prometheus"
echo ""
echo -e "  ${BLUE}📊 Что смотреть в Grafana:${NC}"
echo -e "     → Панель #7: ${YELLOW}Container Memory Usage${NC}"
echo -e "     → Алерт: ${YELLOW}MemoryPressure Alert${NC} (панель #13)"
echo ""
echo -e "  ${BLUE}🔧 Для сброса:${NC}"
echo -e "     ${YELLOW}bash scripts/reset.sh${NC}"
echo ""
