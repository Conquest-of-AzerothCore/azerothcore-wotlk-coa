# 0631. A minion strike's flat part is scaled by the read armor

- Status: accepted
- Date: 2026-11-13
- Builds on: ADR 0541, ADR 0547

## Context

`minion_swing_ratio` takes `strike_flat` off every strike hit unmitigated (ADR 0547). On a Physical strike the
dummy's armor reduces the flat part with the weapon part, so the ratio reads `1 - flat (1 - A) / (W A)` low (A the
armor factor, W the mitigated swing): the 504901 spell-power arm read 1.953 for 2.0 (lesson of 311.1). Claim 73.1,
Bone Smash 505229 "Weapon Damage plus ${$505229m2+$505229ppl2}", is Physical with a flat 100 (EffectRealPointsPerLevel
0.0 in the server DBC set). The mentor (cycle 9, 21:32) allowed a zero-armor dummy or removing the flat after the run's
armor factor read, never an unmitigated flat on an armored hit. `run.py` has no creature armor field, and a fixture
aura would not reach the armor the hit uses when `LocalLevelScaling::ViewArmorFor` replaces it.

## Options

1. A zero-armor dummy: no fixture field, and an aura can be bypassed by the view armor.
2. Read `armor_reduced_damage` (`Unit::CalcArmorReducedDamage` on 1000) of the strike spell on the dummy in the run
   and scale the flat by it.

## Decision

Option 2. `strike_flat_armor: true` (it needs a `strike_flat`) reads `armor_reduced_damage` of `strike_spell` on the
dummy once, with the caster as the attacker (the minion is at the caster's level, Scale()); the model carries the
label as `treatment_flat_armor` and `compare.behaviour_hit_ratio_verdict` scales the flat by the read / 1000 in each
part before it takes it off. The kind also takes `learn` (spells learned before the raise, a Life Force gate).

## Consequences

- A model without `treatment_flat_armor` is unchanged; the 504901 entries keep their unmitigated flat (the observation
  stands, no judge change for them in this cycle).
- The probe's attacker is the caster, not the minion: an armor modifier the minion alone carries is not in the read
  (none is known for the Decaying Colossus 50115).
- Uncounted pilot 20261113-205010 (raw reads): armor_reduced_damage 913, Colossus swing 821.7 over 238 swings, Bone
  Smash 897.5 over 70 non-critical hits, (897.5 - 91.3) / 821.7 = 0.981.
- Seeded tests: kinds/test_minion_swing_ratio.py `MinionSwingRatioArmorFlatTests`. Templar has no entry with the
  field; Templar `generate --class 19` and `--stack` are byte-identical to 628582dc78.
