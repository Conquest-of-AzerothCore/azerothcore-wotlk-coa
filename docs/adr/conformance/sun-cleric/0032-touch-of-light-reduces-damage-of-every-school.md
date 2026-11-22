# 0032. Touch of Light reduces the damage of every school

- Status: accepted
- Date: 2026-11-22

## Context

Touch of Light 572885, Spell.dbc text: "Enemies struck by Blessing of Absolution now deal $572886s1% reduced damage
for $572886d." The class code casts 572886 on the enemy damaged by the Blessing of Absolution strike 804252
(`AscensionSunClericEvents.cpp`, `case 572885: Cast(player,target,572886)`). 572886 Effect[0] is aura 79
`SPELL_AURA_MOD_DAMAGE_PERCENT_DONE`, target enemy, BasePoints -21 + 1 = -20, MiscValue 1 (Physical only). The
engine readers of aura 79 (`Unit::SpellDamageBonusDone`, `Unit::MeleeDamageBonusDone`, `UpdateAllDamagePctDoneMods`)
apply it only to the schools in MiscValue.

The tooltip names no school. Owner ruling O-25: the debuff reduces ALL damage the enemy deals by 20%, not Physical
only. Measured before the fix (pair 20261122-164341 / 20261122-164658, build 6cd75cfa82e6): an enemy's Physical Void
Zone 92559 read a treatment / control ratio of 0.80041 in both runs, its Light of the Naaru 41394 read 1.0
(1100 against 1100 per hit) in both runs.

## Options

- Widen 572886 Effect[0] MiscValue to 127 (`SPELL_SCHOOL_MASK_ALL`) in the class contract
  `AscensionSunCleric::ApplyContracts`, keyed to the id.
- Add a damage hook in the class code that scales the enemy's non-Physical damage while it carries 572886: a second
  reader of the same aura beside the engine's.
- A `spell_dbc` SQL override of 572886: it replaces the whole record for a one-field change.

## Decision

The first option (owner ruling O-25). The amount, duration, target and the client text stay as they are; only the
school mask of the effect changes.

## Consequences

- An enemy carrying 572886 deals 20% less damage of every school for its 5 s, Physical unchanged at 20%.
- 572886 is referenced only by 572885 Effect[0] TriggerSpell in Spell.dbc and by `AscensionSunClericEvents.cpp` in
  the code; no SQL, no other class file and no other class's code reads it. The contract function returns for any
  spell outside family 33, and no engine file changes.
- Regression: the 572885 class-file entries `struck_damage` (Physical Void Zone, expected 0.8) and
  `struck_damage_magic` (Light of the Naaru, expected 0.8), each with a control arm that unlearns 572885.
