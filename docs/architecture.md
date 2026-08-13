# Replicaz Architecture (mobile-first)

**Status:** Reflects local P1 + P2 scaffold as of 2026-08-11  
**Stack pattern:** tgt-rn Messenger REST + CMF WebSocket (via Kafka)  
**Related:** [`LOCAL_MESSAGING.md`](./LOCAL_MESSAGING.md) · [`DESIGN_PRINCIPLES.md`](./design/DESIGN_PRINCIPLES.md) · P1/P2 QA checklists

---

## 1. System overview

```
┌──────────────────┐          ┌──────────────────┐
│  Flutter app     │          │  Flutter app     │
│  (Sim A / Alice) │          │  (Sim B / Bob)   │
└────────┬─────────┘          └────────┬─────────┘
         │ REST (Dio + JWT)            │
         │ WS join / push              │
         ▼                             ▼
    ┌────────────────────────────────────────┐
    │  Messenger API  :9010                  │
    │  NestJS  global prefix /msgr           │
    │  Auth · Users · Chat rooms / messages  │
    └───────────────┬────────────────────────┘
                    │
         ┌──────────┼──────────────┐
         ▼          ▼              ▼
   Postgres:5436  Kafka:9092    (publish events)
   users          messenger.chat-room
   chat_rooms     messenger-ws.chat-messages
   chat_room_members
   chat_messages
                    │
                    ▼ consume
              ┌─────────────┐
              │ CMF :8088   │  WebSocket hub only
              │ (no chat DB)│
              └──────▲──────┘
                     │ join-chat-room
                     │ chat-room-message-received
                     │
              Flutter ThreadBloc (per open thread)
```

| Component | Responsibility | Not responsible for |
|-----------|----------------|---------------------|
| **Flutter** | Multi-identity UX, REST write/read, WS receive, local workspace | Being source of truth for chat history |
| **Messenger** | Auth, rooms, messages, membership, JWT | Identity / multi-life product model |
| **Kafka** | Async bus Messenger → CMF | Persistence of chat |
| **CMF** | Realtime fan-out to joined WS clients | History, auth, identity |
| **Postgres** | Durable users / rooms / messages | Realtime delivery |

**Local ports**

| Port | Service |
|------|---------|
| 5436 | Postgres |
| 9092 | Kafka |
| 2181 | Zookeeper |
| 8095 | Kafka UI (optional) |
| 9010 | Messenger `/msgr` |
| 8088 | CMF HTTP `/health` + WebSocket |

Sibling repo: `../cmf` (`yky32/cmf`).

---

## 2. State management (app)

Aligned with **Depozio** / **Triftly**:

- `flutter_bloc` **Bloc only** (no Cubit, no Riverpod)
- Equatable events/states with `part` / `part of`
- `AppBootstrap` + root `MultiBlocProvider`
- StatelessWidget pages; events for business mutations

Details: [`DESIGN_PRINCIPLES.md`](./design/DESIGN_PRINCIPLES.md)

### Primary blocs

| Bloc | Scope |
|------|--------|
| `AuthBloc` | Session, login/logout, 401 → force re-login |
| `IdentitiesBloc` | Active life; onboard Personal / Job / Freelance |
| `ConversationsBloc` | Inbox list for **active identity only** |
| `ThreadBloc` | One open room: history + WS + send |
| Contacts / Notes / FollowUps | Local workspace, identity-stamped |

---

## 3. Domain model

```
User (server account — Alice / Bob)
 └── Identity (client-only lives)
      ├── Contact / Note / FollowUp     local, identityId stamped
      └── Conversation (chat room)      server membership + client binding
            └── Message                 server history + live WS
```

### Split of concerns

| Concept | Where it lives |
|---------|----------------|
| User / password / JWT | Messenger + secure storage |
| Identity (Personal / Job / Freelance) | Client `IdentityService` + local store |
| Room membership | Messenger `chat_room_members` |
| Room ↔ identity binding | Client `StorageKeys.roomIdentityBindings` (`roomId → identityId`) |
| Message body / timestamps | Messenger `chat_messages` |
| Live delivery | CMF WS after Kafka |

