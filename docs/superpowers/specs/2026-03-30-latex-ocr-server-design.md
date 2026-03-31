# LaTeX OCR Server Design

## Summary

Build a small deployment repo for a self-hosted LaTeX OCR service that exposes the upstream `pix2tex` API behind Caddy with HTTPS and static bearer-token authentication.

The repo should be operationally small and reproducible:

- Docker Compose for service orchestration
- Caddy as the public HTTPS reverse proxy
- Upstream `pix2tex` API container as the internal OCR service
- Static bearer-token auth enforced at the proxy
- Lightweight deploy and smoke-test scripts

## Goals

- Provide a repeatable deployment path for the OCR server
- Terminate HTTPS at the edge
- Require bearer-token auth for public OCR requests
- Keep the public API compatible with the Raycast extension
- Make updates and verification simple enough for one-person operations

## Non-Goals

- Custom inference API logic in v1
- Multi-service observability stack
- Kubernetes, Terraform, or full infrastructure automation
- User/session management
- Rate limiting or audit logging in v1

## Architecture

### Components

1. Caddy
2. Upstream `pix2tex` API container
3. Docker Compose project wiring them together

### Traffic Flow

1. A client sends `POST /predict/` over HTTPS to the public domain.
2. Caddy validates `Authorization: Bearer <token>`.
3. If the token is valid, Caddy proxies the request to the internal `pix2tex` API service.
4. The API returns plain text LaTeX.
5. Caddy returns that response unchanged to the client.

### Public Contract

The externally reachable API should preserve the upstream contract:

- `GET /` for a simple health check
- `POST /predict/` with multipart file field `file`
- Response body is plain text LaTeX

The Raycast extension should only need:

- `serverBaseUrl`
- `apiToken`

## Auth Model

v1 uses a static shared bearer token enforced by Caddy.

Expected request header:

`Authorization: Bearer <token>`

Requests without a valid token should be rejected before they reach the OCR container.

## Deployment Model

### Service Layout

Compose should define:

- `pix2tex`
- `caddy`

The OCR service should not be exposed directly on a public host port. It should be reachable only through the Compose network and proxied by Caddy.

### TLS

Caddy should manage TLS automatically for the configured domain using an ACME contact email provided via environment variables.

### Persistence

Caddy data and config volumes should be persisted so certificates survive container restarts and redeploys.

## Repo Structure

The repo should contain:

- `docker-compose.yml`
- `Caddyfile`
- `.env.example`
- `README.md`
- `scripts/deploy.sh`
- `scripts/smoke-test.sh`

### File Responsibilities

- `docker-compose.yml`: defines service topology, env wiring, networks, and persistent volumes
- `Caddyfile`: defines HTTPS host, auth gate, and proxy routing
- `.env.example`: documents required deployment variables
- `README.md`: documents setup, deploy, update, and smoke-test workflow
- `scripts/deploy.sh`: performs safe deploy/update actions
- `scripts/smoke-test.sh`: checks both health and OCR behavior

## Environment Variables

The repo should define and document at least:

- `LATEX_OCR_DOMAIN`
- `LATEX_OCR_ACME_EMAIL`
- `LATEX_OCR_BEARER_TOKEN`

The deployment should fail fast if required values are missing.

## Scripts

### Deploy Script

`scripts/deploy.sh` should:

1. Verify `.env` exists
2. Verify required env vars are present
3. Pull/update images
4. Start or refresh the Compose stack
5. Print the next verification step

It should remain simple shell, without hidden state or external dependencies beyond Docker Compose.

### Smoke-Test Script

`scripts/smoke-test.sh` should:

1. Verify a target image path argument is provided
2. Verify the bearer token and domain are available
3. Call `GET /`
4. Call `POST /predict/` with the supplied image
5. Exit non-zero on failures

The output should make it obvious whether the service is reachable, authorized, and producing OCR output.

## Error Handling

The deployment should clearly distinguish:

- Misconfigured env vars
- Proxy auth rejection
- TLS/domain issues
- OCR container unavailability
- OCR request failures

The scripts and README should help the operator narrow failures quickly without deep container debugging for common cases.

## Security

For v1:

- Only Caddy is publicly exposed
- OCR service stays internal to Compose networking
- Bearer token is never hardcoded in tracked config files
- `.env.example` documents shape only, not secrets

## Testing And Verification

This repo does not need an application test suite in v1. It needs operational verification.

### Required Verification

- `docker compose up` succeeds
- Caddy serves the configured domain over HTTPS
- Unauthorized requests fail
- Authorized health check succeeds
- Authorized `/predict/` succeeds with a sample equation image

### Manual Downstream Verification

After server deployment, the Raycast extension should be tested against:

- `serverBaseUrl=https://<domain>`
- the configured bearer token

## Recommended Next Step

The next step is to write an implementation plan that scaffolds the deployment repo, writes the Compose and Caddy config, adds the env/example docs, and creates the deploy and smoke-test scripts.
