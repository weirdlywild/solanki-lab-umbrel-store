FROM node:22-alpine

ENV MCP_GATEWAY_PORT=3333 \
    MCP_GATEWAY_STORAGE=/data \
    NODE_ENV=production

RUN npm install -g @fiberplane/mcp-gateway@0.7.1 --omit=dev \
    && npm cache clean --force

RUN mkdir -p /data

WORKDIR /data

EXPOSE 3333

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD wget -q --spider http://127.0.0.1:3333/ || exit 1

USER node

ENTRYPOINT ["mcp-gateway"]
CMD ["--port", "3333"]
