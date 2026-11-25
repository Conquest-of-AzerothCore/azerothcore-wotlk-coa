# 0023. Owner ruling Q-cu-23: Hour of Twilight aligns spell haste, magic dispel, and Corrupt Mind

- Status: accepted (owner ruling Cultist Q-cu-23 / O-15, 2026-11-25; provisional number)
- Date: 2026-11-25

## Context

Hour of Twilight `255275` (server `Spell.dbc`, `SpellFamilyName` 31, `Description[enUS]`): "Channel for `$d`,
heralding the end of the world on all nearby enemies, instantly removing all beneficial magic effects from them and
reducing your damage taken and their haste and movement speed by `$255276s1%` while channeling. While channeling,
nearby enemies will also be struck with Apocalyptic Skies. At the end of the duration you unleash a terrifying
scream, applying Corrupt Mind on nearby enemies."

Effective `Spell.dbc` and `pending_db_world` data:

- `255275`: `DurationIndex 32` (`6000 ms`), `Effect[0]` caster damage taken `-25%`, `Effect[1]` triggers `255276`
  every `2000 ms`, `Effect[2]` triggers `301988` (Apocalyptic Skies) every `1500 ms`. No `SPELL_EFFECT_DISPEL`, no
  `560109` trigger, and no row in `spell_script_names` (`data/sql/updates/pending_db_world/`).
- `255276`: `EffectRadiusIndex = 14` (`8.0 yd`), `Effect[0]` slow `-25%` (`bp = -26, die = 1`, `$255276s1 = 25`),
  `Effect[1]` melee haste `-25%` (`bp = -26, die = 1`), `Effect[2]` spell haste (`SPELL_AURA_HASTE_SPELLS`) `-50%`
  (`bp = -51, die = 1`, producing `1.50x` cast speed in `Unit::ApplyCastTimePercentMod`).
- `src/server/coa/AscensionCultist*.cpp` had zero handlers for `255275` or `255276`.

Before measurements (`cu-t10/prove-a2`, build `a863401cd7ce`, server commit `4d4ac0d30a4b`, `cu-rt10/review.md:120-122`):

- `255275 behaviour_metric_delta enemy_spell_haste`: `cast_speed_multiplier` `1.0 -> 1.50` vs expected `1.25 +- 0.01`
  (alert/alert).
- `255275 behaviour_metric_delta dispel_magic`: Arcane Intellect `1459` on enemy dummy at `5 yd` stayed `1 -> 1` vs
  expected `0` (alert/alert).
- `255275 behaviour_metric_delta corrupt_mind_end`: Corrupt Mind `560109` on humanoid dummy at `5 yd` after `6500 ms`
  stayed `0 -> 0` vs expected `1` (alert/alert).

Live evidence (`ev2.md:10-34`): none (`0` events in 186 logs); archive tooltip video `q742IyqxrV0` (`8:46`) matches
`255275` `Spell.dbc` verbatim. The project owner ruled (`Q-cu-23 align_tooltip`, O-15, 2026-11-25) to align all
three parts with the tooltip.

## Options

- Implement all three parts inside `src/server/coa/AscensionCultistContracts.cpp`: set `255276` `Effects[2].BasePoints
  = -26` in `ApplyContracts`, add `UNITHOOK_ON_AURA_APPLY` to `cultist_scaling` to dispel all beneficial magic effects
  on hostile enemies within `Radius(255276)` (`8.0 yd`) when `255275` applies, and extend
  `cultist_scaling::OnAuraRemove` to cast `560109` on hostile enemies within `Radius(255276)` when `255275` expires
  (`AURA_REMOVE_BY_EXPIRE`) while the Cultist is alive. Chosen: class-scoped, requires no SQL (`spell_script_names`)
  and no shared engine edits, and naturally skips Corrupt Mind when the channel is interrupted or cancelled early.
- Register `255275` in `spell_script_names` for `aura_ascension_cultist_lifecycle`. Rejected: requires a SQL edit,
  which is outside class-scoped C++ limits.

## Decision

In `src/server/coa/AscensionCultistContracts.cpp`:

1. Set `info->Effects[2].BasePoints = -26` for `id == 255276` in `ApplyContracts`.
2. Hook `UNITHOOK_ON_AURA_APPLY` in `cultist_scaling` (`OnAuraApply`): for Cultist caster `255275`, collect beneficial
   `DISPEL_MAGIC` auras via `Unit::GetDispellableAuraList` on valid hostile targets within `Radius(255276)` (`8.0 yd`),
   roll `CalcDispelChance(enemy, true)`, and remove them via `Unit::RemoveAurasDueToSpellByDispel`.
3. In `cultist_scaling::OnAuraRemove`: on `AURA_REMOVE_BY_EXPIRE` of `255275` for an alive Cultist caster, cast
   `560109` on valid hostile targets within `Radius(255276)`.

No shared engine, DBC, SQL, or client text changes.

## Consequences

- Hour of Twilight `255275` reduces nearby enemies' spell haste by `25%` (`1.25x` cast time, matching melee haste,
  movement speed, and caster damage reduction), instantly dispels beneficial magic effects from nearby hostile enemies
  on channel start, and applies Corrupt Mind `560109` to nearby hostile enemies upon completing the full 6 s channel
  (early cancel or death does not trigger Corrupt Mind).
- Other spells reached: none (`255275`/`255276` only; existing `OnAuraRemove` handler for `560943` / `525049` is
  unchanged and re-verified).
- Regressions (`prove-B`, runs `20261125-090233` and `20261125-090317`, build `cd58fe6d6def`, `18/18` ok, `0` flips):
  - `255275 behaviour_metric_delta enemy_spell_haste`: `ok` / `ok` (`1.25` / `1.25` vs `1.25`, control `1.0`).
  - `255275 behaviour_metric_delta dispel_magic`: `ok` / `ok` (`0.0` / `0.0` vs `0.0`, control `1.0`).
  - `255275 behaviour_metric_delta corrupt_mind_end`: `ok` / `ok` (`1.0` / `1.0` vs `1.0`, control `0.0`).
  - All 5 sibling `255275` entries (`channel_duration`, `damage_taken`, `enemy_melee_haste`, `enemy_slow`,
    `apocalyptic_skies`) and all 10 `525049` entries (re-checking `cultist_scaling::OnAuraRemove`): `ok` / `ok`, no
    reading moved.
