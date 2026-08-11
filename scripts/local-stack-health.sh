#!/usr/bin/env bash
# P1: health-check local Messenger + CMF stack for two-sim chat.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
API_HOST="${API_HOST:-http://127.0.0.1:9010}"
CMF_HOST="${CMF_HOST:-http://127.0.0.1:8088}"
KAFKA_UI="${KAFKA_UI:-http://127.0.0.1:8095}"
DB_PORT="${DB_PORT:-5436}"

ok() { printf '  ✓ %s\n' "$*"; }
bad() { printf '  ✗ %s\n' "$*"; FAILED=1; }
FAILED=0

echo "== Replicaz local stack health =="
echo "root: $ROOT"
echo

echo "[1/5] Docker infra"
if command -v docker >/dev/null 2>&1; then
  for c in replicaz-postgres replicaz-kafka replicaz-zookeeper; do
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "$c"; then
      ok "$c running"
    else
      bad "$c not running — docker compose up -d postgres zookeeper kafka kafka-ui"
    fi
  done
else
  bad "docker not installed"
fi

echo
echo "[2/5] Postgres :$DB_PORT"
if (echo >/dev/tcp/127.0.0.1/"$DB_PORT") >/dev/null 2>&1; then
  ok "port $DB_PORT open"
else
  bad "nothing listening on $DB_PORT"
fi

echo
echo "[3/5] CMF $CMF_HOST"
if curl -sf --max-time 3 "$CMF_HOST/health" >/dev/null 2>&1 || \
   curl -sf --max-time 3 "$CMF_HOST/" >/dev/null 2>&1; then
  ok "CMF reachable"
else
  # CMF may only expose WS; try TCP
  if (echo >/dev/tcp/127.0.0.1/8088) >/dev/null 2>&1; then
    ok "CMF port 8088 open (no /health)"
  else
    bad "CMF not up — cd ../cmf && KAFKA_BROKER=localhost:9092 PORT=8088 npm run dev"
  fi
fi

echo
echo "[4/5] Messenger $API_HOST"
LOGIN_PAYLOAD='{"email":"alice@replicaz.local","password":"password"}'
LOGIN_RES="$(curl -sS --max-time 5 \
  -H 'Content-Type: application/json' \
  -d "$LOGIN_PAYLOAD" \
  "$API_HOST/msgr/auth/login" 2>/dev/null || true)"

if echo "$LOGIN_RES" | grep -q 'accessToken'; then
  ok "login alice@replicaz.local"
  TOKEN="$(echo "$LOGIN_RES" | python3 -c 'import sys,json; print(json.load(sys.stdin)["data"]["accessToken"])' 2>/dev/null || true)"
  if [[ -n "${TOKEN:-}" ]]; then
    ME="$(curl -sS --max-time 5 -H "Authorization: Bearer $TOKEN" "$API_HOST/msgr/users/me" 2>/dev/null || true)"
    if echo "$ME" | grep -q 'alice@replicaz.local\|Alice\|alice'; then
      ok "JWT accepted on /msgr/users/me"
    else
      bad "JWT me check failed: $ME"
    fi
    ROOMS="$(curl -sS --max-time 5 -H "Authorization: Bearer $TOKEN" "$API_HOST/msgr/chat/my-rooms" 2>/dev/null || true)"
    if echo "$ROOMS" | grep -q '"data"'; then
      ok "GET /msgr/chat/my-rooms ok"
    else
      bad "rooms failed: $ROOMS"
    fi
  fi
else
  bad "login failed — is messenger on :9010 with SEED_DEMO_USERS=true?"
  bad "response: ${LOGIN_RES:-<empty>}"
fi

echo
echo "[5/5] Kafka UI (optional) $KAFKA_UI"
if curl -sf --max-time 3 "$KAFKA_UI" >/dev/null 2>&1; then
  ok "Kafka UI up"
else
  printf '  · Kafka UI not required (skipped)\n'
fi

echo
if [[ "$FAILED" -eq 0 ]]; then
  echo "All required checks passed. Run two sims and chat Alice ↔ Bob."
  exit 0
fi
echo "Some checks failed. See docs/LOCAL_MESSAGING.md"
exit 1
