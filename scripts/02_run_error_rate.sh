#!/usr/bin/env bash
set -euo pipefail

echo "Inject error rate (50%)..."
curl -s -X POST http://localhost:5000/api/failures \
  -H 'Content-Type: application/json' \
  -d '{"error_rate": 50}'

echo "Generating traffic (Ctrl+C to stop)..."
while true; do
  curl -s -o /dev/null -w "%{http_code}\n" http://localhost:5000/api/balance
  sleep 0.1
done
