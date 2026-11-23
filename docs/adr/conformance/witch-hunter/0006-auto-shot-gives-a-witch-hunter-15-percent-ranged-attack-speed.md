# 0006. Auto Shot gives a Witch Hunter 15% ranged attack speed

- Status: accepted
- Date: 2026-11-15

## Context

Auto Shot 75's Description in the installed Spell.dbc is `$?s552011[Automatically shoots the target until cancelled.
Increases your ranged Attack Speed by 15%.][... by $34082s2% and scales with Ranged Attack Power.]`. The live
baseline grants 552011 to the Witch Hunter, so the client shows the 15% branch, and the owner's live Witch Hunter
shows 15%. The 15 is a literal of the text: no DBC aura carries it, and before this change nothing applied any Auto
Shot haste to a Witch Hunter (the ranged speed read the weapon speed). Owner ruling O-21 (mentor D-127): "+15% ranged
attack speed, as the tooltip states", with no link to another class and no text change.

## Options

- Call `Unit::ApplyAttackTimePercentMod(RANGED_ATTACK, 15, apply)` from Witch Hunter code, the call an aura 140 of
  amount 15 makes, guarded by a `CustomData` flag.
- Cast Hunter's 34082 with a custom 15% value: 34082 belongs to Hunter and Hero, so any later change to it would
  reach the Witch Hunter (a cross-class link), and its effect 0 comes along.
- A Witch Hunter aura 140 spell: the class's own aura 140 spells are talents (Rapid Reload, Hail of Gunfire), and
  reusing one collides with its aura slot.

## Decision

The first option. `witch_hunter_auto_shot_haste` (`AscensionWitchHunterCompletion.cpp`) syncs the bonus on login and
on every learn and forget, for any spell id, so a class change that keeps Auto Shot is reconciled by the next learn.
The sync returns at once when the flag already matches the wanted state (class 15 and Auto Shot held, D-134), so a
replayed login hook or a reconnect never applies it twice. The constant is `AUTO_SHOT_TOOLTIP_RANGED_HASTE_PCT`.
`ApplyCastTimePercentMod` is not used: ranged-slot spells follow the ranged attack speed in
`Unit::ModSpellCastTime`, so Darkslayer and Heartseeking Bolt cast 15% faster as well.

## Consequences

- Sheet ranged speed: gun 2300 ms reads 2300 x 100 / 115 = 2000.00 ms, Heavy Crossbow 2800 ms reads 2434.78 ms.
- Rapid Reload and Hail of Gunfire multiply with it; each removal divides out its own share only.
- Rage per ranged hit is unchanged: it uses the unhasted attack time.
- Regressions: `witch-hunter-auto-shot-haste-relog.json` (two relogs, a replayed login hook, a reconnect, forget and
  learn), `-weapon-swap.json`, `-hail-of-gunfire.json`, `-rapid-reload.json`; the class file's Rapid Reload ranks 1
  and 2 read 2434.78 before (form: 2800 / 1.15) and 2254.43 / 2098.95 after.
- Hunter, Hero, Ranger, Starcaller and Tinker are untouched (class filter).
- Counted pair 20261115-194308 / 20261115-194358 (worldserver sha256 34348eaf6a0d): the four regressions pass in
  both runs; `707863` and `705512 behaviour_metric_delta ranged_haste` ok 0.862069 / 0.925926, `712479` ok 0.8.
