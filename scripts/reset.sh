#!/usr/bin/env bash
set -euo pipefail

echo "Resetting failure state..."
curl -s -X POST http://localhost:5000/api/reset

echo "Done."
