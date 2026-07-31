# Replicaz — Design & Architecture Principles

Aligned with **Depozio** and **Triftly** conventions.

## State management (mandatory)

- **flutter_bloc only** — `Bloc<Event, State>`, **not Cubit**, **not Riverpod**
- **Equatable** on every event/state
- File triad with `part` / `part of`:
  - `{feature}_bloc.dart`
  - `{feature}_event.dart`
  - `{feature}_state.dart`
- UI dispatches **events only** — never call business methods on the Bloc
- Prefer **StatelessWidget**; StatefulWidget only for controllers / animations / form keys
- `BlocBuilder` + `buildWhen`, `BlocListener` + `listenWhen` for side effects
- **No SnackBar** for happy paths — silent completion + Bloc-driven UI
- No get_it / injectable / Freezed for Phase 1 (same as Depozio/Triftly live apps)

## Feature layout

```
lib/features/{feature}/
├── bloc/
│   ├── {feature}_bloc.dart
│   ├── {feature}_event.dart
│   └── {feature}_state.dart
├── data/                 # services + local persistence
└── presentation/
    ├── pages/
    └── widgets/
```

Shared infrastructure lives in `lib/core/` (bootstrap, storage, theme, widgets).

## DI

- `AppBootstrap` initializes SharedPreferences / secure storage / services
- Root `MultiBlocProvider` via `AppBlocProviders`
- Route/page-scoped Blocs via `BlocProvider(create: …)..add(Load…)`

## Product / UI

- Mobile-first messenger for multi-identity lives
- Fast identity switching is a core interaction
- Calm, modern chat surfaces — not dashboard chrome
- Brand: **Syne** · UI: **Plus Jakarta Sans**
- Shared `ScreenHeader`: small brand eyebrow + page title (28) + capped identity pill
- Soft mist canvas; real bubbles; floating composer
- **Floating liquid nav island** (Triftly pattern) — Stack overlay + glass blur, not Material `NavigationBar`
- Modal sheets via `ReplicazBottomSheet` (`useRootNavigator: true`) so they cover the nav island
- Avoid purple-gradient / cream-terracotta / newspaper clichés
- Never let display type wrap in headers (`maxLines: 1` + ellipsis)

## Messaging vs workspace

- Workspace (identities / contacts / notes / follow-ups) = local CRUD + future sync queue
- Messaging = REST Messenger + CMF WS (tgt-rn): send via API, receive via `join-chat-room` / `chat-room-message-received`
- Local stack: Postgres + Kafka + CMF + Nest `/msgr` — see `docs/LOCAL_MESSAGING.md`
- Do not mix message hot path into workspace sync

## Later (not now)

- NestJS / Postgres cloud API
- Clerk or Supabase Auth
- CMF WebSocket + Kafka realtime
