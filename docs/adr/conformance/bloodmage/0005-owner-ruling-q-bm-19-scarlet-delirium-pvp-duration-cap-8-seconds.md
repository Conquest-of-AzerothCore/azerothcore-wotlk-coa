# 0005. Owner ruling Q-bm-19: Scarlet Delirium caps PvP Fear duration at 8 seconds

- Status: accepted (owner ruling Bloodmage Q-bm-19 / O-10, 2026-11-26; provisional number)
- Date: 2026-11-26

## Context

Scarlet Delirium (`801074` Rank 1, `803684..803688` Ranks 2–6; server `Spell.dbc`, `Description[enUS]`): "Flood the
minds of up to $i nearby enemies with visions of unraveling flesh, fearing them for $d (8 sec versus players) while
draining their life essence, siphoning ${$m2+0+$SP*0.15} health every $t2 sec."

Effective server `Spell.dbc` data (verified by full scan of `Spell.dbc`):

- Exactly 6 spells in `SpellFamilyName = 26` carry `SpellFamilyFlags[2] & 0x100`: the 6 Scarlet Delirium ranks
  `801074`, `803684`, `803685`, `803686`, `803687`, and `803688`. All 6 have `DurationIndex = 64` (`40000 ms`) and
  `Effect[0] = SPELL_EFFECT_APPLY_AURA` with `ApplyAuraName = SPELL_AURA_MOD_FEAR (7)`.
- `GetDiminishingReturnsLimitDuration` (`src/server/game/Spells/SpellMgr.cpp:342-415`) returned the default
  `10 * IN_MILLISECONDS` for Scarlet Delirium, so `Unit::ApplyDiminishingToDuration` capped PvP Fear duration at
  `10000 ms` instead of `8000 ms`.
- Pre-fix measurement (`batch4/bm-re2-2`, `ev2.md`): `803688` PvE creature duration (`40 s`) and health siphon passed,
  while `player_duration` alerted because the aura lasted past `8000 ms` on an enemy player.

Tooltip video archive `q742IyqxrV0` (`t=6:40` Rank 6, `t=7:18` Rank 1) confirms `"for 40 sec (8 sec versus players)"`;
combat logs contained no PvP applications (`ev2.md`). The project owner ruled (`Q-bm-19 cap_8s`, `O-10`, 2026-11-26) to
cap Scarlet Delirium's PvP Fear duration at `8 s` in `SpellMgr.cpp`.

## Options

- Add an explicit `8 * IN_MILLISECONDS` branch in `GetDiminishingReturnsLimitDuration`
  (`src/server/game/Spells/SpellMgr.cpp`) matching `SpellFamilyName == 26 && (SpellFamilyFlags[2] & 0x100) &&
  Effects[EFFECT_0].IsAura(SPELL_AURA_MOD_FEAR)`. Chosen: directly follows owner ruling `Q-bm-19`, matches the five
  existing CoA 8 s PvP caps right above it (`991522`, `800145`, `806148`, `500952`, `803325`), covers all 6 ranks with
  zero unintended family-26 collisions, and integrates natively with diminishing returns (`8000 -> 4000 -> 2000 -> 0 ms`)
  while preserving `40000 ms` vs PvE targets.
- Cap duration in an `AllSpellScript::OnCalcMaxDuration` hook in `src/server/coa/` (as Cultist ADR 0024 did to avoid
  touching `ENGINE_FILES`). Rejected: `O-9` (`SpellInfo.h`/`.cpp`) already touches `ENGINE_FILES` in the same fix wave,
  and `O-10` explicitly requested `SpellMgr.cpp`.

## Decision

In `GetDiminishingReturnsLimitDuration` (`src/server/game/Spells/SpellMgr.cpp`), return `8 * IN_MILLISECONDS` when
`spellproto->SpellFamilyName == 26 && (spellproto->SpellFamilyFlags[2] & 0x100) &&
spellproto->Effects[EFFECT_0].IsAura(SPELL_AURA_MOD_FEAR)`.

## Consequences

- All 6 ranks of Scarlet Delirium (`801074`, `803684..803688`) cap at `8000 ms` against players and
  `CREATURE_FLAG_EXTRA_ALL_DIMINISH` targets (halving cleanly through Fear DR steps) while retaining `40000 ms` against
  ordinary PvE creatures.
- No other spell in `Spell.dbc` matches the predicate.
- Post-fix build, `803688` `player_duration` / `duration` regressions, and finished-class reruns (`templar` 19,
  `necromancer` 23) run after the fix-wave merge build (`O-8`).
