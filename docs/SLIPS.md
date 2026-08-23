# Slips (receipts) — slasher desk

Per-**life** document capture for slashers who constantly keep paper trails.

## Types
| Kind | Use |
|------|-----|
| **手寫單** handwritten | Photo / manual — no QR required |
| **POS 單** | QR scan (common fiscal/URL QR) + optional photo |
| **收貨單** delivery | QR / DN code + photo of goods slip |

## Entry
Desk → **Slips** segment → Scan (header QR) → `/desk/slips/scan`

## Isolation
`Receipt.identityId` scoped like notes/FU. Other lives never list these rows.

## Storage
- Metadata: `LocalStore` key `receipts`
- Photos: app documents `receipts/*.jpg`
- Demo fixtures: `assets/fixtures/demo/receipts.json`

## Out of scope (v1)
- Cloud OCR / expense export / accounting
- Cross-life shared vault

## P0 polish
- Camera denied → fallback copy + Photo/Library/Manual still work
- Remembers last slip kind (default handwritten if none)
- Delete slip deletes local image file
- List thumbnails use cacheWidth
- Settings reset demo force-reloads receipts
