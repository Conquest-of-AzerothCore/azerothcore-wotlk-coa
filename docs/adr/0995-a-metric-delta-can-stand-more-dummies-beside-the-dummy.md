# 0995. A metric delta can stand more dummies beside the dummy

- Status: accepted
- Date: 2026-11-17
- Builds on: ADR 0582

## Context

Slayer's Mark 804068 raises the attack power of attackers against the marked target only. Witch Hunter ADR 0024 adds
that bonus to the area rows of the class, so a regression needs one area cast that strikes a marked dummy and an
unmarked one, each read on its own. A metric delta scenario holds one dummy; no option adds live dummies (`corpse`
and `extra_corpses` add creatures killed by a setup cast, `after_trigger_strike` a striker).

## Decision

A `metric_delta` option module `area_dummies` (ADR 0582 option, opt-in): a list of 1 to 9 distances adds creatures
`area1`, `area2`, ... as copies of the dummy at those distances. Setup casts must keep the dummy as their target; the
entry reads any of the dummies through `fields.target`. Entries that do not set it are unchanged. Class half:
Witch Hunter ADR 0024. Provisional number, renumbered at merge (14.4).

## Consequences

- Seeded tests in `metric_delta_options/test_area_dummies.py`: the creatures and the setup target, no creature without
  the option, refused inputs, and an alerting mutant (a marked reading on an unmarked dummy).
- No class file other than the Witch Hunter's sets the option, so the finished classes' digests do not move.
