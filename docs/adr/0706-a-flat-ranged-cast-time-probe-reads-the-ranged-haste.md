# 0706. A flat ranged cast-time probe reads the ranged haste

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15

## Context

`Unit::ModSpellCastTime` applies `SPELLMOD_CASTING_TIME` flat modifiers first and the ranged haste
(`m_modAttackSpeedPct[RANGED_ATTACK]`) after them for a DmgClass 3 spell. The generated passive `add` model expects
the flat points as the delta. Heavy Crossbows 503681 `e1 spell_cast_time_ms 681203` read +435 against +500 under the
15% Auto Shot haste on branch feat/coa-witch-hunter-c10-o21 (2173 -> 2608). Mentor decision D-158 (design D-20).

## Options

- Read the ranged attack time before and after the learn and scale the expected delta by the measured haste.
- Derive the haste from before / base cast time: wrong whenever the ranged-slot +500 ms applies.
- Mark the probe not judged: loses the check.

## Decision

The first option, for a flat (`add`) `spell_cast_time_ms` probe on a DmgClass 3 target only, when the scenario's
weapon set has a ranged weapon. The model keeps `ranged_haste` (labels, base speed, item); the judge expects
`(before / f_before + points) x f_after - before`, f the read attack time over the base speed. A missing read stays
an alert.

## Consequences

- Finished classes: the add-model cast-time labels are Templar `706449 e0 spell_cast_time_ms 578276` (DmgClass 1)
  and Necromancer `704715 e0 ... 807941` (1), `704717 e1 ... 707007` (1), `704717 e1 ... 504439` (0). None has a
  ranged target, so none is judged by the new rule, and both classes regenerate byte-identical. Their records show a
  factor of 1 all the same: each delta equals the points exactly (Templar record 2, 20261114-165640 / -163739:
  0 -> 1500; Necromancer final16, 20261114-084514 / -090752: 1500 -> 1000, 0 -> 1000, 0 -> 1000).
- Witch Hunter: `503681 e1 spell_cast_time_ms 681203` gains the two reads.
