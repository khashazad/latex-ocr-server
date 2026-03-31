# LaTeX OCR Server

Deploy the upstream `pix2tex` API behind Caddy on plain HTTP with static bearer-token authentication.

## Files

- `docker-compose.yml` runs `pix2tex` and `caddy`
- `Caddyfile` enforces bearer-token auth and proxies to `pix2tex`
- `.env.example` documents the required IP-mode deployment variables
- `scripts/deploy.sh` pulls and starts the stack
- `scripts/smoke-test.sh` verifies auth, health, and OCR output

## Requirements

- Docker with Compose support
- A reachable server IP
- Port `80` open

## Setup

1. Copy `.env.example` to `.env`
2. Fill in:
   - `LATEX_OCR_BASE_URL` as `http://<ipv4-address>` with no path
   - `LATEX_OCR_BEARER_TOKEN`
3. Run:

```bash
./scripts/deploy.sh
```

Example `.env`:

```dotenv
LATEX_OCR_BASE_URL=http://203.0.113.10
LATEX_OCR_BEARER_TOKEN=replace-this-with-a-long-random-secret
```

## Smoke Test

Run:

```bash
./scripts/smoke-test.sh /path/to/equation.png
```

Expected results:

- unauthorized `GET /` returns `401`
- authorized `GET /` returns `200`
- authorized `POST /predict/` returns non-empty LaTeX text

## Update Flow

To refresh the deployment after config or image changes:

```bash
./scripts/deploy.sh
```

## Raycast Extension Settings

Use these values in the extension:

- `serverBaseUrl=http://<ipv4-address>`
- `apiToken=<LATEX_OCR_BEARER_TOKEN>`

Do not add `/predict/` to the base URL.

## Security Note

This setup uses plain HTTP, not HTTPS. Your bearer token and uploaded OCR data travel in plaintext, so use it only on a trusted network, over a VPN, or when you accept that transport risk.
