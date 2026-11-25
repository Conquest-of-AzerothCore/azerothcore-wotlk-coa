# 1228. After start reads may read an ally, and phase auras may name the striker

- Status: accepted (number provisional, assigned at merge)
- Date: 2026-11-23
- Extends: [ADR 1208](1208-metric-delta-reads-a-caster-aura-at-the-start-of-the-after-phase.md)

## Context

The Sun Cleric entries of Holy Form 805301 that read The Redeemer 301005 on two grouped allies (`extra_heal_redeemer`
and its controls) judge the aura only at the phase readings. A 301005 left on an ally from the before phase would be
consumed by the after phase's strike and read as a Redeemer heal of the after phase (mentor D-242: each ally's auras
are read at the start). `aura` is an EVENT metric (`coverage.METRIC_EVIDENCE`), so an `ally_arm` precondition arm on
it is refused, and `after_start_reads` read the caster only.

## Options

- Remove 301005 from each ally with a `set_aura` of 0 stacks: the state is forced, not read.
- A precondition arm on `aura`: refused, `aura` is not a state metric, and arms read at the phase readings, not at
  the after-phase start.
- An optional `actor` on each `after_start_reads` read.

## Decision

Each `after_start_reads` read may name an `actor`, a unit of the entry's scenario (the caster or an ally of its
`ally_arm`). The read is `aura_stacks` of the spell on that actor, at the same point as the caster reads, and its
label gains ` <actor>`. A read without `actor` keeps its caster read, label and model. A mismatch or a missing read
stays `unmeasured`; nothing becomes `ok` or `alert`. Python only, opt-in, default off.

## Consequences

- Tests: `AfterStartActorReadsTests` (metric_delta_options/test_after_start_reads.py), with a mutant that reads the
  caster in place of the ally.
- Only entries that set `actor` change; finished-class scenario digests are unchanged.

## Second decision: phase auras on the striker

### Context

Heaven's Appraisal 300353 says the Gavels "can no longer be parried". At the dummy no control Gavel was ever parried:
the dummy is summoned at x + 3 with the player's orientation (CoAGameplayTest.cpp:3496-3499) and, passive, never turns
(Unit::SetInFront is called from Creature::SelectVictim, Unit.cpp:12884), so the caster, which faces the dummy to
cast, stands behind it and Unit::MeleeSpellHitResult clears canParry (Unit.cpp:3826-3840). An aggressive striker turns
to the caster once engaged, but `phase_auras` named only the caster and the dummy, so no parry fixture could be set on
it.

### Options

- Keep the dummy and move the caster: relocation keeps the orientation (CoAGameplayTest.cpp:7858-7862), and two units
  of one orientation can never both stand in front of each other.
- A new option module that sets auras on the striker: a second list beside `phase_auras` for one unit.
- `striker` as a unit of `phase_auras`, `after_auras` and `before_auras`, accepted only when the entry has a `strike`.

### Decision

`phase_auras`, `after_auras` and `before_auras` may name `striker` as the holder or the aura's caster when the entry
has a `strike`; without one the builder raises `ValueError`. Mentor D-257. No existing entry names it.

### Consequences

- Tests: `PhaseAuraStrikerTests` (test_behaviours.py), with a mutant that drops the striker unit.
- Finished-class scenario digests are unchanged.
