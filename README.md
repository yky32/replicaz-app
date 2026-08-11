# Replicaz

Flutter messenger for multi-identity lives.

**State:** `flutter_bloc` (Depozio / Triftly style)  
**Messaging:** tgt-rn pattern — Dio REST Messenger + CMF WebSocket  
Guide: [`docs/LOCAL_MESSAGING.md`](docs/LOCAL_MESSAGING.md)  
P1 QA: [`docs/P1_QA_CHECKLIST.md`](docs/P1_QA_CHECKLIST.md)  
P2 QA: [`docs/P2_QA_CHECKLIST.md`](docs/P2_QA_CHECKLIST.md)

## Local backend (2 sims)

```bash
# infra
docker compose up -d postgres zookeeper kafka kafka-ui

# CMF (sibling ../cmf)
cd ../cmf && KAFKA_BROKER=localhost:9092 PORT=8088 npm run dev

# Messenger API
cd backend && DB_HOST=localhost DB_PORT=5436 KAFKA_BROKER=localhost:9092 \
  SEED_DEMO_USERS=true PORT=9010 npm run dev

# health
./scripts/local-stack-health.sh
```

| User | Password |
|------|----------|
| `alice@replicaz.local` | `password` |
| `bob@replicaz.local` | `password` |

Then run the app on two simulators and create a chat between Alice and Bob.

## App

```bash
flutter pub get
flutter run
```

## Principles

[`docs/design/DESIGN_PRINCIPLES.md`](docs/design/DESIGN_PRINCIPLES.md)
