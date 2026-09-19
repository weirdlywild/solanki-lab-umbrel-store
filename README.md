# Solanki Lab — umbrelOS Community App Store

Community App Store for umbrelOS. Add this repo in **App Store → ⋮ → Community App Stores → Add → paste this repo URL**.

## Apps

| App | ID | Version | Notes |
|---|---|---|---|
| [Browserless](https://browserless.io) | `solanki-lab-browserless` | 2.56.7 | Official image (`ghcr.io/browserless/chromium`), digest-pinned |
| [Fiberplane MCP Gateway](https://github.com/fiberplane/mcp-gateway) | `solanki-lab-mcp-gateway` | 0.7.1 | Self-built image (`ghcr.io/weirdlywild/mcp-gateway`) — no official image exists |

## App IDs

All app IDs are prefixed with the store ID `solanki-lab` (required by umbrelOS).

## Publishing checklist

1. **Run the image workflow** — push this repo to GitHub (`weirdlywild/solanki-lab-umbrel-store`) so
   `.github/workflows/mcp-gateway-image.yml` builds and publishes
   `ghcr.io/weirdlywild/mcp-gateway:0.7.1` (linux/amd64 + linux/arm64).
2. **Update the digest** — the digest in `solanki-lab-mcp-gateway/docker-compose.yml` is from a
   local build; after the workflow publishes, replace it with the real multi-arch manifest digest:

   ```bash
   TOKEN=$(curl -s "https://ghcr.io/token?service=ghcr.io&scope=repository:weirdlywild/mcp-gateway:pull" | jq -r .token)
   curl -sI -H "Authorization: Bearer $TOKEN" \
     -H "Accept: application/vnd.oci.image.index.v1+json" \
     "https://ghcr.io/v2/weirdlywild/mcp-gateway/manifests/0.7.1" \
     | grep -i docker-content-digest
   ```

   Then update `image:` in `solanki-lab-mcp-gateway/docker-compose.yml`.
3. **Verify** — both apps pass the official linter:

   ```bash
   git clone https://github.com/getumbrel/umbrel-apps /tmp/umbrel-apps
   cd /tmp/umbrel-apps && npm i
   npm run lint:apps -- --root <this-repo> --check-images solanki-lab-browserless
   npm run lint:apps -- --root <this-repo> --check-images solanki-lab-mcp-gateway
   ```
4. **Add the store on your umbrel**: App Store → ⋮ → Community App Stores → Add → paste the repo URL.

## Gallery & icons

- Screenshots (`1.webp`, `2.webp`, 2160×1350) are committed per app and referenced
  relatively (official gallery convention). They were captured live from running
  containers.
- Icons are 256×256 SVG tiles with dark backgrounds and white brand marks,
  committed in-app and served via jsdelivr
  (`https://cdn.jsdelivr.net/gh/weirdlywild/solanki-lab-umbrel-store/<app>/icon.svg`).
  Committing assets is required for community stores (the jsdelivr icon URL serves
  from this repo); the official-store linter's `package.review_assets` warning does
  not apply to community stores.

## Notes

- **Browserless**: set `TOKEN` per-install (umbrel seed). No sub-path support — served at root via app proxy on its own port. Every environment variable from the official [Docker configuration reference](https://docs.browserless.io/enterprise/docker/config) is exposed: session limits (`CONCURRENT`, `QUEUED`, `TIMEOUT`, `MAX_RECONNECT_TIME`), security (`CORS*`, `ALLOW_GET`, `ALLOW_FILE_PROTOCOL`, `DISABLE_BLOCKLIST`), health (`HEALTH`, `MAX_CPU_PERCENT`, `MAX_MEMORY_PERCENT`, `HEARTBEAT_INTERVAL`), telemetry (`OTEL_ENABLED`), and logging (`LOG_LEVEL`, `LOG_FORMAT`, `TZ`). User data and downloads persist under `${APP_DATA_DIR}/data` and `${APP_DATA_DIR}/downloads`.
- **MCP Gateway**: `MCP_GATEWAY_TOKEN` set per-install; UI at `/ui?token=...`, API at `/api`, per-server proxy at `/s/<name>/mcp`. All documented env vars are supported: `MCP_GATEWAY_PORT`, `MCP_GATEWAY_STORAGE`, `MCP_GATEWAY_TOKEN`, `DEBUG`. Data persists under `${APP_DATA_DIR}/data`.
- Apps are packaged per the umbrel community store template (manifestVersion 1.1, app_proxy pattern). The umbrelOS 2.0 `environment:` manifest block exposes the tunables in App Settings.
