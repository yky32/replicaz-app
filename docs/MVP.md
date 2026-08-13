# Replicaz MVP

**Status:** Ready for PR / local demo  
**Branch target:** `feature/mvp-p0-p1` (create on commit)  
**Date:** 2026-08-13

## In scope (done)

### Auth & identities
- Login / register / logout (local JWT messenger)
- Personal / Job / Freelance identities + switcher
- Identity-scoped contacts, notes, follow-ups (local)

### Messaging
- 1:1 chat via Nest `/msgr` + Postgres
- Direct room **dedupe** (Alice/Bob share one roomId)
- Realtime via CMF WebSocket + Kafka
- Thread full-screen (no nav covering composer)
- Optimistic send + fail/retry
- Inbox multi-room live preview + 12s REST backup
- Peer display titles (not creator room.name)
- Unread badges (row + nav chat tab)
- Typing indicators
- Identity send guard (wrong life → blocked)
- Hide chat (swipe, device-local)
- Inbox search

### Tooling / docs
- `docs/architecture.md` current flow
- `scripts/e2e-chat.sh` · `scripts/local-stack-health.sh` · `scripts/run-two-sims.sh`
- P1 QA checklist partially automated

## Out of MVP (later)
- Groups, media, push notifications
- Cloud auth / multi-device identity sync
- Server-side leave membership
- Production deploy / App Store
- External IM bridges (WhatsApp/TG)

## Demo script
1. Start docker infra + CMF + Messenger (see `docs/LOCAL_MESSAGING.md`)
2. `./scripts/local-stack-health.sh` && `./scripts/e2e-chat.sh`
3. Two sims: Alice / Bob
4. New chat once each → same room → live send + typing + unread on inbox

## Verify
```bash
flutter analyze lib
flutter test
./scripts/e2e-chat.sh
```
