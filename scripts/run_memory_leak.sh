#!/usr/bin/env bash
set -euo pipefail

echo "Inject memory leak..."
curl -s -X POST http://localhost:5000/api/failures \
  -H 'Content-Type: application/json' \
  -d '{"memory_leak_mb": 5}'

echo "Generating traffic (Ctrl+C to stop)..."
while true; do
  curl -s -o /dev/null http://localhost:5000/api/balance
  sleep 0.1
done
