# 0023. Owner ruling Q-cu-23: Hour of Twilight aligns spell haste, magic dispel, and Corrupt Mind

- Status: accepted (owner ruling Cultist Q-cu-23 / O-15, 2026-11-25; review follow-up `cu-rfix43`; provisional number)
- Date: 2026-11-25

## Context

Tooltip sentences read directly from server `Spell.dbc` (`/srv/coa/server-data/dbc/Spell.dbc`, sha256
`4e4ed9ba1c2e10089b543182da6836b2298fdeafd61f8602dc25f79fe5facfa7`, `SpellFamilyName` 31):

- Hour of Twilight `255275` (`Description[enUS]`): "Channel for `$d`, heralding the end of the world on all nearby
  enemies, instantly removing all beneficial magic effects from them and reducing your damage taken and their haste and
  movement speed by `$255276s1%` while channeling. While channeling, nearby enemies will also be struck with Apocalyptic
  Skies. At the end of the duration you unleash a terrifying scream, applying Corrupt Mind on nearby enemies."
- Hour of Twilight `255276` (periodic debuff, `Description[enUS]`): "...At the end of the duration you unleash a
  terrifying scream, applying Darkwither and Corrupt Mind on each affected enemy."
- Corrupt Mind `560109` (`Description[enUS]`): "Generates 10 Insanity. Corrupt the mind of an enemy and spread madness,
  fearing them in place for `$d` (8 sec vs players), bouncing to up to 2 nearby enemies`$?s525049[ and applying Mind
  Rot to them@s:560714:0@][]`. Damage dealt may end this effect."

Effective `Spell.dbc` and `pending_db_world` data:

- `255275`: `DurationIndex 32` (`6000 ms`), `Effect[0]` caster damage taken `-25%`, `Effect[1]` triggers `255276`
  every `2000 ms`, `Effect[2]` triggers `301988` (Apocalyptic Skies) every `1500 ms`. No `SPELL_EFFECT_DISPEL`, no
  `560109` trigger, and no row in `spell_script_names` (`data/sql/updates/pending_db_world/`).
- `255276`: `EffectRadiusIndex = 14` (`8.0 yd`), `Effect[0]` slow `-25%` (`bp = -26, die = 1`, `$255276s1 = 25`),
  `Effect[1]` melee haste `-25%` (`bp = -26, die = 1`), `Effect[2]` spell haste (`SPELL_AURA_HASTE_SPELLS`) `-50%`
  (`bp = -51, die = 1`, producing `1.50x` cast speed in `Unit::ApplyCastTimePercentMod`).
- `560109`: `DurationIndex 64` (`40000 ms`, `8000 ms` vs players / `CREATURE_FLAG_EXTRA_ALL_DIMINISH`),
  `EffectChainTarget[0..1] = 3`, `MaxAffectedTargets = 3`, `SPELL_ATTR4_BOUNCY_CHAIN_MISSILES`, `Speed = 23.0`.
- `src/server/coa/AscensionCultist*.cpp` originally had zero handlers for `255275` or `255276`.

Before measurements (`cu-t10/prove-a2`, build `a863401cd7ce`, server commit `4d4ac0d30a4b`, `cu-rt10/review.md:120-122`):

- `255275 behaviour_metric_delta enemy_spell_haste`: `cast_speed_multiplier` `1.0 -> 1.50` vs expected `1.25 +- 0.01`
  (alert/alert).
- `255275 behaviour_metric_delta dispel_magic`: Arcane Intellect `1459` on enemy dummy at `5 yd` stayed `1 -> 1` vs
  expected `0` (alert/alert).
- `255275 behaviour_metric_delta corrupt_mind_end`: Corrupt Mind `560109` on humanoid dummy at `5 yd` after `6500 ms`
  stayed `0 -> 0` vs expected `1` (alert/alert).

