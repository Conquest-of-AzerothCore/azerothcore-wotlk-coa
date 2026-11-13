# 0162. Armor of Faith takes its coefficients from the Templar table alone

- Status: accepted (mentor approval, 2026-11-11)
- Date: 2026-11-11

## Context

Armor of Faith 804930: "Whenever the absorption shield from Staffguard breaks, inflict
${$801546m1+$801546ppl1+$AP*0.2+$sph*0.5} High Threat Holy damage to nearby enemies." The script-cast hit check of
ADR 0160 read a mean 801546 hit of 232.86 and 233.41 (92 hits each, counted pair 20261111-214318 / -214450) against
the tooltip model 190.44 [185.73, 195.14]. The attack power and spell power terms are added twice:
`TemplarCoefficients` (src/server/coa/AscensionTemplarData.h, `{ 801546, 0, 0.2, 0.5, ... }`) adds them to the effect
value in `ModifySpellEffectBaseValue` (AscensionTemplarContracts.cpp), and `spell_bonus_data` row 801546 (direct 0.5,
ap 0.2, rev_20260913_02_templar_passives.sql) adds them again in `Unit::SpellDamageBonusDone`. The other table-driven
Templar hits carry a zero bonus row ("Templar: explicit coefficient or actual result", rev_20260909_04), which also
keeps `SpellDamageBonusDone` from falling back to the Spell.dbc `BonusMultiplier`.

## Considered options

1. Drop 801546 from `TemplarCoefficients`. Rejected: the table is the single source for every other Templar hit.
2. Delete the bonus row and leave none. Rejected: without a row, `SpellDamageBonusDone` uses the Spell.dbc
   `BonusMultiplier` as the spell power coefficient.
3. Replace the row with the zero row of its siblings, as rev_20260909_04 does. Chosen.

## Decision

`data/sql/updates/pending_db_world/rev_20261111_40_templar_armor_of_faith_single_coefficient.sql` deletes the row
of 801546 and inserts the zero row.

## Consequences

- The 801546 hit reads its tooltip model; the 804930 value read (801546 e0, 268-271, which reads the hook value
  only) does not move.
- `TemplarCoefficients` spells that still carry a non-zero bonus row: Lightkeeper's burst 561277 (ap 0.22,
  rev_20260918_23). It is measured by its own script-hit entry and is not changed here.
- Regression: `804930 script_hit 801546` and `804930 effect_value 801546e0 #0`.
