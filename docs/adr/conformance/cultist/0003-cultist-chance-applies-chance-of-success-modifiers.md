# 0003. Cultist Chance helper applies chance-of-success spell modifiers

- Status: accepted
- Date: 2026-11-25

## Context

Everpresent `300272` (server `Spell.dbc`, `Description[enUS]`): "Increases the chance to trigger Presences by $s1%."
Embodied Presences `803283` (server `Spell.dbc`, `Description[enUS]`): "Increases the chance to trigger your Presences
by $s1% and reduces their mana costs by $s2%."

In server `Spell.dbc` (`4e4ed9ba1c2e`), `Effect[0]` of both passives is aura `107` (`SPELL_AURA_ADD_FLAT_MODIFIER`) with
`EffectMiscValue = 18` (`SPELLMOD_CHANCE_OF_SUCCESS`) and `EffectSpellClassMask[0..2] = [512, 0, 64]`, adding `+10`
(`BasePoints = 9`, `DieSides = 1`) for `300272` and `+5` (`BasePoints = 4`, `DieSides = 1`) for `803283`. All four
Cultist Presences (`803035` Presence of Y'Shaarj, `803037` Presence of N'Zoth, `803082` Presence of Yogg-Saron, and
`803339` Presence of C'Thun) belong to `SpellFamilyName = 31` with `SpellFamilyFlags[2] = 64` and state "giving damage
dealt a $h% chance" (`ProcChance = 20` on `803035`, `803037`, `803339`; `30` on `803082`).

Pending world SQL `rev_20261003_10_coa_script_rolled_proc_chance.sql` sets `spell_proc.Chance = 100` on script-rolled
Cultist event auras, including all four Presences, so `Aura::CalcProcChance` applies `SPELLMOD_CHANCE_OF_SUCCESS` to
`100.0f` and leaves `aura_ascension_cultist_event::Check` (`src/server/coa/AscensionCultistEvents.cpp:100-104`) as the
only proc roll. That handler calls `AscensionCultist::Chance` (`src/server/coa/AscensionCultist.cpp:105-117`), which
read `float(info->ProcChance)` and rolled `roll_chance_f` without calling
`player->ApplySpellMod(id, SPELLMOD_CHANCE_OF_SUCCESS, chance)`.

Conformance pair `prove-batchC2` (`20261124-200759` / `20261124-201005`, server build `0df5d16b6e6c`, commit
`1f991106edcf`) measured `803339` -> `803340` on Darkwither `502220` ticks at `4238/21000 = 20.18%` and
`4278/21000 = 20.37%` with `300272` learned (expected `30%`, unlearned control `0/400`), and `3918/19000 = 20.62%` and
`3778/19000 = 19.88%` with `803283` learned (expected `25%`, unlearned control `0/400`). Video `q742IyqxrV0`
(2026-09-17) and the `bindmysoul` / `coabuildhub` snapshots carry the same `+10%` and `+5%` Presence chance text.

## Options

- Call `player->ApplySpellMod(id, SPELLMOD_CHANCE_OF_SUCCESS, chance)` in `AscensionCultist::Chance`, matching
  `AscensionPyromancer::Chance`, `AscensionNecromancer`, and `AscensionStarcaller`. Chosen.
- Add special-case checks for `300272` and `803283` only on the four Presence IDs. Rejected: duplicates the DBC class
  mask already carried on `300272` and `803283`, while an audit of all 19 `Chance()` callers shows no caller receives an
  unintended modifier.

## Decision

In `AscensionCultist::Chance` (`src/server/coa/AscensionCultist.cpp`), return `false` up front when `!player`, `!info`,
`!player->HasAura(id)`, or `State(player).timers.HasTimeUntilEvent(id)` holds, then apply
`player->ApplySpellMod(id, SPELLMOD_CHANCE_OF_SUCCESS, chance)` to `float(info->ProcChance)` before the `707753`
Horrific Visions addition (`300313` / `706245` above 40 Insanity) and `roll_chance_f(std::clamp(chance, 0.0f, 100.0f))`.
No shared file, SQL, DBC, or client text changes.

## Consequences

- `803035` (`20%`), `803037` (`20%`), `803082` (`30%`), and `803339` (`20%`) gain `+10` percentage points with `300272`
  Everpresent and `+5` percentage points with `803283` Embodied Presences (`+15` with both), matching their tooltips.
- `706245` Dark Revelation (`Flags = [0, 0, 134217728]`, `20%`) matches only `680602` (`40 Insanity`) `Effect[2]`, whose
  `CalcValue` is `-1 + 1 = 0`, so its rate is unchanged (`20%`, or `30%` above 40 Insanity with `707753`).
- All other 14 `Chance()` callers (`302015`, `300278`, `800463`, `560715`, `300300`, `300313`, `520388`, `560091`,
  `561336`, `560320`, `706911`, `707640`, `805606`, `805110`) carry `SpellFamilyFlags = [0, 0, 0]` and no `SpellAffect`
  `SPELLMOD_CHANCE_OF_SUCCESS` row, so their rates are unchanged.
- Regressions (counted pair `20261125-004405` / `20261125-004553`, build `592b996d98ae`):
  - `300272 behaviour_metric_delta presence_proc`: `6308/21000 = 30.04%` (`[29.23%, 30.86%]`) and `6333/21000 = 30.16%`
    (`[29.35%, 30.98%]`) against expected `30%`, with unlearned control `0/400` in both runs.
  - `803283 behaviour_metric_delta presence_proc`: `4697/19000 = 24.72%` (`[23.92%, 25.54%]`) and `4736/19000 = 24.93%`
    (`[24.13%, 25.74%]`) against expected `25%`, with unlearned control `0/400` in both runs and
    `803283 behaviour_metric_delta mana_cost` unchanged at `1547 -> 1774` (`+227`).