**Messenger has no identity concept.** Multi-life isolation is entirely client-side via bindings + filtering.

---

## 4. Navigation

```
GoRouter
├── /login, /register
├── StatefulShellRoute (liquid nav island)
│   ├── /messages                 InboxScreen
│   ├── /contacts (+ nested forms)
│   ├── /home
│   └── /notes (+ nested forms)
├── /messages/:conversationId     ThreadScreen
│       parentNavigatorKey = root   ← full-screen; nav island hidden
├── /identities …
└── /follow-ups
```

Thread is **outside** the shell so the floating `LiquidNavIsland` does not cover the composer.

---

## 5. Auth flow

```
Login / Register
  → POST /msgr/auth/login | /msgr/auth/register
  → { accessToken, user }
  → FlutterSecureStorage (JWT)
  → Dio interceptor attaches Authorization: Bearer <token>
  → HTTP 401 on protected route → AuthSessionExpired → login
```

Demo seed (`SEED_DEMO_USERS=true`):

| Email | Password |
|-------|----------|
| `alice@replicaz.local` | `password` |
| `bob@replicaz.local` | `password` |

---

## 6. Identities (P2)

- First authenticated load: `IdentityService.ensureOnboarded()` seeds **Personal / Job / Freelance**
- **Personal** is active by default
- Feature blocs listen to `activeIdentityId` (distinct) and **clear lists on switch**
- Workspace entities always stamp `identityId` at create; edits **never** reassign identity mid-form
- Cannot delete the last remaining identity

### Room binding rules (current)

1. On **create** direct chat → bind `roomId` to **active** identity.
2. On **inbox load** (`conversationsForIdentity`):
   - Fetch all server rooms for the user (`GET /chat/my-rooms`).
   - If `roomId` unbound on this device → **auto-bind** to active identity (so peer-created rooms appear).
   - If bound to another identity → hide in this life’s inbox.
3. Switching identity filters inbox/contacts/notes/follow-ups; no cross-life bleed.

---

## 7. Messaging flows (P1)

### 7.1 Create / open 1:1 chat

```
User A: New chat → pick User B
  → POST /msgr/chat/my-rooms { participantIds: [B] }
  → Messenger:
       if direct room already exists for exact pair {A,B}
         → return existing room (dedupe)
       else
         → insert chat_rooms + chat_room_members
         → Kafka publish messenger.chat-room
  → Client bind roomId → active identity
  → navigate /messages/:roomId
```

**Invariant:** both users must share the **same** `chatRoomId` for CMF join to deliver live messages.

CMF also learns room creation via Kafka (`ChatRoomConsumer`) and tracks in-memory room participants for WS.

### 7.2 Open thread

```
ThreadScreen(conversationId)
  → ThreadBloc + ThreadLoadRequested(identityId)
  → GET /msgr/chat/my-rooms/:id/messages     // history
  → CmfSocket.connect(ws://…:8088)
  → sink: { type: join-chat-room, chatRoomId }
  → on dispose / leave: socket disconnect (no leak)
  → app resume: ThreadReconnectRequested
```

### 7.3 Send message (happy path)

```
1. UI ThreadSendRequested
2. Optimistic bubble (deliveryStatus: pending)
3. POST /msgr/chat/rooms/:id/messages { content }
4. Messenger:
     - assert membership
     - insert chat_messages
     - update room lastMessagePreview / lastMessageAt
     - Kafka publish messenger-ws.chat-messages
         { chatRoomId, messageId, from: alias, content, sentTimestamp }
5. Response → bubble pending → sent
6. CMF ChatMessageConsumer:
     - broadcastToChatRoom(chatRoomId, type: chat-room-message-received, …)
     - only clients that joined that room receive the frame
7. Peer open **thread** ThreadBloc:
     - filter type + chatRoomId
     - append / de-dupe vs optimistic
8. Peer on **inbox** ConversationsBloc (`CmfMultiRoomSocket`):
     - joins all current inbox roomIds on one WS
     - on message → ConversationsPreviewUpdated (list bump, no open thread required)
9. Soft REST poll every ~12s while ConversationsBloc alive (backup)
10. Inbox preview also bumps from own thread send path
```

