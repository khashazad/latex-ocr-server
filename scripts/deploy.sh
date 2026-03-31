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

IPV4_BASE_URL_PATTERN='^http://((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])(:80)?$'
if [[ ! "$LATEX_OCR_BASE_URL" =~ $IPV4_BASE_URL_PATTERN ]]; then
  echo "LATEX_OCR_BASE_URL must be http://<ipv4-address> or http://<ipv4-address>:80 with no path, query, or fragment." >&2
  exit 1
fi

if [[ "$LATEX_OCR_BASE_URL" == "http://0.0.0.0" || "$LATEX_OCR_BASE_URL" == "http://0.0.0.0:80" ]]; then
  echo "LATEX_OCR_BASE_URL must be a reachable server IPv4 address, not 0.0.0.0." >&2
  exit 1
fi

docker compose --env-file .env pull
docker compose --env-file .env up -d

echo "Deployment finished."
echo "Next step: ./scripts/smoke-test.sh /path/to/equation.png"
