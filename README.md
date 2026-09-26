# Solanki Lab — umbrelOS Community App Store

Community App Store for umbrelOS. Add this repo in **App Store → ⋮ → Community App Stores → Add → paste this repo URL**.

> ⚠️ Apps in community stores are **not vetted by the Umbrel team**. Review the
> manifests before installing. This store pins every image by digest and is
> packaged per the official community store template.

## Apps

| App | ID | Version | Image | Notes |
|---|---|---|---|---|
| [Browser Use](https://github.com/imamousenotacat/re-browser-use) | `solanki-lab-browser-use` | 0.9.8 | `ghcr.io/weirdlywild/solanki-lab-browser-use` (self-built) | AI browser automation MCP server (re-browser-use fork) |
| [Fiberplane MCP Gateway](https://github.com/fiberplane/mcp-gateway) | `solanki-lab-mcp-gateway` | 0.7.1 | `ghcr.io/weirdlywild/mcp-gateway` (self-built) | MCP proxy, registry & traffic capture |
| [Paperclip](https://github.com/paperclipai/paperclip) | `solanki-lab-paperclip` | 2026.916.1 | `ghcr.io/paperclipai/paperclip` (upstream, digest-pinned) | Agent orchestration control plane — org chart, goals, budgets, governance |

## Getting started

1. Add the store: **App Store → ⋮ (three dots) → Community App Stores → Add** →
   paste `https://github.com/weirdlywild/solanki-lab-umbrel-store`.
2. Install **Browser Use** and **MCP Gateway** from the store (one-click install).
3. Open each app once — the install completes and both become dashboard tiles.

## Security model — read this first

This store is public. The apps are **network services that clients connect to
directly by port**, so their security posture differs from the umbrel UI:

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
  the token in the app's environment settings.

### Access control recommendations

| Setting | Value | Why |
|---|---|---|
| Tailscale | **Required** for remote access | Your umbrel (and this store) already has a Tailscale app — use `100.x.x.x:PORT` for remote clients. Do **not** expose these ports publicly (no Cloudflare Tunnel hostnames, no port forwards, no UPnP). |
| Browser Use token | Keep the per-install token | Controls access to the MCP endpoint that drives a real browser. |
| MCP Gateway token | Keep the per-install token | Strong (43-char base64url). Set your own only if you need a known value — minimum 32 chars. |

> ⚠️ **Do not create a public Cloudflare Tunnel / reverse-proxy hostname for
> these apps.** Browser Use and MCP Gateway are automation endpoints — exposing
> them publicly turns your box into a free headless-browser / proxy farm.

## Using the apps

### Browser Use

Browser Use is packaged as a self-hosted MCP server over streamable HTTP/SSE
(stdio bridged through `mcp-proxy`). Point any MCP client at the SSE endpoint:

```json
{
  "mcpServers": {
    "browser-use": {
      "type": "http",
      "url": "http://umbrel.local:8766/sse"
    }
  }
}
```

Or register it in your **MCP Gateway** as a streamable-HTTP server pointing at
`http://umbrel.local:8766/sse`, then call it from Claude Desktop / Cursor /
Copilot via the gateway.

- The **re-browser-use** fork defeats Cloudflare verification via **NopeCHA**.
- Set `OPENAI_API_KEY` or `ANTHROPIC_API_KEY` in the app settings so the agent
  can steer the browser.
- `BROWSER_USE_HEADLESS=true` runs Chromium headless (default). Set `false` to
  show a window through xvfb.

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
      "url": "http://umbrel.local:3333/s/browser-use/mcp"
    }
  }
}
```

The per-server proxy is unauthenticated by design (upstream behavior) — rely on
Tailscale reachability and/or per-server bearer headers. Remote access: replace
`umbrel.local` with your Tailscale IP (`100.x.x.x`) and enable Tailscale on the
client machine.

### Paperclip

Paperclip is an **open-source control plane for teams of AI agents**. Rather than
one chat window, you get an org chart: agents hold roles, report to a manager,
are assigned goals, and wake on schedules or events to do work. It tracks token
spend, enforces per-agent budgets with hard stops, persists sessions across
reboots, and keeps a full audit log.

- **Dashboard:** port `3100`. The UI is responsive, so the same page works from
  a phone over Tailscale. Create the first account through the bootstrap flow on
  first visit.
- **Agent runtimes:** the image ships `claude`, `codex`, `opencode`, `gemini` and
  `kimi` preinstalled, plus adapters for Hermes, OpenClaw, arbitrary shell
  commands and HTTP webhooks. Create an agent in the UI and pick an adapter.
- **9Router wiring:** `ANTHROPIC_BASE_URL` / `OPENAI_BASE_URL` already point at
  your 9Router. Set `ANTHROPIC_API_KEY` (and `OPENAI_API_KEY`) in the app
  settings to activate model routing.
- **Database:** embedded PostgreSQL (PGlite) inside the container — no separate
  database service, no external dependency. Backups are written hourly to the
  app data directory and kept for 7 days.

> ⚠️ **Agents run unattended.** The Claude Code adapter defaults to skipping
> permission prompts, so give Paperclip a dedicated workspace directory and set
> per-agent budgets. Measured idle footprint is ~1 GB RAM, so it is comfortable
> alongside the rest of this store. Keep port `3100` on your LAN or Tailscale —
> do not expose it to the internet.

## Environment variables

All variables below are configurable in **umbrelOS → App → Settings →
Environment variables** (umbrelOS 2.0 `environment:` manifest block). Compose
defaults match the upstream defaults.

### Browser Use

| Variable | Default | Description |
|---|---|---|
| `OPENAI_API_KEY` | unset | OpenAI key used by the browser agent to steer (needed if no Anthropic key). |
| `ANTHROPIC_API_KEY` | unset | Anthropic key used by the browser agent to steer (needed if no OpenAI key). |
| `BROWSER_USE_HEADLESS` | `true` | Run Chromium headless, or show a window via xvfb when `false`. |
| `ANONYMIZED_TELEMETRY` | `false` | Disable anonymized telemetry. |

> The MCP endpoint is served by `mcp-proxy` (stdio→streamable HTTP bridge),
> spawning `re-browser-use` as the stdio server. The container runs Chromium and
> installs Playwright deps.

### MCP Gateway

| Variable | Default | Description |
|---|---|---|
| `MCP_GATEWAY_PORT` | `3333` | HTTP listen port. |
| `MCP_GATEWAY_STORAGE` | `~/.mcp-gateway` | Data dir (`mcp.json` registry + SQLite capture logs); here `/data` → `${APP_DATA_DIR}/data`. |
| `MCP_GATEWAY_TOKEN` | auto-generated | Bearer token for `/api`, `/gateway/mcp`, `/ui` (min 32 chars recommended). |
| `DEBUG` | unset | Debug logging: `*` for all, `@fiberplane/*` for gateway modules. |

### Paperclip

| Variable | Default | Description |
|---|---|---|
| `PAPERCLIP_API_URL` | `http://127.0.0.1:3100` | **Agent-facing** control-plane URL. Must resolve *inside* the container. |
| `PAPERCLIP_AUTH_DISABLE_SIGN_UP` | `true` | Block new account registration. Existing accounts keep working. |
| `PAPERCLIP_DEPLOYMENT_EXPOSURE` | `private` | `private` = LAN/Tailscale only. `public` only behind TLS. |
| `ANTHROPIC_BASE_URL` | `http://192.168.1.38:20128` | 9Router Anthropic-compatible endpoint. No `/v1` — the Anthropic SDK appends the path. |
| `ANTHROPIC_API_KEY` | unset | 9Router key used by the Claude Code adapter. |
| `OPENAI_BASE_URL` | `http://192.168.1.38:20128/v1` | 9Router OpenAI-compatible endpoint. Keep `/v1` — the OpenAI SDK appends the path. |
| `OPENAI_API_KEY` | unset | 9Router key used by the Codex and OpenCode adapters. |
| `PAPERCLIP_PUBLIC_URL` | `http://solanki:3100` | The URL you actually open in the browser. Used for links and callbacks. |
| `PAPERCLIP_ALLOWED_HOSTNAMES` | `solanki,solanki.tailnet.ts.net,192.168.1.38,100.79.230.24` | Extra hostnames accepted for login, beyond the public URL host. |
| `PAPERCLIP_TELEMETRY_DISABLED` | `1` | Set to `1` to disable anonymous usage telemetry. |

> ⚠️ **`PAPERCLIP_API_URL` is not the same as `PAPERCLIP_PUBLIC_URL`.** Paperclip
> injects `PAPERCLIP_API_URL` into every agent process, so it has to resolve from
> inside the container. If it's left unset, the server derives it from
> `PAPERCLIP_PUBLIC_URL` — and a LAN hostname like `solanki` does **not** resolve
> inside the container. The symptom is nasty: agents run fine and return
> sensible replies, but every attempt to read an issue, post a comment, or
> create a sub-agent fails, so the agent reports itself blocked and no work
> actually lands. Keep it on loopback unless the agents run on another host.

> `BETTER_AUTH_SECRET` is **not** exposed here. The container generates a random
> 32-byte value on first start and persists it at `${APP_DATA_DIR}/data/auth.env`
> with mode `600`, so sessions survive restarts and updates without a secret in
> this public repo. Upstream refuses to boot without it.

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

- **Image**: Browser Use ships as a Python package (`re-browser-use`), so this
  store builds a custom container that runs its MCP server behind `mcp-proxy`.
  `.github/workflows/browser-use-image.yml` builds
  `ghcr.io/weirdlywild/solanki-lab-browser-use` (linux/amd64) and pushes it to
  GHCR. When bumping, update `Dockerfile`, the workflow `VERSION`, and the
  pinned digest in `solanki-lab-browser-use/docker-compose.yml`.
- **Paperclip** ships a public multi-arch image, so there is nothing to build.
  The compose file pins it by digest. Upstream only publishes moving channel
  tags (`latest`, `beta`, `canary`, `nightly`) plus `sha-*` tags — there are no
  semver tags — so resolve a tag to its `docker-content-digest` and update both
  the manifest `version` and the digest in `solanki-lab-paperclip/docker-compose.yml`:

  ```bash
  ghcr_token=$(curl -s "https://ghcr.io/token?scope=repository:paperclipai/paperclip:pull&service=ghcr.io" | jq -r .token)
  curl -sI -H "Authorization: Bearer $ghcr_token" \
    -H 'Accept: application/vnd.oci.image.index.v1+json' \
    https://ghcr.io/v2/paperclipai/paperclip/manifests/latest | grep -i docker-content-digest
  ```

  The `version` field tracks upstream's own build stamp, readable from the image
  config label `org.opencontainers.image.version`.
- **Lint** both apps with the official linter:

  ```bash
  git clone https://github.com/getumbrel/umbrel-apps /tmp/umbrel-apps
  cd /tmp/umbrel-apps && npm i
  npm run lint:apps -- --root <this-repo> --check-images solanki-lab-browser-use
  npm run lint:apps -- --root <this-repo> --check-images solanki-lab-mcp-gateway
  ```

- App IDs are prefixed with the store ID `solanki-lab` (required by umbrelOS).
- Manifests use `manifestVersion: 1.1` + the app_proxy pattern; umbrelOS 2.0
  installs 1.x apps via its legacy compatibility layer.

## Licensing

- **Browser Use (re-browser-use fork)**: MIT. `mcp-proxy`: MIT.
- **MCP Gateway**: MIT. Image build is trivial (see `Dockerfile`).
- **Paperclip**: MIT (upstream image is used unmodified).
- This store repo itself: MIT (see `LICENSE`).