Review finding (`cu-rfix43`, Important #1): the initial commit (`dd7b06c189`) cast `560109` per hostile target in
`Nearby(player, Radius(255276))`, and each triggered cast still ran `Spell::SelectImplicitChainTargets` ->
`Spell::SearchChainTargets` (`jumpRadius = 10.0f`, `searchRadius = 20.0f`). On grouped enemies inside `8 yd`, each
enemy was hit multiple times (collapsing `DIMINISHING_FEAR` duration from `8 s` to `4 s` / `2 s` / immune on players
and `CREATURE_FLAG_EXTRA_ALL_DIMINISH` units), and enemies outside `8 yd` within chain range were struck by bounces.
Hour of Twilight's tooltip promises one application of Corrupt Mind per nearby enemy affected by Hour of Twilight,
without altering how a normally cast Corrupt Mind bounces to up to 2 nearby enemies.

Live evidence (`ev2.md:10-34`): none (`0` events in 186 logs); archive tooltip video `q742IyqxrV0` (`8:46`) matches
`255275` `Spell.dbc` verbatim. The project owner ruled (`Q-cu-23 align_tooltip`, O-15, 2026-11-25) to align all
three parts with the tooltip.

## Options

- Implement all three parts inside class-scoped Cultist C++ (`AscensionCultist.h`, `AscensionCultistContracts.cpp`,
  `AscensionCultistAbilities.cpp`): set `255276` `Effects[2].BasePoints = -26` in `ApplyContracts`; hook
  `UNITHOOK_ON_AURA_APPLY` in `cultist_scaling` to dispel beneficial magic auras within `Radius(255276)` (`8.0 yd`) and
  broadcast `SMSG_SPELLDISPELLOG`; and in `cultist_scaling::OnAuraRemove`, set a reentrant-safe
  `State(player).hourOfTwilightCorruptMind` flag around the `Nearby(player, Radius(255276))` `Cast(player, enemy,
  560109)` loop so `cultist_spells::OnSpellBeforeEffects` trims `spell->GetUniqueTargetInfo()` to
  `spell->m_targets.GetUnitTargetGUID()` for those casts only. Chosen: class-scoped, requires no SQL or shared engine
  edits, delivers full hit/immunity/DR and the 8 s PvP cap once per enemy within `Radius(255276)`, leaves outside
  enemies untouched, skips early cancel/interrupt/death naturally via `AURA_REMOVE_BY_EXPIRE`, and leaves normal manual
  casts of `560109` chaining untouched.
- Register `255275` or `560109` in `spell_script_names`. Rejected: requires a SQL edit outside class-scoped C++ limits.
- Apply `560109` via `Unit::AddAura` directly. Rejected: bypasses `Spell` hit, immunity, and diminishing-returns
  processing.

## Decision

1. In `src/server/coa/AscensionCultist.h`: add `bool hourOfTwilightCorruptMind = false;` to `CultistState`.
2. In `src/server/coa/AscensionCultistContracts.cpp`:
   - Set `info->Effects[2].BasePoints = -26` for `id == 255276` in `ApplyContracts`.
   - Hook `UNITHOOK_ON_AURA_APPLY` in `cultist_scaling` (`OnAuraApply`): for Cultist caster `255275`, collect
     beneficial `DISPEL_MAGIC` auras via `Unit::GetDispellableAuraList` on valid hostile targets within
     `Radius(255276)` (`8.0 yd`), roll `CalcDispelChance(enemy, true)`, remove them via
     `Unit::RemoveAurasDueToSpellByDispel`, and send `SMSG_SPELLDISPELLOG` for removed auras.
   - In `cultist_scaling::OnAuraRemove`: on `AURA_REMOVE_BY_EXPIRE` of `255275` for an alive Cultist caster, set
     `State(player).hourOfTwilightCorruptMind = true` (restoring the previous value afterward) while casting `560109`
     on valid hostile targets within `Radius(255276)`.
3. In `src/server/coa/AscensionCultistAbilities.cpp`:
   - In `cultist_spells::OnSpellBeforeEffects` (before the `spell->IsTriggered()` guard): when `info->Id == 560109` and
     `State(player).hourOfTwilightCorruptMind` is true, remove every `TargetInfo` from `spell->GetUniqueTargetInfo()`
     whose `targetGUID != spell->m_targets.GetUnitTargetGUID()`, then return.

No shared engine, DBC, SQL, or client text changes.

## Consequences

- Hour of Twilight `255275` reduces nearby enemies' spell haste by `25%` (`1.25x` cast time), instantly dispels
  beneficial magic effects from nearby hostile enemies on channel start (emitting `SMSG_SPELLDISPELLOG`), and upon
  completing the full 6 s channel applies exactly one non-chaining Corrupt Mind `560109` (with full duration and no
  multi-hit DR collapse) to each nearby hostile enemy while leaving enemies outside Hour of Twilight's radius
  untouched. Early channel cancel or death does not trigger Corrupt Mind.
- Normal manual casts of Corrupt Mind `560109` keep `hourOfTwilightCorruptMind == false` and continue to bounce to up
  to 2 nearby enemies (`560109 bounce_cap` verified `3` of `5`).
- Other spells reached: `560109` (*Corrupt Mind*, `7/7` ok), `525049` (*Eldritch Screams*, sharing `OnAuraRemove` /
  `OnSpellHitResult`, `10/10` ok), and `807128` (sharing `cultist_spells`, `18/18` ok); no reading moved.
- Regression layout note: `metric_delta` cannot spawn 4 enemy players at custom distances (`enemy_player_race` supports
  at most `enemy` + `enemy_helper` without offsets) nor target `area1..3` as separate `ally_arm` actors
  (`ally_arm.py:287`). The regression therefore uses `CREATURE_FLAG_EXTRA_ALL_DIMINISH` creature `36301` (*Zhaagrym
  (1)*, `CombatReach = 1.5 yd`, exact `8 s / 4 s / 2 s / immune` Fear DR via `Unit.cpp:13240,13276` and
  `AscensionCultistAbilities.cpp:115-122`) across 3 inside enemies (`dummy = 3.0 yd`, `area1 = 4.5 yd`,
  `area2 = 6.0 yd`) and 1 outside enemy within chain range (`area3 = 14.0 yd`, `8.0 yd < 10.0 yd` jump radius from
  `area2`) in three complementary entries plus an early-cancel control.
- Regressions (`cu-rfix43-prove-1`, runs `20261125-094456` and `20261125-094551`, build `784e9da7b234`, `47/47` ok,
  `0` flips; plus `cu-rfix43-prove-255275-repeat6`, 6 consecutive runs `20261125-094654`..`-094917`, `12/12` ok in all
  6 runs, `0` flips):
  - `255275 enemy_spell_haste`: `ok` / `ok` (`1.25` vs `1.25`, control `1.0`).
  - `255275 dispel_magic`: `ok` / `ok` (`1 -> 0`).
  - `255275 corrupt_mind_end`: `ok` / `ok` (`0 -> 1`).
  - `255275 corrupt_mind_end_group_duration`: `ok` / `ok` (`area_sum` `aura 560109` `0 -> 3` at `13609 ms`
    [`dummy=1, area1=1, area2=1, area3=0`], `0` at `14830 ms`; `ally_arm` `dummy` `aura_apply_count` `0 -> 1`).
  - `255275 corrupt_mind_end_group_applies`: `ok` / `ok` (`area_sum` `aura_apply_count 560109` `0 -> 3`
    [`dummy=1, area1=1, area2=1, area3=0`]).
  - `255275 corrupt_mind_end_outside_none`: `ok` / `ok` (`area3` `aura_apply_count 560109` `0 -> 0`; `ally_arm` `dummy`
    `0 -> 1`).
  - `255275 corrupt_mind_early_cancel`: `ok` / `ok` (`aura 560109` `1 -> 0`, `aura_apply_count` `1 -> 1`, interrupting
    `60235` `spell_go_count` `0 -> 1`).
  - `255275 damage_taken` (repaired to `spell_damage_total` on `41394` at `wait_ms: 0`): `ok` in all `8/8` runs
    (`1100 -> 1925`, `+825` under `-25%`, `0` flips).
  - All sibling `255275` (`channel_duration`, `enemy_melee_haste`, `enemy_slow`, `apocalyptic_skies`), `560109` (`7/7`),
    `525049` (`10/10`), and `807128` (`18/18`) entries: `ok` / `ok`, no reading moved.
