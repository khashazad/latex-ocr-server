#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -f .env ]]; then
  echo "Missing .env. Copy .env.example to .env first." >&2
  exit 1
fi

set -a
source .env
set +a

: "${LATEX_OCR_BASE_URL:?Missing LATEX_OCR_BASE_URL in .env}"
: "${LATEX_OCR_BEARER_TOKEN:?Missing LATEX_OCR_BEARER_TOKEN in .env}"

docker compose --env-file .env pull
docker compose --env-file .env up -d

echo "Deployment finished."
echo "Next step: ./scripts/smoke-test.sh /path/to/equation.png"
