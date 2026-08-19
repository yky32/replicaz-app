# Replicaz design system (lite)

Inspired by **Uber Base** ideas: tokens first, few high-frequency components,
strong status, predictable motion — adapted for multi-life (not mobility).

## Tokens

| File | Role |
|------|------|
| `lib/app/theme/app_colors.dart` | Palette + life colors |
| `lib/app/theme/app_spacing.dart` | 4/8 grid + nav island metrics |
| `lib/app/theme/app_type.dart` | Display / title / label / body / caption |
| `lib/app/theme/app_motion.dart` | fast/base/slow + `LifeSwitchScope` |

## Components

| Widget | Use |
|--------|-----|
| `LifeListCell` + `LifeMetaBadge` | Chats, people (and similar rows) |
| `LifeContextBar` | “YOU ARE IN …” under headers |
| `StatusBanner` | Wrong-life, connection, soft tips |
| `SearchField` | List search |
| `EmptyState` | Ready + empty (not loading) |
| Skeleton pack | Cold open only |
| `LifeSwitchScope` | Crossfade body when identity changes |

## Rules

1. **Status = active life** — always visible (pill + context bar + tint).
2. Loading empty → skeleton; ready empty → EmptyState.
3. One primary CTA per screen.
4. Motion: `AppMotion.*` only — no magic durations in widgets.
5. Type: prefer `AppType.*` over one-off GoogleFonts in features.
