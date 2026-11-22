# 0025. Slither makes ranged attacks and spells miss

- Status: accepted (contributor decision 2026-11-22); engine file `Unit.cpp`, gated on Witch Doctor ids
- Date: 2026-11-21

## Context

Slither 500947: "You cannot attack or cast spells, but chance to be hit by ranged attacks and spells is reduced by
$806295s1%" (100). 806295 carries attacker ranged and spell hit chance auras at -100, but the stock clamps still let
hits through: `MeleeSpellMissChance` caps the miss chance at 60% and `MagicSpellHitResult` keeps a 1% minimum hit
chance. The cycle 11 sweep 20261121-231523 read 45.8% of ranged strikes and 1.0% of spells landing.

## Decision

- `Unit::MagicSpellHitResult` returns a miss and `Unit::MeleeSpellMissChance` returns 100 for a ranged attack while the
  victim holds 806295. Both are gated on the Witch Doctor aura id, as the Amphibimorph check in `GetCreatureType`; the
  40 stock spells with -100 hit auras keep their clamps. `SPELL_ATTR3_ALWAYS_HIT` and `SPELL_ATTR7_NO_ATTACK_MISS`
  still hit.

## Consequences

- Regression: the class entries `500947 slither_spell_miss` and `slither_ranged_miss`, with their control arms.
- An engine-file edit: the finished-class reruns run in the final pass.
