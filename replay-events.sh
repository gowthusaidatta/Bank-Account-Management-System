#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:${SERVER_PORT:-8080}}"
PROCESSING_GROUP="${1:-current-account}"

echo "Triggering replay for processing group: ${PROCESSING_GROUP}"
curl -fsS -X POST "${BASE_URL}/api/admin/replay/${PROCESSING_GROUP}"
echo
echo "Replay request submitted successfully."
