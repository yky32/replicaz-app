# Soft launch checklist — Replicaz (slasher preview)

## Product scope (v0 / TF)

**In**
- 3-tab IA: Chats · Circle · Desk
- Multi-life isolation + wrong-life lock + one-tap switch
- Offline demo + JSON fixtures (relative dates)
- Needs you (Desk + Chats mini)
- Circle suggestions from chats
- Follow-up from thread + contactName
- Focus life (local, long-press pill)
- First-run tip sheet (once)

**Out (ok for soft launch)**
- Production backend / real multi-device sync
- Push notifications
- Public App Store marketing
- Bridges (WA/TG)

## Tester path
1. Install latest TestFlight build  
2. **Enter multi-life demo** (re-seeds fixtures if version bumped)  
3. Read first-run tip  
4. Switch lives · open wrong-life chat · Use {life}  
5. Desk Needs you · Circle Add from chat · Thread Follow-up  
6. Long-press Life pill → Focus  

## Engineering
- `flutter analyze` clean (info only ok)
- `flutter test` green
- Bundle `com.replicaz` · export compliance false
- Demo path must not require API

## Verdict rule
Soft-launch ready when a stranger can complete the tester path in **5 minutes** without asking “where do I go?”
