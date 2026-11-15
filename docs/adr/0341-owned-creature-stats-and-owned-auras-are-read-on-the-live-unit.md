# 0341. Owned creature stats and owned auras are read on the live unit

- Status: accepted
- Date: 2026-11-12

## Context

Minion stat claims (Army of the Dead's Ghoul haste and crit chance, Depravity's minion haste, Death and Ice's crit
chance) need the live minion's values (G-21 point 2). The harness read a pet's attack time (`pet_attack_time_ms`,
`GetPet()` only) and no owned creature's crit chance. Death and Ice's fix note (F-b1-2) rested on code reading:
the Necromancer recalculation looks a summons-only aura up with `GetAura` on the caster.

## Decision

- Read-only harness metrics (G-39: reading and recording only):
  - `owned_creature_attack_time_ms` (`entry`): the minion's `UNIT_FIELD_BASEATTACKTIME`, the interval its swing timer
    is reset to (`Unit::ApplyAttackTimePercentMod`, `Unit.cpp:14894-14911`);
  - `owned_creature_crit_chance` (`entry`, `target`): `Unit::GetUnitCriticalChance(BASE_ATTACK, victim)`;
  - `owned_aura` (`spell`): `Unit::GetOwnedAura(spell) != nullptr` on the actor.
- `coverage.METRIC_EVIDENCE`: the two creature reads are `state` with the haste and crit words in `STATE_PROMISES`,
  so a learned contrast is behaviour (ADR 0258 terms); `owned_aura` is a readback.
- `metric_delta` takes a `learn` list (Life Force capacity passives), learned with the trigger spell.

## Consequences

- Counted pairs: Depravity haste 2000 to 1904.76 ms, Army of the Dead 2000 to 1818.18 ms and 5 to 15% with one
  Abomination, Death and Ice 5 to 15% with a Skeletal Mage raised before the learn.
- F-b1-2 diagnostic: after learning 560012 the caster owns it (`owned_aura` 1) but holds no application
  (`aura` 0), the lookup the recalculation uses.
- Templar generation is byte-identical.
