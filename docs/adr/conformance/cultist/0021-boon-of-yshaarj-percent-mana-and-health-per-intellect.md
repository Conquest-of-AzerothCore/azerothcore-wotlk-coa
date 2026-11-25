# 0021. Owner ruling Q-cu-24: Boon of Y'shaarj applies +200%/+400% to Cultist mana and health per Intellect

- Status: accepted (owner ruling Cultist Q-cu-24 / O-16, 2026-11-25)
- Date: 2026-11-25

## Context

Boon of Y'shaarj `560080` (Rank 1, `$s1 = 200`) / `561335` (Rank 2, `$s1 = 400`), server `Spell.dbc` `Description[enUS]`:
"Increases the amount of mana and now health per point of Intellect by $s1%." Both ranks carry two
`SPELL_AURA_ASCENSION_MOD_MAX_MANA_FROM_STAT` (aura `328`) effects on `STAT_INTELLECT` (`MiscValueB = 3`): `Effect[0]`
targets `POWER_MANA` (`MiscValue = 0`) and `Effect[1]` targets `POWER_HEALTH` (`MiscValue = -2`), with `BasePoints`
`199+1 = 200` (Rank 1) and `399+1 = 400` (Rank 2).

Shared engine code `GetAscensionMaxManaFromStatBonus` and `GetAscensionMaxHealthFromStatBonus`
(`src/server/game/Entities/Unit/StatSystem.cpp:70-100`) compute `CalculatePct(float(player.GetStat(STAT_INTELLECT)), amount)`,
which added a flat `+2` (Rank 1) and `+4` (Rank 2) mana and health per point of Intellect.

Before measurement (`batch3/cu-rt10/review.md` Alerts #4–#5 & §5, `prove-b1`, build `a863401cd7ce`, commit `4d4ac0d30a4b`):
- `560080` (Rank 1): mana `+142` at 71 Int (`2297 -> 2439`) and `+742` at 371 Int (`6797 -> 7539`) vs `+1570` / `+10570`;
  health `+142` (`2278 -> 2420`) and `+742` (`2278 -> 3020`).
- `561335` (Rank 2): mana `+284` at 71 Int (`2297 -> 2581`) and `+1484` at 371 Int (`6797 -> 8281`) vs `+3140` / `+21140`;
  health `+284` (`2278 -> 2562`) and `+1484` (`2278 -> 3762`).

The owner ruled (Cultist `Q-cu-24` / `O-16`, 2026-11-25):
- Mana: apply `+200%` / `+400%` to the normal Intellect-to-mana scaling (`15 x 3 = 45` mana/Int at Rank 1, `15 x 5 = 75` at
  Rank 2).
- Health: start from a base of `0.25` health per Intellect point increased by the same `+200%` / `+400%` (`0.75` HP/Int at
  Rank 1, `1.25` HP/Int at Rank 2).
- Scope: Cultists only and only with Boon of Y'shaarj learned (without the talent, Intellect grants `0` health; no other
  class changes).

In `Player::GetManaBonusFromIntellect()` (`StatSystem.cpp:421-429`), the engine gives `1` mana for each of the first 20
Intellect points (`baseInt`) and `15` mana for each point above 20 (`moreInt * 15.0f`). Applying `+200%` / `+400%` directly
to `GetManaBonusFromIntellect()` scales the first 20 points proportionally (`1 -> 3` at Rank 1, `1 -> 5` at Rank 2) and
points above 20 to `45` / `75`, yielding exact `+1570` / `+10570` (Rank 1) and `+3140` / `+21140` (Rank 2) at 71 / 371 Int.
The bonus multiplies the whole Intellect mana bonus, including the first 20 Intellect points that give 1 mana each
(3 / 5 mana with the talent); reported to the owner on 2026-11-25.

## Options

- Hook the existing `PlayerScript` callbacks `PLAYERHOOK_ON_AFTER_UPDATE_MAX_HEALTH` and
  `PLAYERHOOK_ON_AFTER_UPDATE_MAX_POWER` (`StatSystem.cpp:440,461`) in `cultist_player`
  (`src/server/coa/AscensionCultist.cpp`), guarded strictly to Cultists (`Owner(player) == player`) and aura effects
  `560080` / `561335`, replacing the flat aura-328 term (`CalculatePct(intellect, amount) * totalPct`) with
  `CalculatePct(manaFromInt, amount) * totalPct` for mana and `intellect * 0.25f * (1.0f + amount / 100.0f) * totalPct` for
  health. Chosen: zero shared engine edits, keeps native aura-328 triggers on learn/unlearn (`SpellAuraEffects.cpp:4530-4533`)
  and Intellect changes (`StatSystem.cpp:177-178`), preserves `TOTAL_PCT` modifiers, and keeps `spell_effect_value` at `200`/`400`.
- Modify `StatSystem.cpp:70-100`. Rejected: shared engine code used by other classes' aura-328 spells.

## Decision

In `src/server/coa/AscensionCultist.cpp`, subscribe `cultist_player` to `PLAYERHOOK_ON_AFTER_UPDATE_MAX_HEALTH` and
`PLAYERHOOK_ON_AFTER_UPDATE_MAX_POWER` and adjust `value` only when `Owner(player) == player` and an active aura `328`
effect belongs to `560080` or `561335` on `STAT_INTELLECT`. No shared engine, SQL, DBC, or other-class files are changed.

## Consequences

- Only Cultists carrying `560080` or `561335` are affected; Cultists without the talent keep `0` health per Intellect and
  standard mana per Intellect, and other classes' aura-328 spells (verified with `runemaster-wizardry`, `20261125-090952`)
  are untouched.
- Pre-existing handwritten scenario `apps/coa-gameplay-test/scenarios/cultist-boon-of-yshaarj.json` (written for #965 under
  the old `+2/+4` flat model) was updated from `[1.9, 2.1]` to the O-16 `5/3` ratio `[1.60, 1.75]` (`1.25 / 0.75 = 1.6667`)
  and passed (`20261125-093947`: level-40 Cultist `50` Int measured R1 mana `+940`, R1 health `+37`, R2 health `+62`,
  ratio `1.6757`).
- Regressions (counted pair `cu-rfix42-prove` `20261125-094043` / `20261125-094117`, build `0a0822d00f1f`, 0 flips; also
  confirmed in `prove-2` `20261125-090640` / `20261125-090726`):
  - `560080`: `mana_base` `+1570` / `+1570` (`2297 -> 3867`, `ok/ok`), `mana_int` `+10570` / `+10570` (`6797 -> 17367`,
    `ok/ok`), `health_base` `+53` / `+53` (`2278 -> 2331`, `ok/ok`), `health_int` `+278` / `+278` (`2278 -> 2556`, `ok/ok`).
  - `561335`: `mana_base` `+3140` / `+3140` (`2297 -> 5437`, `ok/ok`), `mana_int` `+21140` / `+21140` (`6797 -> 27937`,
    `ok/ok`), `health_base` `+88` / `+88` (`2278 -> 2366`, `ok/ok`), `health_int` `+463` / `+463` (`2278 -> 2741`, `ok/ok`).
