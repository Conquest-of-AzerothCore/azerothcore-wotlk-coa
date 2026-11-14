# 0537. A resurrection reads the ally's health and mana after the accept

- Status: accepted
- Date: 2026-11-13

## Context

Call of The Scourge 803605: "Bring a dead ally back to life with $s1 health and $q1 mana." The `cast_combat` resurrect
entry proved the revival (dead before, alive after a real cast in combat and CMSG_RESURRECT_RESPONSE) but read only
`alive`, so the health and mana claims (378.1, 379.0) stayed a named tool gap.

## Decision

- `cast_combat` takes `resurrect_amounts` (with `resurrect`): after the accept it reads the ally's `health` and its
  mana (`power` 0), judged exactly against the resurrection effect's EffectBasePoints + EffectDieSides and
  EffectMiscValue (SPELL_EFFECT_RESURRECT_NEW 113: absolute health and mana). The ally's regeneration is off for that
  scenario (`allow_regeneration: false`), so no tick moves the reads.

## Consequences

- 803605 revive reads 583 health and 833 mana. The label `803605 effect_value #1` (unreadable `$q1`) is removed from
  the mana claim, not reclassified.
- Tests: `ResurrectAmountTests` (test_behaviours.py), with a wrong amount that must alert. Templar `generate` unchanged
  (no Templar entry sets the field).
