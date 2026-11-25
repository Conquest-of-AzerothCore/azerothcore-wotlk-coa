# 0017. Eternal Grasp extends summoned Tentacle durations

- Status: accepted
- Date: 2026-11-25

## Context

Eternal Grasp `704878` (Rank 1) and `704879` (Rank 2) (server `Spell.dbc`, `SpellFamilyName` 31, `Description[enUS]`):
"Increases the duration of your Tentacles by `$s1%`."

Effective `Spell.dbc` and `pending_db_world` data:

- `704878` `Effect[0]`: `SPELL_AURA_ADD_PCT_MODIFIER` (108), `MiscValue = 1` (`SPELLMOD_DURATION`), `BasePoints = 24`,
  `DieSides = 1` (`+25%`), `EffectSpellClassMask = [32, 4194432, 536870912]`.
- `704879` `Effect[0]`: `SPELL_AURA_ADD_PCT_MODIFIER` (108), `MiscValue = 1` (`SPELLMOD_DURATION`), `BasePoints = 49`,
  `DieSides = 1` (`+50%`), `EffectSpellClassMask = [32, 4194432, 536870912]`.
- Full `Spell.dbc` family-31 scan confirms mask `[32, 4194432, 536870912]` matches all Cultist Tentacle summon spells:
  `802044` (Tentacle of Y'shaarj, `30 s -> 37.5 s / 45 s`), `801153` (Tentacle of C'Thun, `30 s -> 37.5 s / 45 s`),
  `802042` (Tentacle of Yogg-Saron, `30 s -> 37.5 s / 45 s`), `572103` (Tentacle of N'Zoth, `8 s -> 10 s / 12 s`), and
  `500707` (Eldritch Tentacle, `8 s -> 10 s / 12 s`), and matches zero non-Tentacle spells in `CultistSummonSpells`
  (`301988`, `680573`, `706932`, `804777`, `804779` all have `SpellFamilyFlags = [0, 0, 0]`).
- No pending SQL overrides exist for `704878` or `704879`.

Before this fix, conformance pairs `prove-part-b1`, `b1b`, `b1c` (build `89d8bfc1fc05`, server `c81a74761fd4`) measured:

- `704878 behaviour_metric_delta tentacle_duration`: `owned_creature_count(50096) = 0` at `35.0 s` (expected `1` until
  `37.5 s`, `0` at `40.0 s`; alert).
- `704879 behaviour_metric_delta tentacle_duration`: `owned_creature_count(50096) = 0` at `42.0 s` (expected `1` until
  `45.0 s`, `0` at `48.0 s`; alert).

Cause in `src/server/coa/AscensionCultistAbilities.cpp:450-460` (`spell_ascension_cultist_ability::Effect`, since
initial commit `e36bc50aad`): the script intercepts every `SPELL_EFFECT_SUMMON` in `CultistSummonSpells` via
`PreventHitDefaultEffect(index)` and passes raw `GetSpellInfo()->GetDuration()` to `Summon(...)` without calling
`player->ApplySpellMod(GetSpellInfo()->Id, SPELLMOD_DURATION, duration)` (unlike stock `Spell::EffectSummonType` in
`SpellEffects.cpp:3388-3390` and `ModifiedDuration` in `AscensionCultistEvents.cpp:26-31`).

Live combat-log evidence (`ev2.md`): live log 67 (`Hyrax`) with Eternal Grasp rank 1 observed 3 Tentacles of N'Zoth
(`572103`) lasting `9.93-9.98 s` (`8 s * 1.25`) and 1 Tentacle of Yogg-Saron (`802042`) lasting `37.5 s` (`30 s * 1.25`).

## Options

- Call `player->ApplySpellMod(GetSpellInfo()->Id, SPELLMOD_DURATION, duration)` before passing `std::max(1000, duration)`
  to `Summon(...)` in `spell_ascension_cultist_ability::Effect` (`src/server/coa/AscensionCultistAbilities.cpp:457`).
- Hardcode checks for `704878`/`704879` aura amounts on specific Tentacle spell IDs. Rejected: duplicates the `Spell.dbc`
  `SPELLMOD_DURATION` mask logic already handled by `Player::ApplySpellMod` and would miss `561035` (Teachings of Mythrax)
  on direct `500707` casts.

## Decision

In `src/server/coa/AscensionCultistAbilities.cpp:456-460` (`spell_ascension_cultist_ability::Effect`), compute:

```cpp
int32 duration = GetSpellInfo()->GetDuration();
player->ApplySpellMod(GetSpellInfo()->Id, SPELLMOD_DURATION, duration);
Summon(player, effect.MiscValue, position, std::max(1000, duration),
    GetExplTargetUnit(), GetSpellInfo()->Id);
```

No shared engine, DBC, SQL, or client text changes.

## Consequences

- Eternal Grasp rank 1 (`704878`, +25%) and rank 2 (`704879`, +50%) now extend the live duration of every Cultist
  Tentacle summoned through `spell_ascension_cultist_ability` (`802044`, `801153`, `802042`, `572103`, `500707`).
- Non-Tentacle Cultist summons (`301988`, `680573`, `706932`, `804777`, `804779`) have `SpellFamilyFlags = [0, 0, 0]`,
  so `ApplySpellMod` leaves their durations unchanged.
- No other class is reached. Reached Cultist spells (`802044` 7/7 checks, `572103` 9/9 checks) were rerun in `prove-D`
  with 0 readings moved, and catalog scenario `apps/coa-gameplay-test/scenarios/cultist-eternal-grasp.json` passed
  (`VERIFY ALL: PASSED`, `20261125-092230`).
- Regressions (`prove-D`, runs `20261125-092133` and `20261125-092203`, build `df6b57891a53`, 18/18 ok, 0 flips):
  - `704878 tentacle_duration`: unlearned control `0` at `35009 ms`; learned `1` at `35009 ms` (window `34800..35600 ms`)
    and `0` at `40018 ms` (window `39800..40600 ms`) in both runs (ok/ok),
  - `704879 tentacle_duration`: unlearned control `0` at `42009 ms`; learned `1` at `42009 ms` (window `41800..42600 ms`)
    and `0` at `48018 ms` (window `47800..48600 ms`) in both runs (ok/ok).
- Ledger rows `704878` and `704879` updated from `effect_value e0 #0` to
  `["704878 behaviour_metric_delta tentacle_duration"]` and `["704879 behaviour_metric_delta tentacle_duration"]`
  (audited `behaviour` in `prove-D/audit.json`).
