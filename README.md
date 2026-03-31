# LaTeX OCR Server

Deploy the upstream `pix2tex` API behind Caddy with HTTPS and static bearer-token authentication.

## Files

- `docker-compose.yml` runs `pix2tex` and `caddy`
- `Caddyfile` terminates TLS and enforces bearer-token auth
- `.env.example` documents required deployment variables
- `scripts/deploy.sh` pulls and starts the stack
- `scripts/smoke-test.sh` verifies auth, health, and OCR output

## Requirements

- Docker with Compose support
- A public domain pointing to your server
- Ports `80` and `443` open

## Setup

1. Copy `.env.example` to `.env`
2. Fill in:
   - `LATEX_OCR_DOMAIN`
   - `LATEX_OCR_ACME_EMAIL`
   - `LATEX_OCR_BEARER_TOKEN`
3. Run:

```bash
./scripts/deploy.sh
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

- `serverBaseUrl=https://<your-domain>`
- `apiToken=<LATEX_OCR_BEARER_TOKEN>`

Do not add `/predict/` to the base URL.
