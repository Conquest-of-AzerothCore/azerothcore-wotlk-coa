# 0010. Fearmonger uses 2308 ms tick rate (O-24) and Taldaram's Torment periodic ticks can crit

- Status: accepted (owner ruling Bloodmage Q-bm-10 / O-10 / O-11, 2026-11-26; provisional number)
- Date: 2026-11-26

## Context

Server `Spell.dbc` (`/srv/coa/server-data/dbc/Spell.dbc`, `SpellFamilyName = 26`):

- Fearmonger `501132`: `"Increases the tick rate and cost of Taldaram's Torment by $s1%."` (`Effect[0]` aura `108`
  `SPELL_AURA_ADD_PCT_MODIFIER`, `MiscValue = 19` `SPELLMOD_ACTIVATION_TIME`, `BasePoints = -31`, `DieSides = 1` ->
  `-30%` on `EffectSpellClassMask = (0, 0, 2097152)`; `Effect[1]` `SPELLMOD_COST` `+30%`).
- Taldaram's Torment `800772, 802568..802573, 802580` (all 8 ranks share `SpellFamilyFlags = (0, 0, 2097152)`,
  `DurationIndex = 8` `15000 ms`, `Effect[0]` `SPELL_AURA_PERIODIC_DAMAGE` `Amplitude = 3000 ms`, `Effect[1]` aura `308`,
  all bound to `aura_ascension_bloodmage_taldarams_torment` via `-800772`):
  `"@ext:Periodic damage dealt through this can critically strike.:ext@"`.

Two defects existed on `aura_ascension_bloodmage_taldarams_torment`:

1. `Player::ApplySpellMod(..., SPELLMOD_ACTIVATION_TIME, m_amplitude)` (`SpellAuraEffects.cpp:725`) multiplies `3000 ms`
   by `1 + (-30/100) = 0.7f` -> `2100 ms` (`+42.86%` tick rate) instead of the O-24 `+30%` tick rate
   (`3000 / 1.30 = 2307.69 ms -> 2308 ms`). Sun Cleric's integer pre-scaling formula truncates `-30%` on `3000 ms` to
   `2306 ms`.
2. `AuraEffect::CalcPeriodicCritChance` (`SpellAuraEffects.cpp:1180-1210`) checks `SPELL_AURA_ABILITY_PERIODIC_CRIT`
   (`286`), while Taldaram's Torment carries aura `308` on `Effect[1]` and `582767` is never applied, leaving periodic
   ticks unable to crit (`m_critChance == 0.0f`).

The owner confirmed `Q-bm-10` (`rate_2308ms`) in `O-10` and `O-11`.

## Options

- Implement `CalcPeriodic` (`DoEffectCalcPeriodic`) and `EnablePeriodicCrit` (`AfterEffectApply`) inside
  `aura_ascension_bloodmage_taldarams_torment` (`src/server/coa/AscensionBloodmageTalents.cpp`) and update
  `apps/coa-gameplay-test/scenarios/bloodmage-fearmonger-tick-and-cost.json` (`2100 -> 2308`). Chosen: stays strictly
  inside Bloodmage C++, uses double rounding `target = std::round(double(amplitude) * 100.0 / (100.0 - modifier))` and
  `amplitude = int32(std::ceil(target * 100.0 / (100.0 + modifier)))` so `int32(3298 * 0.7f) == 2308 ms` exact after
  `ApplySpellMod`, and computes periodic crit via `SpellDoneCritChance` + `SpellTakenCritChance` + `SetCritChance`.
- Change `Player::ApplySpellMod` globally for `SPELLMOD_ACTIVATION_TIME`. Rejected: affects every class.

## Decision

1. In `src/server/coa/AscensionBloodmageTalents.cpp` (`aura_ascension_bloodmage_taldarams_torment`):
   - Add `CalcPeriodic` bound to `DoEffectCalcPeriodic` (`EFFECT_0, SPELL_AURA_PERIODIC_DAMAGE`), pre-scaling `amplitude`
     when `SPELL_FEARMONGER` (`501132`) `EFFECT_0` is active on the caster's spell-mod owner so the subsequent
     `SPELLMOD_ACTIVATION_TIME` yields `2308 ms`.
   - Add `EnablePeriodicCrit` bound to `AfterEffectApply` (`EFFECT_0, SPELL_AURA_PERIODIC_DAMAGE,
     AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK`), calling `SpellDoneCritChance`, `SpellTakenCritChance`, and
     `SetCritChance(std::max(0.0f, crit))`.
2. Update `apps/coa-gameplay-test/scenarios/bloodmage-fearmonger-tick-and-cost.json` to assert `2308 ms`.

## Consequences

- Fresh applications of any Taldaram's Torment rank under Fearmonger tick at `2308 ms` while retaining the `+30%` health
  cost modifier and unboosted `3000 ms` baseline.
- Taldaram's Torment periodic ticks can critically strike using the caster's spell crit chance and target taken-crit
  modifiers.
- Build and gameplay verification run in the coordinator's post-merge verification pass for Lots 1–3.
