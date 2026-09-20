FROM golang:1.27-alpine AS builder
RUN apk add --no-cache git ca-certificates
ARG VERSION=1.8.17
RUN git clone --depth 1 --branch v${VERSION} https://github.com/luqman-v1/9router-go.git /app && \
    cd /app && \
    CGO_ENABLED=0 GOOS=linux GOARCH=$(go env GOARCH) go build -ldflags="-s -w -X '9router/proxy/internal/updater.CurrentVersion=${VERSION}'" -o /9router-go ./cmd/9router-go/

FROM alpine:3.21
RUN apk add --no-cache ca-certificates tzdata sqlite
COPY --from=builder /9router-go /usr/local/bin/9router-go
COPY scripts/init-db.sh /usr/local/bin/init-db.sh
RUN chmod +x /usr/local/bin/9router-go /usr/local/bin/init-db.sh
RUN mkdir -p /app/data

ENV PORT=20130 \
    DB_PATH=/app/data/data.sqlite \
    DATA_DIR=/app/data

EXPOSE 20130

ENTRYPOINT ["init-db.sh"]
