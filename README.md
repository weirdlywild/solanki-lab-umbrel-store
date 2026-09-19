# Solanki Lab — umbrelOS Community App Store

Community App Store for umbrelOS. Add this repo in **App Store → ⋮ → Community App Stores → Add → paste this repo URL**.

> ⚠️ Apps in community stores are **not vetted by the Umbrel team**. Review the
> manifests before installing. This store pins every image by digest and is
> packaged per the official community store template.

## Apps

| App | ID | Version | Image | Notes |
|---|---|---|---|---|
| [Browserless](https://browserless.io) | `solanki-lab-browserless` | 2.56.7 | `ghcr.io/browserless/chromium` (official, digest-pinned) | Headless Chrome API server |
| [Fiberplane MCP Gateway](https://github.com/fiberplane/mcp-gateway) | `solanki-lab-mcp-gateway` | 0.7.1 | `ghcr.io/weirdlywild/mcp-gateway` (self-built) | MCP proxy, registry & traffic capture |

## Getting started

1. Add the store: **App Store → ⋮ (three dots) → Community App Stores → Add** →
   paste `https://github.com/weirdlywild/solanki-lab-umbrel-store`.
2. Install **Browserless** and **MCP Gateway** from the store (one-click install).
3. Open each app once — the install completes and both become dashboard tiles.

## Security model — read this first

This store is public. The two apps are **network services that clients connect
to directly by port**, so their security posture differs from the umbrel UI:

- The **web UIs** (`/docs`, `/ui`) sit behind umbrel's login wall (app proxy).
- **MCP clients connect directly** to `umbrel.local:PORT`, which **bypasses the
  umbrel login**. The per-app token is the only protection on those ports.

### Token handling

- Each install gets a **unique, deterministic per-install token**
  (`deterministicPassword: true` in the manifest → the token is derived from
  your umbrel's seed, not stored in this repo).
- The token is **displayed in the app's info/settings in umbrelOS** after
  install. It is stable across restarts and updates — put it in your clients
  once and keep it.
- Never publish your token. If you suspect it leaked, rotate it by changing
  `TOKEN` / `MCP_GATEWAY_TOKEN` in the app's environment settings.

### Access control recommendations

| Setting | Value | Why |
|---|---|---|
| Tailscale | **Required** for remote access | Your umbrel (and this store) already has a Tailscale app — use `100.x.x.x:PORT` for remote clients. Do **not** expose these ports publicly (no Cloudflare Tunnel hostnames, no port forwards, no UPnP). |
| `TOKEN` / `MCP_GATEWAY_TOKEN` | Keep the per-install token | Strong (43-char base64url). Set your own only if you need a known value — minimum 32 chars. |
| `CORS` | `false` (default) | Block cross-origin browser calls. |
| `ALLOW_GET` | `false` (default) | Disable unauthenticated GET scraping of `/json`, `/content`, `/pdf`. |
| `ALLOW_FILE_PROTOCOL` | `false` (default) | Block `file://` reads inside sessions. |
| `DISABLE_BLOCKLIST` | `false` (default) | Keep the URL blocklist (localhost, private IPs, cloud metadata endpoints). |
| `HEALTH` | `true` (optional) | Reject requests while the browser is unhealthy. |

> ⚠️ **Do not create a public Cloudflare Tunnel / reverse-proxy hostname for
> these apps.** Browserless and MCP Gateway are automation endpoints — exposing
> them publicly turns your box into a free headless-browser / proxy farm.

## Using the apps

### Browserless

The token authenticates every connection. Examples:

```js
// Puppeteer (standard puppeteer-core, no fork)
const browser = await puppeteer.connect({
  browserWSEndpoint: 'ws://umbrel.local:3000?token=YOUR_TOKEN',
});

// Playwright
const browser = await pw.chromium.connectOverCDP('ws://umbrel.local:3000?token=YOUR_TOKEN');
```

- API docs & playground: `http://umbrel.local:3000/docs` (through the umbrel UI tile)
- Health: `http://umbrel.local:3000/pressure` (requires the token)
- REST endpoints (`/content`, `/pdf`, `/screenshot`, `/function`, …) accept the
  token via the `X-Browserless-Token` header or `?token=` query param.
- No sub-path support: the app is served at the root path on its own port.

### MCP Gateway

| Endpoint | Use | Auth |
|---|---|---|
| `http://umbrel.local:3333/ui?token=YOUR_TOKEN` | Web UI — register/manage MCP servers | token |
| `http://umbrel.local:3333/api/*` | REST API | Bearer token |
| `http://umbrel.local:3333/gateway/mcp` | Management MCP server (add/remove/list via tools) | Bearer token |
| `http://umbrel.local:3333/s/<server-name>/mcp` | Per-server MCP proxy — **this is what your clients connect to** | passes through your server's own auth |

Point Claude Desktop, Cursor, OpenClaw or any MCP client at the gateway:

```json
{
  "mcpServers": {
    "browser": {
      "type": "http",
      "url": "http://umbrel.local:3333/s/browserless/mcp"
    }
  }
}
```

The per-server proxy is unauthenticated by design (upstream behavior) — rely on
Tailscale reachability and/or per-server bearer headers. Remote access: replace
`umbrel.local` with your Tailscale IP (`100.x.x.x`) and enable Tailscale on the
client machine.

## Environment variables

All variables below are configurable in **umbrelOS → App → Settings →
Environment variables** (umbrelOS 2.0 `environment:` manifest block). Compose
defaults match the upstream defaults.

### Browserless

| Variable | Default | Description |
|---|---|---|
| `TOKEN` | per-install | API token for all client requests. Set for any deployment reachable beyond localhost. |
| `HOST` | `0.0.0.0` | Bind address. |
| `PORT` | `3000` | Internal listen port. |
| `CONCURRENT` | `10` | Max concurrent browser sessions (requests queue beyond this). |
| `QUEUED` | `10` | Max queued requests before HTTP 429. |
| `TIMEOUT` | `30000` | Session timeout in ms (`-1` = none). |
| `MAX_RECONNECT_TIME` | unset | Max reconnection timeout (ms) after disconnect; unset = Infinity. |
| `CORS` | `false` | Enable CORS headers on all routes. |
| `CORS_ALLOW_ORIGIN` | `*` | Allowed origins when CORS is enabled. |
| `CORS_ALLOW_METHODS` | unset | Allowed methods when CORS is enabled (unset = all). |
| `CORS_MAX_AGE` | `2592000` | CORS preflight cache age (s). |
| `ALLOW_GET` | `false` | Allow GET for `/json`, `/content`, `/pdf`. |
| `ALLOW_FILE_PROTOCOL` | `false` | Allow `file://` inside sessions (security risk). |
| `HEALTH` | `false` | Pre-request health checks on `/pressure`. |
| `MAX_CPU_PERCENT` | `99` | CPU load % cap for health checks. |
| `MAX_MEMORY_PERCENT` | `99` | Memory load % cap for health checks. |
| `HEARTBEAT_INTERVAL` | `30000` | WS heartbeat interval (ms); lower behind load balancers with idle timeouts. |
| `DISABLE_BLOCKLIST` | `false` | Disable the localhost/private-IP/cloud-metadata URL blocklist. |
| `OTEL_ENABLED` | `false` | OpenTelemetry instrumentation. |
| `LOG_LEVEL` | `trace` | `trace`/`debug`/`info`/`warn`/`error`/`fatal`/`silent` (default here: `warn`). |
| `LOG_FORMAT` | `plain` | `plain` or `json`. |
| `TZ` | `UTC` | IANA time zone. |
| `DATA_DIR` | OS temp | User-data dir (cookies/cache) — **not mounted** in this package (upstream default; temp space resets on restart). |
| `DOWNLOAD_DIR` | OS temp | Downloads dir — **not mounted** in this package (upstream default; temp space resets on restart). |

> `KEY` (enterprise license) is intentionally not exposed — this app uses the
> OSS image. `DEBUG` (npm debug patterns) is supported upstream but left unset.

Suggested for a 16 GB home server also running other apps: `CONCURRENT: 5`,
`TIMEOUT: 60000`.

### MCP Gateway

| Variable | Default | Description |
|---|---|---|
| `MCP_GATEWAY_PORT` | `3333` | HTTP listen port. |
| `MCP_GATEWAY_STORAGE` | `~/.mcp-gateway` | Data dir (`mcp.json` registry + SQLite capture logs); here `/data` → `${APP_DATA_DIR}/data`. |
| `MCP_GATEWAY_TOKEN` | auto-generated | Bearer token for `/api`, `/gateway/mcp`, `/ui` (min 32 chars recommended). |
| `DEBUG` | unset | Debug logging: `*` for all, `@fiberplane/*` for gateway modules. |

## Gallery & icons

- Screenshots (`1.webp`, `2.webp`, 2160×1350) are captured live from running
  containers and served via jsdelivr CDN (absolute URLs — umbrel's gallery-URL
  rewrite only applies to the official store).
- Icons are 256×256 SVG tiles (dark background + white brand mark), also served
  via jsdelivr.
- Assets are committed in-repo because community stores must serve their own
  assets; the official-store linter's `package.review_assets` warning does not
  apply to community stores.

## Development

- **Image**: the gateway ships npm-only upstream (no official Docker image).
  `.github/workflows/mcp-gateway-image.yml` builds `ghcr.io/weirdlywild/mcp-gateway`
  (linux/amd64 + linux/arm64) and pushes it to GHCR. When bumping the gateway
  version, update `Dockerfile`, the workflow `VERSION`, and the pinned digest in
  `solanki-lab-mcp-gateway/docker-compose.yml` (fetch the new manifest digest via
  the GHCR registry API).
- **Lint** both apps with the official linter:

  ```bash
  git clone https://github.com/getumbrel/umbrel-apps /tmp/umbrel-apps
  cd /tmp/umbrel-apps && npm i
  npm run lint:apps -- --root <this-repo> --check-images solanki-lab-browserless
  npm run lint:apps -- --root <this-repo> --check-images solanki-lab-mcp-gateway
  ```

- App IDs are prefixed with the store ID `solanki-lab` (required by umbrelOS).
- Manifests use `manifestVersion: 1.1` + the app_proxy pattern; umbrelOS 2.0
  installs 1.x apps via its legacy compatibility layer.

## Licensing

- **Browserless**: SSPL-1.0 OR commercial. Free for open-source/non-commercial
  use; commercial/closed-source CI use requires a paid license.
- **MCP Gateway**: MIT. Image build is trivial (see `Dockerfile`).
- This store repo itself: MIT (see `LICENSE`).
