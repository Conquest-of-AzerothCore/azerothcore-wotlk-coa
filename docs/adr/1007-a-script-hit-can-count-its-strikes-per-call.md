# 1007. A script hit can count its strikes per call

- Status: draft
- Date: 2026-11-17
- Builds on: none

## Context

Houndmaster's Call 802273 states "dealing two strikes for X Shadow damage". The `script_hit` entry judged the mean of
the non-critical 706332 strikes of the Shadowhound 50124 and needed 2 hits over 6 calls, so a server casting one strike
per call would pass (review-a I-2). The raw counts behind "12 and 10 usable hits" in the earlier pair were not kept.
Mentor D-475 approved an opt-in judging addition.

## Decision

- `script_hit` takes `strikes_per_cast` (a positive integer; it needs a minion `caster_entry`, casts and no
  `strike_spell`). Each treatment trial reads `owned_creature_spell_cast_count` of the hit spell by that creature before
  its last cast and after its settle, and one end read counts the hit spell's damage events of any outcome (landed).
- `compare.judge_hit` passes the verdict of the unchanged judge (`judged_hit`) through `strikes_verdict` only when the
  model holds `strikes`: it alerts unless every call's cast difference equals `strikes_per_cast`, is unmeasured when a
  read is missing, and appends per run the casts per call, casts, landed, usable, critical and not-landed strikes.

Number assigned at integration; status draft until merged.

## Consequences

- Entries without the field build the same scenarios and get the same verdict object (seeded test with the judge
  replaced); the finished-class digests do not move.
- Seeded tests in `test_behaviours.py` `ShadowhoundStrikesPerCallTests`: read placement, two strikes per call ok, the
  mutant with one strike per call, a missing and an extra strike alert, a missing read is unmeasured.
- The cast counter is per creature: a call whose creature is replaced between its two reads would read a wrong
  difference and alert rather than pass.
