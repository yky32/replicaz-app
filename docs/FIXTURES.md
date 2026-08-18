# Fixture / mock data

Offline **JSON fixtures** power the multi-life demo UI. No Nest/Dio required.

## Files

```
assets/fixtures/demo/
  meta.json
  identities.json
  contacts.json
  notes.json
  follow_ups.json
  conversations.json
  messages.json
  room_identity_bindings.json
  room_read_cursors.json
```

Edit any JSON → bump `meta.json` → `version` → next **Enter multi-life demo** re-seeds.

## How it loads

1. Login → **Enter multi-life demo**
2. `AuthService.enterDemoOffline()` → `DemoSeed.ensureFromFixtures(force: true)`
3. JSON → `LocalStore` (SharedPreferences)
4. `IdentitiesLoadRequested` refreshes blocs
5. `AppConfig.demoOfflineSession = true` → messaging stays **local** (not Dio)

## Switch back to real Dio API

| Step | |
|------|--|
| 1 | Deploy backend; set `API_HOST` / `CMF_WS_URL` |
| 2 | Build with `USE_REMOTE_BACKEND=true` (default) |
| 3 | User signs in with **email** (not demo) |
| 4 | Demo flag off → `MessagingService` uses `RemoteMessagingApi` (Dio) |
| 5 | Fixtures stay in repo for UI dogfood; unused in live path |

Optional compile flag later: `USE_FIXTURE_DATA` — not required; demo session is the switch.

## Force refresh fixtures on device

Logout → Enter multi-life demo again (`forceReseed: true` by default).  
Or bump `version` in `meta.json`.
