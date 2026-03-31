# LaTeX OCR Server IP Proxy Design

## Goal

Replace the domain-based HTTPS deployment design with a simpler IP-based deployment that still requires a bearer token. The service should be reachable at `http://<server-ip>` without requiring a DNS name or ACME email address.

## Architecture

The deployment will keep two services in Docker Compose:

- `pix2tex` as the internal OCR API on port `8502`
- `caddy` as a small public reverse proxy on port `80`

Caddy will no longer terminate TLS or depend on a hostname. Instead it will listen on plain HTTP, require `Authorization: Bearer <token>`, and forward authorized requests to the internal `pix2tex` container.

The public contract remains:

- `GET /` for health
- `POST /predict/` with multipart field `file`

This keeps the Raycast extension contract stable except for the base URL changing from `https://<domain>` to `http://<server-ip>`.

## Configuration

The env contract should be reduced to the minimum required values:

- `LATEX_OCR_BEARER_TOKEN`
- `LATEX_OCR_BASE_URL`

`LATEX_OCR_BEARER_TOKEN` is the shared secret checked by Caddy and configured in Raycast.

`LATEX_OCR_BASE_URL` is the public base URL used by the smoke test, for example `http://203.0.113.10`. It should not include `/predict/`.

The previous variables must be removed from the repo contract:

- `LATEX_OCR_DOMAIN`
- `LATEX_OCR_ACME_EMAIL`

## Repo Shape

The repo should keep the same basic operator surface:

- `docker-compose.yml`
- `Caddyfile`
- `.env.example`
- `README.md`
- `scripts/deploy.sh`
- `scripts/smoke-test.sh`

The changes are behavioral, not structural. Existing files should be updated rather than replaced with a new stack.

## Data Flow

The request flow is:

1. Raycast sends `POST http://<server-ip>/predict/`
2. Caddy checks `Authorization: Bearer <token>`
3. Authorized requests are proxied to `pix2tex:8502`
4. `pix2tex` returns plain text LaTeX
5. Raycast copies the returned LaTeX

Unauthorized requests should return `401`.

## Deployment Model

Deployment remains Docker Compose driven. The deploy script should validate only the token and base URL env values, then pull and start the stack.

The server no longer depends on:

- public DNS
- ACME registration
- HTTPS certificate issuance

It does still require:

- Docker with Compose support
- inbound access to port `80`
- a firewall policy appropriate for an HTTP service on a public IP

## Testing And Verification

The smoke-test script should use `LATEX_OCR_BASE_URL` from `.env` and verify:

- unauthenticated `GET /` returns `401`
- authenticated `GET /` returns `200`
- authenticated `POST /predict/` returns non-empty LaTeX

All existing curl calls should retain explicit connect and total timeouts.

Compose validation should confirm:

- only the token and base URL env vars are required
- Caddy publishes only port `80`
- the internal `pix2tex` healthcheck remains intact
- Caddy still waits for `pix2tex` health before starting

## Security Tradeoff

This design intentionally drops HTTPS to avoid requiring a domain. That is acceptable only if the user accepts plaintext HTTP traffic between Raycast and the server. The bearer token remains useful for access control, but it is not a substitute for transport encryption.

Recommended usage is:

- trusted network
- VPN/private network
- personal server with acceptable risk tolerance

If stronger transport security is needed later, the design should move back to a hostname-based HTTPS deployment.

## User-Facing Configuration

Raycast should be configured with:

- `serverBaseUrl=http://<server-ip>`
- `apiToken=<LATEX_OCR_BEARER_TOKEN>`

The user must not append `/predict/` to the base URL.

## Out Of Scope

This redesign does not add:

- HTTPS without a domain
- custom auth application code
- rate limiting
- IP allowlists
- VPN automation

Those can be added later if needed.
