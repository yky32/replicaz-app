# Replicaz Architecture (mobile-first)

## State management

Aligned with **Depozio** and **Triftly**:

- `flutter_bloc` **Bloc only** (no Cubit, no Riverpod)
- Equatable events/states with `part` / `part of`
- `AppBootstrap` + root `MultiBlocProvider`
- StatelessWidget pages; events for all business mutations

Details: [`DESIGN_PRINCIPLES.md`](./design/DESIGN_PRINCIPLES.md)

## Domain

```
User (local session)
 └── Identity  (active identity drives all workspace + chat lists)
      ├── Contact / Note / FollowUp   (local, identityId stamped)
      └── Conversation → Message     (local ownerIdentityId OR
                                       remote room bound via
                                       room_identity_bindings)
```

## Identities (P2)

- First load runs `IdentityService.ensureOnboarded()` → Personal / Job / Freelance
- **Personal is active by default** for new users
- Feature blocs listen to `activeIdentityId` (distinct) and **clear lists on switch**
- Remote chats: messenger has no identity concept; client stores
  `StorageKeys.roomIdentityBindings` (roomId → identityId) on create
- Edits preserve original `identityId` (never reassign on switch mid-form)

## Messaging (P1)

- REST via **Dio** `ApiClient` → Nest `/msgr` (JWT in secure storage)
- Realtime via CMF WebSocket (`join-chat-room` / `chat-room-message-received`)
- Thread owns socket lifecycle (open / dispose / app-resume reconnect)
- Workspace stays local; do not route chat through `core/sync`

## Later

Cloud API, Clerk/Supabase Auth, workspace sync queue — keep workspace and message paths separate.