```
Sender ──REST──► Messenger ──Postgres
                    │
                    └──Kafka──► CMF ──WS──► Receiver thread (joined room)
                                      └──► Receiver inbox (multi-room join)
```

### 7.4 Load history (cold open / no WS)

```
GET /msgr/chat/my-rooms/:id/messages
  → ordered ASC
  → map messageContent.{content,from,sentTimestamp,messageId}
```

### 7.5 Failure / reconnect (intended P1 behaviours)

| Case | Behaviour |
|------|-----------|
| Send while API down | Bubble **failed** + tap to retry |
| CMF blip | Connection banner; reconnect / resume re-join |
| JWT expired | 401 → clear session → login |
| Leave thread | Socket closed; no background reconnect for that room |

---

## 8. Key HTTP API (Messenger)

Base: `http://127.0.0.1:9010/msgr` · Auth: JWT

| Method | Path | Notes |
|--------|------|--------|
| POST | `/auth/login` | email + password |
| POST | `/auth/register` | |
| GET | `/users` | list others (new chat picker) |
| GET | `/users/me` | |
| GET | `/chat/my-rooms` | memberships + metadata.participants |
| POST | `/chat/my-rooms` | create or **reuse** direct room |
| GET | `/chat/my-rooms/:id/messages` | history |
| POST | `/chat/rooms/:id/messages` | send |

Display title on client: prefer **other** participant `name`/`alias` from `metadata.participants` (not raw `room.name`, which is creator-centric).

---

## 9. Kafka topics

| Topic | Producer | Consumer | Purpose |
|-------|----------|----------|---------|
| `messenger.chat-room` | Messenger | CMF ChatRoomConsumer | Room created metadata |
| `messenger-ws.chat-messages` | Messenger | CMF ChatMessageConsumer | Fan-out chat payload to WS room |

CMF internal room keys use prefix `chat_room_` + id; join/broadcast resolve via `ChatRoomManager.getChatRoomKey(chatRoomId)` so clients send **bare** UUID.

---

## 10. Flutter config defaults

`AppConfig` (overridable via `--dart-define`):

| Key | Default |
|-----|---------|
| `API_HOST` | `http://127.0.0.1:9010` |
| `CMF_WS_URL` | `ws://127.0.0.1:8088` |
| `USE_REMOTE_BACKEND` | `true` |

When remote is off, conversations/messages use local store only (no CMF).

---

## 11. Known constraints / design debts (as of this doc)

1. **Identity bindings are device-local** — not synced across devices/reinstall (auto-bind on first inbox load mitigates peer-created rooms on same install).
2. **Two users must open/join the same room** for live WS; history still works via REST if one side never joined WS.
3. **No groups / media / push** yet; typing + unread are client-local (P1).
4. **No cloud auth** — local JWT seed users only.
5. **CMF client IDs are random UUIDs** — not profileId; typing peer label is best-effort.
6. **Direct-room dedupe** is server-side exact 2-member match; older duplicate rooms may still exist in DB until cleaned.
7. **Leave chat** is local hide only (not server membership delete).

### P1 product features (client)

| Feature | Behaviour |
|---------|-----------|
| Unread badge | Local read cursor per room; inbox badge; cleared on open/mark-read |
| Typing | CMF `typing-start` / `typing-stop` + thread UI |
| Identity send guard | Bound room identity must match active life to send |
| Leave/hide | Swipe inbox row → hide on device; New chat can reopen |
| Offline / error UX | Connection banner, load failure retry, disabled composer when wrong life |

---

## 12. Later (out of current flow)

- Cloud API, Clerk/Supabase Auth  
- Workspace sync queue (keep workspace path separate from chat path)  
- Unread, typing, media, groups  
- Multi-device identity binding sync  
- Production deploy / non-local hosts  

---

## 13. One-liner

> **Write path:** App → Messenger REST → Postgres + Kafka → CMF → peer WS.  
> **Read path:** App → Messenger REST (history) + CMF join (live).  
> **Multi-life:** Client identities + room bindings; server only knows users and rooms.
