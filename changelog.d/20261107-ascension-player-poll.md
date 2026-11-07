## Ascension player polls

- Add native poll list/submission handlers with bounded parsing and asynchronous account-level persistence.
- Add draft, choice, publish, close, list and results administrator commands with quoted creation fields.
- Enforce eligibility, stable choice ownership, comment limits, immutable published content and vote-change policy.
- Refresh poll state on login, world-entry requests, publication, closure, expiry and submission.
- Use recovered native client defaults for opaque metadata; normal creation/publication needs no wire setup.
- Add characters/world migrations without changing the client addon. Maintainer reports local in-game success; automated regression coverage remains pending.
