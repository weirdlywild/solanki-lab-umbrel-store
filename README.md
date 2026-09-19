# Solanki Lab — umbrelOS Community App Store

Community App Store for umbrelOS. Add this repo in **App Store → ⋮ → Community App Stores → Add → paste this repo URL**.

## Apps

| App | ID | Version | Notes |
|---|---|---|---|
| [Browserless](https://browserless.io) | `solanki-lab-browserless` | 2.56.7 | Official image (`ghcr.io/browserless/chromium`), digest-pinned |
| [Fiberplane MCP Gateway](https://github.com/fiberplane/mcp-gateway) | `solanki-lab-mcp-gateway` | 0.7.1 | Self-built image (`ghcr.io/solanki-lab/mcp-gateway`) — no official image exists |

## App IDs

All app IDs are prefixed with the store ID `solanki-lab` (required by umbrelOS).

## Publishing checklist

1. **Run the image workflow** — push this repo to GitHub (`solanki-lab/solanki-lab-umbrel-store`) so
   `.github/workflows/mcp-gateway-image.yml` builds and publishes
   `ghcr.io/solanki-lab/mcp-gateway:0.7.1` (linux/amd64 + linux/arm64).
2. **Update the digest** — the digest in `solanki-lab-mcp-gateway/docker-compose.yml` is from a
   local build; after the workflow publishes, replace it with the real multi-arch manifest digest:

   ```bash
   TOKEN=$(curl -s "https://ghcr.io/token?service=ghcr.io&scope=repository:solanki-lab/mcp-gateway:pull" | jq -r .token)
   curl -sI -H "Authorization: Bearer $TOKEN" \
     -H "Accept: application/vnd.oci.image.index.v1+json" \
     "https://ghcr.io/v2/solanki-lab/mcp-gateway/manifests/0.7.1" \
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

- Screenshots (`1.png`, `2.png`) are committed per app and referenced relatively (community-store
  convention). They were captured from the live containers.
- Icons are hosted URLs (official brand assets): Browserless `https://browserless.io/favicon.svg`,
  MCP Gateway Fiberplane icon.

## Notes

- **Browserless**: set `TOKEN` per-install (umbrel seed). No sub-path support — served at root via app proxy on its own port.
- **MCP Gateway**: `MCP_GATEWAY_TOKEN` set per-install; UI at `/ui?token=...`, API at `/api`, per-server proxy at `/s/<name>/mcp`.
- Data persists under `${APP_DATA_DIR}/data`.
- Apps are packaged per the umbrel community store template (manifestVersion 1.1, app_proxy pattern).
