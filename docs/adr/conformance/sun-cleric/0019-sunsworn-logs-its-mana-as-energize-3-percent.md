# 0019. Sunsworn logs its auto attack mana as Energize 3%

- Status: accepted
- Date: 2026-11-22

## Context

Sunsworn 802935, Spell.dbc text: "Increases your Physical damage dealt by $s1% and auto attacks now have a $h% chance
to restore $504619s1% of your maximum mana." 802935 has ProcChance 10, and its effect 1 (aura 42) has
EffectTriggerSpell 504619 "Energize 3%". That is the only DBC link to 504619. 504619 is Effect 137 with BasePoints 2
and DieSides 1, so 3%, and AttributesEx 1024 (`SPELL_ATTR1_NO_THREAT`).

The proc is scripted (`AscensionSunClericEvents.cpp`, `case 802935`). It restores `CalculatePct(max mana,
Amount(504619))` through `Mana()`, whose default source is 504877 "Vow of Grace" (`AscensionSunCleric.h`). 504877 is
Effect 30 with AttributesEx 0. Each Sunsworn proc therefore:
- sent its SPELL_ENERGIZE log as Vow of Grace;
- generated threat. `Unit::EnergizeBySpell` calls `ThreatManager::ForwardThreatForAssistingMe` with 0.5 threat per
  point. That call returns early only for a spell with `SPELL_ATTR1_NO_THREAT` (`ThreatManager.cpp`), or for a player
  who `GainsManaWithoutThreat` (auras 681330, 504786 or 801145, none of them a Sun Cleric aura).

Measured in batch 6 chunk a3 (diagnostic `coa-verify` run 20261122-045118, 40 swings per hand): 8 energize events
of 504877 at 86 mana each, and none queried under 504619. Counted pair of the class's Sunsworn entries before this
change: 20261122-045517 / 20261122-045553 (build b3e613641105). The tooltip states no source spell, so the expectation
rests on live evidence (mentor decision D-93, criterion 1).

Live combat logs (coa-history, 186 logs, 2026-07-12 to 2026-08-23), SPELL_ENERGIZE from players:
- under 504619: 2922 events in 12 logs from 6 players, mean 121 mana;
- under 504877: 2365 events in 14 logs from 9 players, over the same dates. Vow of Grace's own restore also logs as
  504877;
- 2 players show both ids in one log.

## Options

- Keep 504877. The amount and the rate stay correct, but the log names the wrong spell and each proc adds threat.
- Pass 504619 as the energize source in `case 802935` only. `Mana()`'s default stays, so every other caller, Vow of
  Grace included, keeps 504877.

## Decision

The second option (mentor decision D-93, 2026-11-22). The amount is unchanged: it is still read from `Amount(504619)`.

## Consequences

- Sunsworn's mana now appears in the combat log as Energize 3% 504619, as it does on live.
- Sunsworn's mana no longer generates threat, because 504619 carries `SPELL_ATTR1_NO_THREAT`. Before this change, each
  proc added 0.5 threat per point of mana to every creature the cleric threatened (code reading of
  `Unit::EnergizeBySpell`). The regression measures this as a ratio against a control.
- Nothing else reads 504619: no other code, SQL or class file, and no other DBC link. 802935 is a Sun Cleric spell.
  Vow of Grace and the other `Mana()` callers keep 504877.
- Regression: `apps/coa-gameplay-test/scenarios/sun-cleric-sunsworn-mana-source-504619.json`, at level 60, has a
  treatment that knows Sunsworn and a control that does not. The treatment logs at least three 504619 events and no
  504877 event. Each event is 3% of maximum mana, floored. The control logs no 504619 event. The treatment's threat
  per melee damage matches the control's within 0.5%. 504877's threat would raise that ratio by at least 1%, and a
  SETUP assertion checks that bound.
- Clause 312's rate and amount stay without a status. The `procs` kind divides the events of both hands by the
  main-hand trials (batch 6 chunk a3, tool need 1).
