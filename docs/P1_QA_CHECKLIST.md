# P1 QA checklist — Messaging foundation

**Goal:** Alice ↔ Bob chat is boringly reliable on the local stack (Dio REST + CMF WS).

## Pre-flight

```bash
# From replicaz-app/
docker compose up -d postgres zookeeper kafka kafka-ui

# Terminal A — CMF
cd ../cmf && KAFKA_BROKER=localhost:9092 PORT=8088 npm run dev

# Terminal B — Messenger
cd backend && DB_HOST=localhost DB_PORT=5436 KAFKA_BROKER=localhost:9092 \
  SEED_DEMO_USERS=true PORT=9010 npm run dev

# Health
./scripts/local-stack-health.sh
```

| Check | Pass? |
|-------|-------|
| Health script all green | ☐ |
| App builds / runs on sim | ☐ |

## Auth (Dio + secure token)

| # | Step | Pass? |
|---|------|-------|
| A1 | Cold start → login screen (no stale session without JWT) | ☐ |
| A2 | Login `alice@replicaz.local` / `password` → inbox | ☐ |
| A3 | Kill app, relaunch → still logged in (token persisted) | ☐ |
| A4 | Logout → login screen; protected API would 401 | ☐ |
| A5 | Wrong password → error on form (not crash) | ☐ |

## Two-sim chat

| # | Step | Pass? |
|---|------|-------|
| M1 | Sim A = Alice, Sim B = Bob | ☐ |
| M2 | Alice: New chat → Bob → room opens | ☐ |
| M3 | Alice sends “hello” → Bob sees it **without** restart | ☐ |
| M4 | Bob replies → Alice sees it live | ☐ |
| M5 | Leave thread → inbox shows last message preview + time | ☐ |
| M6 | Pull-to-refresh inbox updates list | ☐ |

## Thread lifecycle / CMF

| # | Step | Pass? |
|---|------|-------|
| T1 | Open thread → connection banner brief or none when CMF up | ☐ |
| T2 | Background app 10s → resume → still receives new messages | ☐ |
| T3 | Stop CMF → banner shows reconnecting/offline | ☐ |
| T4 | Start CMF → tap retry (if failed) → messages flow again | ☐ |
| T5 | Pop thread → socket closed (no crash / no leak in logs) | ☐ |

## Send failures

| # | Step | Pass? |
|---|------|-------|
| S1 | Stop messenger API, send message → bubble failed + “Tap to retry” | ☐ |
| S2 | Start messenger, retry → message sends | ☐ |
| S3 | Happy path: no SnackBar on success | ☐ |

## Exit criteria (P1)

- [ ] Alice ↔ Bob message appears on both devices without restart  
- [ ] Reconnect after CMF blip recovers  
- [ ] JWT survives app restart; 401 forces re-login  

## Not in P1

Groups, media, typing, unread badges, production auth, workspace sync.
