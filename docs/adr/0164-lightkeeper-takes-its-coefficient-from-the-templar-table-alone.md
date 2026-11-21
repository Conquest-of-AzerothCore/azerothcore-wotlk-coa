# 0164. Lightkeeper's burst takes its coefficient from the Templar table alone

- Status: accepted (mentor approval, 2026-11-11)
- Date: 2026-11-11
- Follows: ADR 0162 (the same double count on Armor of Faith 801546)

## Context

Lightkeeper 560835: "Periodic damage dealt by Condemn also has a $h% chance to burst, dealing
${$561277m1*$<scalingbp>+$AP*.22} Holy damage to up to $561277i1 enemies within $561277a1 yds of the target."
The tooltip states the attack power term once. At the scenario's stats (attack power 313, Holy spell power 0, read in
both runs) the formula gives 167.60 (m1 = 100 times the scaling base, 98.74, plus 0.22 x 313 = 68.86). The
script-cast hit model of ADR 0160 floors it to 167, applies the class tuning 887007 (-20%) to 133 and the Holy
partial-resist steps of a level 60 target (0, 10, 20, 30% at 0.20, 0.45, 0.30, 0.05): 117.40. The counted pair
20261111-220111 / -220320 read 163.26 and 165.05 (43 hits each), against 117.40 [113.25, 121.55]. With the term
twice, 236.46 floors to 236, tunes to 188 and resists to 166.0, as measured.

The term is added twice: `TemplarCoefficients` (`{ 561277, 0, 0.22, ... }`, src/server/coa/AscensionTemplarData.h)
adds it to the effect value in `ModifySpellEffectBaseValue`, and `spell_bonus_data` row 561277 (ap 0.22,
data/sql/updates/pending_db_world/rev_20260918_23_templar_lightkeeper_coefficient.sql) adds it again in
`Unit::SpellDamageBonusDone`. The other table-driven Templar hits carry the zero row.

## Decision

`data/sql/updates/pending_db_world/rev_20261111_41_templar_lightkeeper_single_coefficient.sql` deletes the row of
561277 and inserts the zero row ("Templar: explicit coefficient or actual result"), as ADR 0162 does for 801546. A
missing row would let `SpellDamageBonusDone` use the Spell.dbc `BonusMultiplier`; the zero row keeps it at 0.

## Consequences

- The burst reads its tooltip model, about 117 at these stats (`560835 script_hit 561277`).
- The parked hand-written scenario `apps/coa-gameplay-test/scenarios/templar-lightkeeper.json` (level 80,
  `spell_damage_done(561277) >= 850` against a fixed base of 1000) had its threshold set while the double count was
  in place: the bonus row's attack power term is what lifts the calculation above 850. It is not changed here; it
  reads a calculation, not a hit, and is parked with the level-80 scenarios.
- TemplarCoefficients spells without any bonus row, 527270 and 801465, take no second term by code reading: 527270
  is `SPELL_DAMAGE_CLASS_NONE` and its value goes to 527269, which has the zero row; 801465 and its triggered
  801501 are magic with Spell.dbc `BonusMultiplier` 0, and `SpellDamageBonusDone` adds attack power only from a
  bonus row.
