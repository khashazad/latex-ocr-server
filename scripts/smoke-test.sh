#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 /path/to/equation.png" >&2
  exit 1
fi

if [[ ! -f .env ]]; then
  echo "Missing .env. Copy .env.example to .env first." >&2
  exit 1
fi

IMAGE_PATH="$1"
if [[ ! -f "$IMAGE_PATH" ]]; then
  echo "Image file not found: $IMAGE_PATH" >&2
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

BASE_URL="${LATEX_OCR_BASE_URL%/}"
AUTH_HEADER="Authorization: Bearer ${LATEX_OCR_BEARER_TOKEN}"

UNAUTHORIZED_STATUS="$(curl --connect-timeout 5 --max-time 15 -s -o /dev/null -w '%{http_code}' "${BASE_URL}/")"
if [[ "$UNAUTHORIZED_STATUS" != "401" ]]; then
  echo "Expected unauthorized health check to return 401, got ${UNAUTHORIZED_STATUS}." >&2
  exit 1
fi

AUTHORIZED_STATUS="$(curl --connect-timeout 5 --max-time 15 -s -o /dev/null -w '%{http_code}' -H "${AUTH_HEADER}" "${BASE_URL}/")"
if [[ "$AUTHORIZED_STATUS" != "200" ]]; then
  echo "Expected authorized health check to return 200, got ${AUTHORIZED_STATUS}." >&2
  exit 1
fi

LATEX_OUTPUT="$(curl --connect-timeout 5 --max-time 15 -fsS -H "${AUTH_HEADER}" -F "file=@${IMAGE_PATH}" "${BASE_URL}/predict/")"
if [[ -z "${LATEX_OUTPUT//[[:space:]]/}" ]]; then
  echo "OCR endpoint returned empty output." >&2
  exit 1
fi

echo "Unauthorized health check returned 401."
echo "Authorized health check returned 200."
echo "OCR output:"
printf '%s\n' "$LATEX_OUTPUT"
