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
 └── Identity
      ├── Contact / Note / FollowUp
      └── Conversation → Message
```

## Later

Cloud API, Clerk/Supabase Auth, CMF realtime — keep workspace and message paths separate.
