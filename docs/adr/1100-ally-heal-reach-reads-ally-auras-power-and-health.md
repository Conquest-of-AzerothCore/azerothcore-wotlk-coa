# 1100. Ally heal reach reads ally auras, the caster's power and the health of the party

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 1021 (ally heal reach), ADR 0582 (fixture auras)

## Context

Six Witch Doctor claims act on several ally players and are not heals, or need a count the four judges of
`ally_heal_reach` do not make (cycle 11 group a): Hexbreak's extra ally (300660), Mass Allcure's radius and immunity
(705906), Spirit Link Idol's shared health (706369), the Mojo Beam duration and its growing mana cost (501117), and a
Bottle in the Beam channel that reaches more allies (301175), whose control phase heals the primary target too.

## Decision

New opt-in fields of `kinds/ally_heal_reach.py`; an entry without them generates as before.

- Fixtures: an ally's `auras` and the entry's `caster_auras` (`[spell, stacks]`, set with `set_aura` at each phase
  start); `caster_health` (`[health, maximum]`, regeneration off); `gate_settle_ms` (a wait after the gate learn).
- Cast fields: `power_reads` (the caster's power right before the cast and at the end of its watch), `gap_ms` (a wait
  after the cast), `probes` (ms after the cast, whole polls inside the watch, at which every fixture aura is set again
  with a refusable `set_aura` and the judged auras are read).
- Judges: `count` (the reference ally's heals of `spell` in the treatment window equal `expected`; a control window
  reads 0), `aura_reach` (at each phase end the `reference` has lost `aura`, `removed` units lost it only in the
  treatment, `kept` units keep it), `immune_window` (the `immune` units refuse the aura at the `early_ms` probe and take
  it at `late_ms` in the treatment, and take it at `early_ms` in the control), `drain` (the power spent by
  `high_cast` exceeds that of `low_cast`; evidence metric `power`, contrast `own_cast`) and `health_share` (the
  `levelled` units end within `tolerance` health points of each other from a spread of at least ten tolerances, the
  `apart` units do not move). `reach` gains `control_allowed`: allies whose control heals are allowed, for a gated
  claim about the allies beyond a target the control also heals.
- Harness: `set_aura` takes `refusable` (`CoAGameplayTest.cpp`, `run.py`): when `Unit::AddAura` returns no aura (an
  immune recipient, `Unit.cpp:16768`) the step records `applied: false` instead of failing the scenario.

## Consequences

- Class 13 gains nine scenarios; classes 19 (with and without `--stack`) and 23 generate byte-identical, and no existing
  class 13 scenario changes.
- An `immune_window` reads immunity through an aura application the server refuses, the same `IsImmunedToSpell` check
  a landing spell meets; the verdict names the refusable fixture.
