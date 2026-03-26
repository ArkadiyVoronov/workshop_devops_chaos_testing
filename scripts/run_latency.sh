#!/usr/bin/env bash
set -euo pipefail

echo "Inject latency..."
curl -s -X POST http://localhost:5000/api/failures \
  -H 'Content-Type: application/json' \
  -d '{"latency_ms": 2000}'

echo "Generating traffic (Ctrl+C to stop)..."
while true; do
  curl -s -o /dev/null -w "%{http_code}\n" http://localhost:5000/health
  sleep 0.2
done
