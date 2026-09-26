FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    ANONYMIZED_TELEMETRY=false

# `uv`/`uvx` are needed at RUNTIME, not only at build time. The workaround in
# the CMD below covers the startup path (mcp-proxy spawns `browser-use --mcp`
# directly), but re-browser-use's navigation path shells out to a bare `uvx`.
# Without it every navigation fails with
#   FileNotFoundError: [Errno 2] No such file or directory: 'uvx'
# and the session is stranded on about:blank with no tabs, while the MCP call
# itself still returns 202. python:3.11-slim ships no uv, so copy the official
# static binaries in. /bin is on root's PATH, which is what this image runs as,
# and unlike an ENV PATH it survives the `bash -lc` login shell in the CMD.
COPY --from=ghcr.io/astral-sh/uv:0.12.19 /uv /uvx /bin/

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgbm1 \
    libglib2.0-0 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    xvfb \
    && rm -rf /var/lib/apt/lists/*

# re-browser-use = browser-use patched to defeat Cloudflare via NopeCHA.
# It exposes the same stdio MCP entrypoint as upstream browser-use.
# mcp-proxy bridges that stdio server to a network (SSE) endpoint.
# NOTE: the fork imports pydantic-settings but does not declare it — install
# it explicitly or the CLI crashes at import time (verified on this machine).
# mcp-proxy imports `request_ctx` from `mcp.server.lowlevel.server`, which only
# exists in mcp 1.x — pin `mcp<2` (still satisfies re-browser-use's mcp>=1.10.1).
# The `[cli]` extra is required for the `--mcp` flag to work (otherwise it errors
# with "CLI addon is not installed").
RUN pip install --no-cache-dir "mcp<2" "re-browser-use[cli]" mcp-proxy pydantic-settings

# Install the Chromium browser browser-use drives (headless Linux). The fork
# pulls the `cdp-use` driver but still needs a Chromium binary; playwright is
# the standard way to fetch it. The `uvx` that the upstream docs suggest is now
# present (see the COPY above), so the plain playwright path is used.
RUN pip install --no-cache-dir playwright \
    && playwright install chromium --with-deps \
    || playwright install chromium

# The MCP server is exposed over SSE at http://<host>:8766/sse by mcp-proxy,
# which spawns the re-browser-use stdio MCP server as a subprocess.
EXPOSE 8766

ENV BROWSER_USE_HEADLESS=true

# --pass-environment is required so the spawned stdio server finds the Python
# interpreter. Call the pip-installed `browser-use` binary directly (not uvx) so
# the pydantic-settings fix in the build step is honored. The runtime still
# needs uvx on PATH for navigation, which the COPY near the top provides.
CMD ["bash", "-lc", "exec mcp-proxy --host=0.0.0.0 --port=8766 --pass-environment -- browser-use --mcp"]
