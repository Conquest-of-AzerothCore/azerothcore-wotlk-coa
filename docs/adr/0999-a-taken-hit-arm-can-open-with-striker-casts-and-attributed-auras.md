# 0999. A taken hit arm can open with striker casts and attributed auras

- Status: accepted
- Date: 2026-11-17
- Builds on: ADR 0153, ADR 0125

## Context

Vampire Hunter 803638 (Witch Hunter ADR 0023) reduces the magic damage its holder takes once an enemy applies a curse,
by 5 points and 2 s more for every curse active. Its parts were read only from the 704570 aura amount and duration, data
evidence. A damage-taken read needs an enemy's curse, the fixture curses of two other casters and a magic hit in one
arm, against a control arm. No kind did it: every `taken_hit` arm cast (`opening_casts`, `casts`, `after_casts`) is the
caster's and its `auras` carry no caster; a `metric_delta` `strike` and `after_trigger_strike` refuse each other and
judge a delta, not a ratio. Mentor D-458 approved the opt-in fields (design D1, category A).

## Decision

`taken_hit` arms take two opt-in fields and one optional aura element; the judges are unchanged and still read the
strike spell only:

- `striker_casts`: spells the striker casts once at the struck unit at the arm's start, after the arm's auras, 300 ms
  apart; they are removed from the struck unit at the arm's end. An entry that sets them gives the striker
  `spell_hit_bonus` 100. They need a creature striker, a damage or absorb judge and spells other than the strike.
- `opening_settle_ms`: the wait after the opening or striker casts, default 1500 ms (the former constant).
- An arm aura `[spell, stacks, caster]` names its caster fixture (only the dummy); it is set and removed with that
  caster, and the dummy joins the creatures.

Provisional number, renumbered at merge (guide 14.4).

## Consequences

- Seeded tests in `test_behaviours.py` (`TakenHitScenarioTests`): striker cast order, settle and removal, the hit bonus,
  attributed auras, a plain striker without the fields, refused shapes, and a mutant (no reduction, ratio 1.0, and the
  neighbouring step) that alerts.
- Every existing scenario of classes 15, 19 (and `--stack`) and 23 regenerates byte-identical before the new entries.
- A fixture curse set by another caster is an enemy application for a handler that hooks aura application
  (`AscensionWitchHunterDefenses.cpp` `OnAuraApply`): a fixture curse that lapses inside an arm and is set again restarts
  the effect. The Vampire Hunter entries use a 120 s Curse of Thule 3237 for the dummy's curse; the first run, with the
  12 s Curse of Exhaustion 18223, read the reduction still active after 14 s for that reason.
