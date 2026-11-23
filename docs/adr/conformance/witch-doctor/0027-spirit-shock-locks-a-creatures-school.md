# 0027. Spirit Shock locks a creature's school

- Status: accepted
- Date: 2026-11-21

## Context

Spirit Shock 807743 interrupts non-player spellcasting for $807772d. The class cast the interrupt 807772 from the hit
result, after the Shock's own silence had already stopped the creature's cast, and `Spell::EffectInterruptCast` only
acts on a running cast, so the 4 s school lockout never applied (sweep 20261121-235946, `807743 lockout`: read 0).

## Decision

- The interrupt is cast from `OnSpellCalculatedTarget`, at the Shock's launch, for a non-player target the Shock
  hits (`missCondition == SPELL_MISS_NONE`), so a missed Shock interrupts nothing.

## Consequences

- Regression: `807743 behaviour_expiry lockout`.
