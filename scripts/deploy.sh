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

if [[ ! "$LATEX_OCR_BASE_URL" =~ ^http://([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
  echo "LATEX_OCR_BASE_URL must be http://<server-ip> with no path, query, or fragment." >&2
  exit 1
fi

docker compose --env-file .env pull
docker compose --env-file .env up -d

echo "Deployment finished."
echo "Next step: ./scripts/smoke-test.sh /path/to/equation.png"
