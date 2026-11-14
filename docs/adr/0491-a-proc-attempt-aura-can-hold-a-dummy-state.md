# 0491. A proc attempt aura can hold a dummy state

- Status: accepted
- Date: 2026-11-13

## Context

Soulfreeze 572023: "All Frost damage you deal to Frozen targets now has a $h% chance to unleash Soulfreeze on
them." `Soulfreeze()` (AscensionNecromancerEvents.cpp:39-46) rolls the chance only when the target
`HasAuraState(AURA_STATE_FROZEN)`. The Frost Nova 122 fixture (ADR 0303) breaks on damage, so the target stops being
Frozen after the first hit (mentor, 04:1x: a fixture failure; use Ice Lock 22856 or a per-hit state read). Ice Lock
is a Frost-school stun (aura 12, SchoolMask 16, no AuraInterruptFlags, infinite duration), which gives
AURA_STATE_FROZEN (SpellInfo.cpp:2342-2346) and survives damage. `attempt_auras` of a `procs` entry could only set
an aura on the caster. The harness `set_aura` action already takes a `target`, so no harness change is needed.

## Decision

- An `attempt_auras` item may carry `"target": "dummy"`: its `set_aura` step then names the dummy, before every cast
  of a `cast` trigger. Any other target is refused. Items without the key are unchanged.

## Consequences

- Soulfreeze's proc entry holds Ice Lock on the dummy (a named precondition fixture; the claim is the proc, not a
  Necromancer freeze). Its trials are every Frost hit on the dummy: the Glacial Impact 707592 hits plus the
  801728 ticks, which roll the chance again.
- Templar `generate --class 19` and `--stack` are byte-identical before and after.
- Mutant: the same entry without the dummy fixture alerts (0 procs in 18666 trials, both runs).
- Tests: `test_an_attempt_aura_can_hold_a_dummy_state_before_every_cast` and
  `test_an_attempt_aura_on_another_unit_is_refused` (test_procs.py).
