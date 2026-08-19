# Slasher IA (v2)

## Problem with previous layout
- **4 nav tabs** + orphan Follow-ups + Home link-farm = cognitive overload
- **Life pill + LifeContextBar + subtitle** all said the same thing
- Home duplicated every destination

## Slasher mental model
> “Who am I right now?” → talk · people · work for that self only

## Tabs (3)

| Tab | Route | Job |
|-----|-------|-----|
| **Chats** | `/messages` | Talk in this life |
| **Circle** | `/contacts` | People in this life |
| **Desk** | `/desk` | Notes + Follow-ups (segmented) |

## Not in nav
| Surface | Entry |
|---------|--------|
| Manage lives | Life pill → sheet → Manage · or Chats ⋯ menu |
| Log out | Chats ⋯ menu |
| Thread | Push full-screen |

## Header rules
- **One primary action** per screen (+ menu if needed)
- **Life pill** = only always-on switch control
- Subtitle = short life context (“As Job”) — not a second switcher

## Legacy redirects
`/home`, `/notes`, `/follow-ups` → `/desk`

## Slasher product rules (direction)

Priority: **boundary > switch > follow-ups > circle > chat**

1. Cross-life send is blocked; one-tap **Use {bound life}** restores the correct self.
2. Desk surfaces **overdue** follow-ups first for the active life.
3. Circle/chats copy always names the active life — nothing mixes.
