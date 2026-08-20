# Fixture / mock data

Offline **JSON fixtures** power the multi-life demo UI. No Nest/Dio required.

## Files

```
assets/fixtures/demo/
  meta.json                      # version, demoUser, activeIdentityId
  identities.json
  contacts.json                  # names match chat titles (Circle hub)
  notes.json
  follow_ups.json                # dueOffsetDays + contactName
  conversations.json             # lastMessageOffsetHours + unreadCount
  messages.json                  # createdOffsetHours / serverReceivedOffsetHours
  room_identity_bindings.json
  room_read_cursors.json
```

Edit any JSON → bump `meta.json` → `version` → next **Enter multi-life demo**
(or Settings → force reset fixtures) re-seeds.

## Quality bar (v3+)

Each life (**Personal / Job / Freelance**) must have:

| Surface | Rule |
|---------|------|
| Chats | ≥1 conversation with `unreadCount` ≥ 1 |
| Desk / Needs you | ≥1 **open** follow-up with `dueOffsetDays` ≤ 2 (overdue, today, or due soon) |
| Circle | Contacts whose `name` matches related chat `title` / FU `contactName` |

Keep IDs stable (`id_personal`, `room_alex`, `fu_hike`, …) so messages stay linked.

## Relative date keys

Applied at seed in `DemoSeed._withRelativeDates` (now ± offset → ISO):

| Key | Resolves to |
|-----|-------------|
| `dueOffsetDays` | `dueAt` |
| `createdOffsetDays` / `updatedOffsetDays` | `createdAt` / `updatedAt` |
| `lastMessageOffsetHours` | `lastMessageAt` |
| `createdOffsetHours` / `updatedOffsetHours` | hour-based variants |
| `serverReceivedOffsetHours` | `serverReceivedAt` |

Prefer offsets over hard-coded ISO so Needs you and RelativeTime stay fresh months later.

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

- Logout → Enter multi-life demo again (`forceReseed: true` by default)
- Settings → force reset fixtures
- Or bump `version` in `meta.json` (current quality pack: **3**)
