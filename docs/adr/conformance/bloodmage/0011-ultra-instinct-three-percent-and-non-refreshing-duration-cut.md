# 0011. Owner ruling Q-bm-8: Ultra Instinct grants +3% crit damage and cuts remaining duration without refresh

- Status: accepted (owner ruling Bloodmage Q-bm-8 / O-10, 2026-11-26; provisional number)
- Date: 2026-11-26

## Context

Server `Spell.dbc` (`SpellFamilyName = 26`):

- Ultra Instinct passive `704654`: `"Direct ability critical strikes now increase your spell and ability critical strike
  chance and critical damage by $504166s1% for ${$504166d-1} sec, stacking up to $504166u times. Each additional
  critical strike increases this by an additional $504166s1%, but reduces its duration by $/1000;504166s3 sec."`
- Ultra Instinct buff `504166`: `DurationIndex = 38` (`11000 ms`), `StackAmount = 10`, `Effect[0]` aura `290`
  (`BasePoints = 2, DieSides = 1` -> `+3%` crit chance), `Effect[1]` aura `163` (`MiscValue = 127`, `BasePoints = 4,
  DieSides = 1` -> `+5%` crit damage), `Effect[2]` effect `177` (`SPELL_EFFECT_ASCENSION_MODIFY_AURA_DURATION`,
  `BasePoints = -1001, DieSides = 1`, `MiscValue = 504166` -> `-1000 ms`).

Two defects broke tooltip conformance:

1. `504166` `Effect[1]` gave `+5%` critical damage per stack instead of `+3%`.
2. Re-casting `504166` on subsequent crits refreshed the aura to `11000 ms` before `Effect[2]` subtracted `1000 ms`,
   leaving the buff pinned at `10000 ms` instead of cutting `1 s` off the remaining duration.

The owner ruled (`Q-bm-8` `tooltip_3_cut_no_refresh`, `O-10`): change `504166` `Effect[1]` to `+3%`/stack and subtract
`1 s` from the remaining duration on subsequent crits without refreshing to `10 s`.

## Options

- Patch `504166` `Effects[EFFECT_1].BasePoints = 2` with `ClientSpellPatches` and intercept `704654` procs in
  `aura_ascension_bloodmage_ultra_instinct` to cast `504166` on first proc (`11000 - 1000 = 10000 ms`) and on later
  procs call `ModStackAmount(1)` + `SetDuration(remaining - 1000)` (or `Remove()` if `remaining <= 1000`). Chosen:
  preserves `504166` `Effect[2]` for initial duration and tooltip `$504166d-1` / `$/1000;504166s3` tokens while avoiding
  refreshing or double-subtracting on stacks 2–10.
- Clear `504166` `Effect[2]` and alter `DurationIndex`. Rejected: breaks tooltip token calculation `$504166d-1` and
  `$/1000;504166s3`.

## Decision

1. In `src/server/coa/AscensionBloodmageTalents.cpp` (`bloodmage_talent_contracts::OnLoadSpellCustomAttr`): set
   `info->Effects[EFFECT_1].BasePoints = 2;` for `504166` and register `504166` in `ClientSpellPatches`.
2. Add `aura_ascension_bloodmage_ultra_instinct` in `src/server/coa/AscensionBloodmageTalents.cpp`, registered in
   `AddSC_AscensionBloodmageTalents()` and bound to `704654` in
   `data/sql/updates/pending_db_world/rev_20261127_02_bloodmage_talents_scripts_procs.sql`.

## Consequences

- Each stack of Ultra Instinct (`504166`) grants `+3%` crit chance and `+3%` crit damage (up to 10 stacks).
- The first crit starts the buff at `10000 ms`; each subsequent crit adds 1 stack and cuts `1000 ms` from the remaining
  duration (removing the buff if `<= 1000 ms` remains) without refreshing.
- Build and gameplay verification run in the coordinator's post-merge verification pass for Lots 1–3.
