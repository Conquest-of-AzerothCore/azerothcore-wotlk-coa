# 0017. The last Radiant Flame tick spends its Dawn charge

- Status: accepted
- Date: 2026-11-22

## Context

A follow-up to #13027 (`90cca54837`, "class abilities batch 3"), which made every Radiant Flame tick spend one Dawn
charge. Its ruling, recorded in the contract of
`apps/coa-gameplay-test/scenarios/sun-cleric-radiant-flame-direct-ticks-12951.json`: "under Dawn every tick spends a
Dawn charge" (the PR author's review on 2026-11-20 of https://www.youtube.com/watch?v=ZZwP04HEkq4). Dawn 807440,
Spell.dbc text: "Each damaging or healing spell will expend a charge regardless of whether or not your current Vow is
fulfilled by it."

Radiant Flame 560867 (rank of 806060) is a 4 sec channel. Its effect 0, aura 227
`SPELL_AURA_PERIODIC_TRIGGER_SPELL_WITH_VALUE`, amplitude 1000 ms, targets the enemy (`TARGET_UNIT_TARGET_ENEMY`) and
triggers Radiant Flame 807058 for the cleric: five ticks. The class script found the channel only through
`GetCurrentSpell(CURRENT_CHANNELED_SPELL)` (`Origin()`, `AscensionSunCleric.cpp`) and spent Dawn on it only when
`Origin()` returned something other than the tick (`OnSpellBeforeEffects`, `AscensionSunClericAbilities.cpp`).

Order proved with log reads at base `68e7af248b` (fix note
`.agents/plans/sun-cleric-conformance/merged/12951-order/report.md`, not committed):

- every map update runs the players before the non-player objects (`Map.cpp:495-521`);
- in the player's update the channel's timer reaches 0 and `Unit::_UpdateSpells` drops the finished pointer
  (`Spell.cpp:4562-4566`, `Unit.cpp:4681-4688`);
- in the same map update the enemy's aura fires its 5th tick at duration 0 and casts 807058 for the cleric, which no
  longer has a current channel, so `Origin()` returns the tick and no charge is spent.

Simulated clock, run 20261122-035738: ticks 1 to 4 at game ms 60809 to 63812 see the channel; the channel clear and
the 5th tick both at game ms 64812, the clear logged first; step 62 read 6 charges left against 5.
`GetTriggeredByAuraSpellInfo()` returned 560867 on all five ticks. Real clock: four runs passed with the 5th tick 29 to
107 ms before the clear; an earlier single-scenario real-clock run (20261122-035201) failed its first attempt with 6.
So a real player loses the last spend whenever the cast lands in the same map update phase.

## Options

- Spend Dawn on the last tick when the channel is gone, recognising the tick by the aura that fired it.
- Keep a record of the channel on the player, outliving the engine's current-spell pointer. It adds class state for
  a value the tick already carries.
- Add a harness action that delays the enemy's aura so the late tick is forced on both clocks (the fix note's
  regression design, a G-39 harness change).

## Decision

The first option (mentor decision D-83, 2026-11-22). In `OnSpellBeforeEffects`, when `Origin()` returns the tick
itself and the tick is Radiant Flame 807058 fired by a Radiant Flame rank (`GetTriggeredByAuraSpellInfo()`,
`Spell.h:672`), `SpendDawn` runs on the tick with that rank's SpellInfo, as it runs on the channel for ticks 1 to 4.
The tick then carries `Dawn` and `DawnCast` itself, the values the copy from the channel gives the earlier ticks.

No harness change (D-83). On the simulated clock the channel's end and the 5th tick land on the same game millisecond
and the players update first, so the scenario forces the late tick by construction: the existing scenario fails
every time without this change and is the regression.

## Consequences

- With Dawn up, a Radiant Flame channel spends exactly five charges, one per tick, whichever comes first in the map
  update: the channel's end or the last tick. The two branches exclude each other, so no tick spends twice.
- `SpendDawn` is unchanged; no `Amount()` call is touched.
- Only Sun Cleric code reads 807058, 806060 and its ranks, and 807440 (class 27 in
  `AscensionSpellProgressionData.h`; the Vow of Grace test in `SpellInfo.cpp` is the class's own). No other class
  is reached.
- Lights of Absolution 807523, copied from the channel to ticks 1 to 4, stays 0 on a late last tick; not in the
  ruling, recorded as an observation.
- Regression: `sun-cleric-radiant-flame-direct-ticks-12951`, step 62 (5 charges left from 10 after 5 ticks) on the
  simulated clock, with a real-clock reference. Control arm: the same exact count, so a double spend would read 4;
  the channel start spends none and Dawn still blocks Solar Power (step 63).
