# Local Messenger + CMF (2 simulators)

tgt-rn pattern on your laptop:

```
Sim A / Sim B
   │ REST POST/GET          │ WebSocket join + push
   ▼                        ▼
Messenger :9010  ──Kafka──►  CMF :8088
   │
Postgres :5436
```

## 1) Start infra (Docker)

From `replicaz-app/` (uses images already on disk — no Hub pull required):

```bash
docker compose up -d postgres zookeeper kafka kafka-ui
```

Kafka UI: http://localhost:8095

## 2) Start CMF + Messenger (npm on host)

**CMF** (sibling repo):

```bash
cd ../cmf
npm install
KAFKA_BROKER=localhost:9092 PORT=8088 npm run dev
```

**Messenger** (this repo):

```bash
cd backend
npm install
DB_HOST=localhost DB_PORT=5436 DB_USER=replicaz DB_PASSWORD=replicaz \
  DB_NAME=replicaz_messenger KAFKA_BROKER=localhost:9092 \
  JWT_SECRET=replicaz-local-dev-secret SEED_DEMO_USERS=true \
  PORT=9010 npm run dev
```

Check:

```bash
curl -s http://127.0.0.1:8088/health
curl -s http://127.0.0.1:9010/msgr/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"alice@replicaz.local","password":"password"}'
```

### Optional: run apps in Docker too

Needs `node:20-alpine` from Docker Hub:

```bash
docker compose --profile apps up -d --build
```

## Demo users (seeded)

| Email | Password |
|-------|----------|
| `alice@replicaz.local` | `password` |
| `bob@replicaz.local` | `password` |

## Two iOS simulators

1. Boot two sims
2. Run Replicaz on both:

```bash
flutter run -d <SIMULATOR_A_ID>
flutter run -d <SIMULATOR_B_ID>
```

3. Sim A → login **Alice**  
4. Sim B → login **Bob**  
5. Either side: **New chat** → pick the other user → open room → send

Flutter defaults (`AppConfig`):

- `API_HOST=http://127.0.0.1:9010`
- `CMF_WS_URL=ws://127.0.0.1:8088`
- `USE_REMOTE_BACKEND=true`

## Stop

```bash
docker compose down
# stop the two npm terminals (Ctrl+C)
```
