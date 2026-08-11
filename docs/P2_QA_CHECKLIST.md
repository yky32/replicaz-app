# P2 QA checklist — Multi-identity product core

**Goal:** Switching lives changes chats, people, notes, and follow-ups with no bleed.

## Onboarding

| # | Step | Pass? |
|---|------|-------|
| O1 | Fresh install / clear app data → login | ☐ |
| O2 | Personal, Job, Freelance exist without manual setup | ☐ |
| O3 | **Personal** is active by default | ☐ |
| O4 | Home title shows active identity name | ☐ |

## Isolation

| # | Step | Pass? |
|---|------|-------|
| I1 | As Personal: add contact “Pat”, note “gym”, follow-up “call mom” | ☐ |
| I2 | Switch to Job → People / Notes / Follow-ups empty (or different) | ☐ |
| I3 | As Job: add contact “Boss”, note “standup” | ☐ |
| I4 | Switch back to Personal → only Pat / gym / mom | ☐ |
| I5 | Switch to Job → only Boss / standup | ☐ |

## Chat ownership (remote stack)

| # | Step | Pass? |
|---|------|-------|
| C1 | As Personal: New chat with Bob | ☐ |
| C2 | Switch to Job → that chat **not** in inbox | ☐ |
| C3 | As Job: New chat with Bob (separate room) | ☐ |
| C4 | Switch Personal → only Personal room; Job → only Job room | ☐ |

## Switch UX

| # | Step | Pass? |
|---|------|-------|
| S1 | Header pill opens “Switch life” sheet | ☐ |
| S2 | Tap another life → lists update without restart | ☐ |
| S3 | No flash of previous identity’s rows | ☐ |
| S4 | Empty states name the life (“No chats in Job”) | ☐ |

## Home hub

| # | Step | Pass? |
|---|------|-------|
| H1 | Counts match current identity | ☐ |
| H2 | Quick actions: Start chat / Add person / New note / Follow-up | ☐ |
| H3 | Space links navigate to correct tabs | ☐ |
| H4 | Manage identities opens identities screen | ☐ |

## Guardrails

| # | Step | Pass? |
|---|------|-------|
| G1 | Cannot delete last remaining identity | ☐ |
| G2 | Create identity switches into it | ☐ |
| G3 | Edit contact after switch does not reassign to new identity | ☐ |

## Exit criteria

- [ ] Job ↔ Personal show different contacts / notes / chats  
- [ ] New user never forced to create an identity manually  
- [ ] Switching feels instant and complete  
