#!/bin/sh
set -e

DB_PATH="${DB_PATH:-/app/data/data.sqlite}"
DATA_DIR="$(dirname "$DB_PATH")"
mkdir -p "$DATA_DIR"
chmod 700 "$DATA_DIR"

if [ ! -s "$DB_PATH" ]; then
  sqlite3 "$DB_PATH" <<'SQL'
CREATE TABLE IF NOT EXISTS apiKeys (
  id TEXT PRIMARY KEY,
  key TEXT UNIQUE NOT NULL,
  name TEXT,
  machineId TEXT,
  isActive INTEGER DEFAULT 1,
  createdAt TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS providerConnections (
  id TEXT PRIMARY KEY,
  provider TEXT NOT NULL,
  authType TEXT NOT NULL,
  name TEXT,
  email TEXT,
  priority INTEGER,
  isActive INTEGER DEFAULT 1,
  data TEXT NOT NULL,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS kv (
  scope TEXT NOT NULL,
  key TEXT NOT NULL,
  value TEXT NOT NULL,
  PRIMARY KEY (scope, key)
);
CREATE TABLE IF NOT EXISTS combos (
  id TEXT PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  kind TEXT,
  models TEXT NOT NULL,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS settings (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  data TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS providerNodes (
  id TEXT PRIMARY KEY,
  type TEXT,
  name TEXT,
  data TEXT NOT NULL,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS usageHistory (
  timestamp TEXT, provider TEXT, model TEXT, connectionId TEXT,
  apiKey TEXT, endpoint TEXT, promptTokens INTEGER, completionTokens INTEGER,
  cost REAL, status TEXT, tokens TEXT, meta TEXT
);
CREATE TABLE IF NOT EXISTS usageDaily (
  dateKey TEXT PRIMARY KEY, data TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS requestDetails (
  id TEXT PRIMARY KEY, timestamp TEXT, provider TEXT, model TEXT,
  connectionId TEXT, status TEXT, data TEXT
);
SQL
  chmod 600 "$DB_PATH"
fi

NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
# Seed the per-install API key (deterministic per umbrel install).
API_KEY="${ROUTER_API_KEY:-sk-9router-local}"
if ! sqlite3 "$DB_PATH" "SELECT 1 FROM apiKeys WHERE key = '$API_KEY' LIMIT 1;" | grep -q 1; then
  ID="$(cat /proc/sys/kernel/random/uuid)"
  sqlite3 "$DB_PATH" "INSERT INTO apiKeys (id, key, name, machineId, isActive, createdAt) VALUES ('$ID', '$API_KEY', 'umbrel-install', NULL, 1, '$NOW');"
fi

exec /usr/local/bin/9router-go
