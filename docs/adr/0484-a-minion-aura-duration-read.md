# 0484. A minion aura duration read

- Status: accepted
- Date: 2026-11-13

## Context

The mentor's approval of fix note F-ma-1 ([Necromancer ADR
0013](conformance/necromancer/0013-plague-horde-is-cast-by-the-minion-on-itself.md)) asks for Plague Horde 807765's
duration on the minion to be read against its DBC value. The harness read a player's or a pet's aura duration, not an
owned creature's.

## Decision

- The harness metric `owned_creature_aura_max_duration_ms` reads `GetMaxDuration()` of the aura `spell` on the
  caster's present owned creature of `entry` (0 when absent). It is a read only (G-39).
- `METRIC_EVIDENCE` classes it as a READBACK: it proves no duration claim (a forced roll refreshes the aura on every
  hit, so an expiry cannot be bracketed); it is the regression's condition read.

## Consequences

- Test: `OwnedCreatureAuraDurationReadbackTest` (test_coverage.py).
