# 0012. Battle Cleric cuts the Paragon cooldown on the cast

- Status: accepted
- Date: 2026-11-22

## Context

Battle Cleric 300347, Spell.dbc text: "Paragon now has a 1 min cooldown and empowers your Gavels, ...". Paragon 680639
has RecoveryTime 300000 and CategoryRecoveryTime 300000. The passive's script (`AscensionSunClericBattleCleric.cpp`)
took 240000 ms off the Paragon cooldown in the Paragon aura's apply handler, only in `AURA_EFFECT_HANDLE_REAL`.

New Day 800600 resets the Paragon cooldown (`SPELL_EFFECT_ASCENSION_RESET_COOLDOWN`, EffectMiscValue 680639), so a
player can recast Paragon inside its own 20 s aura. That cast refreshes the aura in `AURA_EFFECT_HANDLE_REAPPLY`, and
the cooldown was not cut. Measured on pair B (build 1a61a435cece, commit 6a33ad5f7ae1), entry `paragon_cd_newday`:
299494 ms remaining 500 ms after the recast with the passive, as without it; a fresh cast (`paragon_cd`) read 59494.

## Options

- Cut the cooldown in the Paragon cast's `AfterCast` hook, after `Spell::SendSpellCooldown` set it, and stop cutting
  it in the aura handler.
- Also cut it in the aura handler's `AURA_EFFECT_HANDLE_REAPPLY` mode: REAPPLY also runs on aura recalculation, so the
  cooldown could be cut more than once.

## Decision

The first option (mentor decision D-75, 2026-11-22). The `AfterCast` hook of 680639 takes 240000 ms off the Paragon
cooldown when the caster has 300347 and the cast was not triggered with `TRIGGERED_IGNORE_SPELL_AND_CATEGORY_CD` (such
a cast starts no cooldown). The aura handler no longer touches the cooldown, so a fresh cast is cut once. The spell
script and the aura script share the `aura_ascension_battle_cleric` script name, so `spell_script_names` is unchanged.

## Consequences

- Every Paragon cast with Battle Cleric starts a 60 s cooldown, including a recast inside the aura after New Day.
- No other class reads 300347 or 680639 (class map: both only in class 27's spell list).
- Regression: class-file entries `paragon_cd` (fresh cast) and `paragon_cd_newday` (recast inside the aura after New
  Day), each with a control phase without 300347 (299500) and a phase with it (59500).
