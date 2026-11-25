# 0010. Mind Rot increases spell hit chance for all schools

- Status: accepted (provisional number, numbered at merge; owner ruling O-12 Q-cu-1, 2026-11-24)
- Date: 2026-11-25

## Context

Mind Rot 560943 (server `Spell.dbc`, `SpellFamilyName` 31, `Description[enUS]`): "Chance to be struck by spells
increased by `$s1%`." Both Mind Rot 300300 ("Periodic or channeled damage dealt now has a `$h%` chance to curse your
target, applying Mind Rot.") and Eldritch Screams 525049 ("Your Corrupt Mind now also applies Mind Rot to nearby
enemies.") append sub-description 560714: "Increases the chance for allies to hit with all spells against the afflicted
enemy by `$560943s1%` for `$560943d`."

Server `Spell.dbc` defines 560943 Effect[0] as aura 186 `SPELL_AURA_MOD_ATTACKER_SPELL_HIT_CHANCE`, BasePoints 2 with
DieSides 1 (`$s1` = 3), DurationIndex 1 (10000 ms), Dispel 1 (Magic), and `EffectMiscValue[0]` = 0. In
`Unit::MagicSpellHitResult` (`Unit.cpp:4011`) and `Unit::GetTotalAuraModifierByMiscMask` (`Unit.cpp:7194`), aura 186
contributes only when `(aurEff->GetMiscValue() & schoolMask) != 0`. With `EffectMiscValue[0]` = 0, `0 & schoolMask` was
0 for every spell school, so 560943 granted 0% spell hit chance.

Conformance runs `20261125-002625` and `20261125-002657` (`cu-g6b`, build `aa4bb0bc3311`, `Spell.dbc` `4e4ed9ba`)
measured `spell_hit_bonus_taken` on an afflicted Kobold Vermin (entry 6) with `560943` active (`aura` = 1,
`aura_amount` = 3) at 0 on Shadow (502182), 0 on Fire (2136), and 0 on Nature (5176) against the tooltip's 3. The
`coabuildhub` snapshot renders 300300 and 525049 with the same 3% all-spells sentence; `coa-history` holds no events
for 560943.

The project owner ruled (`O-12` `Q-cu-1`, 2026-11-24): fix the server so the 3% applies across all spell schools.

## Options

- Set `Effect[0].MiscValue` of 560943 to `SPELL_SCHOOL_MASK_ALL` (127) in `AscensionCultist::ApplyContracts`.
- Edit `Spell.dbc` or add a `spell_dbc` SQL override. Rejected: shipped DBC files stay untouched and Cultist spell data
  repairs live in `AscensionCultistContracts.cpp`.

## Decision

`AscensionCultist::ApplyContracts` (`src/server/coa/AscensionCultistContracts.cpp`), keyed to spell id 560943, sets
`info->Effects[0].MiscValue = SPELL_SCHOOL_MASK_ALL`. No shared file, DBC, SQL, or client text changes.

## Consequences

- Any unit carrying Mind Rot 560943 (whether applied by Mind Rot 300300 in `AscensionCultistEvents.cpp:82,165` or by
  Eldritch Screams 525049 on Corrupt Mind 560109 in `AscensionCultistAbilities.cpp:301-304`) grants attackers +3% spell
  hit chance across all spell schools (`SPELL_SCHOOL_MASK_ALL` = 127; melee/ranged physical attacks continue to use
  `Unit::MeleeSpellHitResult` and do not read aura 186).
- Unreferenced `Spell.dbc` trigger 561313 (not in `CharacterAdvancement.dbc` or Cultist scripts) also names 560943; no
  other class lists 560943 (`class_map` `shared_with` empty).
- Existing `300300` proc-rate scenarios (`periodic` and `channeled`) were rerun (`20261125-011535` and
  `20261125-011653`, build `5ab2e4cf9275`, 10/10 passed in both runs) with no movement.
- Regressions: gameplay scenario `cultist-525049-mind-rot-hit.json` (`20261125-011318` and `20261125-011505`, build
  `5ab2e4cf9275`) reads `spell_hit_bonus_taken` = 0 before learning 525049 and without 560943, +3 across all seven
  school masks (Shadow 502182, Fire 2136, Nature 5176, Holy 585, Frost 116, Arcane 5143, Physical 500720) with 560943
  from 525049 (0 on the unafflicted caster, 0 after 560943 removal), and +3 across Shadow, Fire, and Nature when 560943
  is applied by Mind Rot 300300. Adding `spell_hit_bonus_taken` to `classes/cultist.json` awaits registering that
  metric in `coverage.METRIC_EVIDENCE` (`test_coverage.py:975`).
