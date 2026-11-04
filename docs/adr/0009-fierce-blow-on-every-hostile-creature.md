# 0009. Give every hostile creature Ascension's Fierce Blow, one owner per creature

- Status: accepted
- Date: 2026-11-03

## Context

On Ascension every hostile creature that meleed a player used Fierce Blow (975011). CoA tank kits were balanced
with it in place (community discussion "Fierce Blows mechanic missing from bosses", 2026-11-01). This fork cast
975011 only from about 52 sources: boss kit rows in `coa_dungeon_boss_kit`, SmartAI rows, `coa_boss_schedule`,
and C++ boss and trash scripts. Ordinary trash and most bosses never used it.

Evidence from the archived Ascension combat logs (186 logs, May-August 2026, 38,650 Fierce Blow events on players):

- 206 of the 207 creatures with at least 100 swings on players used it, trash and open-world mobs included. Pets
  were hit as well (169 events).
- It follows the clock, not the swing count. 10% of the intervals are under 6.2 s, the median is 7.9 s and the
  upper quartile 9.55 s. Across 145 creatures the per-creature median stays near 8 s whatever the swing speed:
  correlation 0.11 with swing speed, -0.81 for the number of white swings between two Fierce Blows. The
  community descriptions of a 33/66/100% roll per swing or per 3 s do not match these intervals.
- No Fierce Blow was dodged, parried or missed (white swings: 44,803 dodges). Blocks and absorbs both happened,
  including 4,059 fully absorbed blows, so there is no shield piercing.
- Its unmitigated, noncritical damage equals a white swing from the same creature on the same target: median ratio
  1.00, middle half 0.96-1.06. That is what the spell's 100% Weapon Percent Damage effect gives.
- Baron Geddon, Ragnaros and the Sons of Flame used Fierce Fire Strike instead of 975011.

The spell already carries `SPELL_ATTR7_NO_ATTACK_DODGE/PARRY/MISS` and `SPELL_ATTR0_ON_NEXT_SWING_NO_DAMAGE` in
both the server and client DBC.

Two engine facts constrain the design:

- An untriggered next-swing cast waits in `CURRENT_MELEE_SPELL` until the next swing.
- Queueing a second one interrupts the first through `Unit::InterruptSpell`, which calls `AI()->OnSpellFailed`.
  Several boss scripts answer that by recasting their own Fierce Blow.

A creature therefore must never get Fierce Blow from two sources.

## Considered options

1. Add 975011 to every creature's SmartAI or kit data. That means thousands of rows, does not cover creatures
   with C++ AI, and every new spawn needs its own row.
2. Move every existing source to one generic scheduler. That rewrites about 52 tuned sources, including the Molten
   Core windows calibrated from the same logs, and their scenarios.
3. A generic scheduler for creatures that have no Fierce Blow of their own. Existing sources keep their own timing.

## Decision

Option 3, in `src/server/coa/CoAFierceBlow.cpp`, behind `CoA.FierceBlow.Enable` (default 1).

- **Scheduler.** An `AllCreatureScript` update hook gives a creature in combat with a player or a player's unit one
  untriggered Fierce Blow 6-9.5 s after the engagement, and again 6-9.5 s after each one. The blow takes the place
  of the next melee swing. An engagement is a gap of more than 1 s beyond the update's own diff since the last
  eligible update, so slow server ticks do not restart the timer.
- **Skipped creatures.** Totems, triggers and player-controlled creatures never get it, and neither do creatures
  that are already casting or out of melee range. A creature that already has a melee spell queued is skipped too.
- **Ownership.** A creature has one owner for its Fierce Blow:
  - At startup the entries that cast 975011 from SmartAI (actions 11 and 218, by entry or through timed action
    lists), `coa_dungeon_boss_kit` or `coa_boss_schedule` are loaded as self-scheduled. SmartAI rows keyed by a
    spawn guid exclude only that spawn, not its whole template. The scheduler skips them.
  - An `AllSpellScript::CanPrepare` hook marks any creature that prepares a Fierce Blow outside the scheduler as
    self-scheduled, so C++ scripts take over the first time they cast one.
  - If the scheduler's blow is still pending at that moment, the script's blow is refused. One blow lands and
    `OnSpellFailed` is not triggered.
  - A creature with a C++ script waits 20-23.5 s for its first scheduled blow, so these scripts identify
    themselves before the scheduler fires. The latest first-cast timer found in the reviewed scripts is Garr's,
    up to 17 s; not every script's timer was audited. A script whose first blow comes later can land one extra
    blow next to the scheduler's, once per creature.

## Consequences

- Every melee creature now produces unavoidable physical damage spikes every 6-9.5 s, as on Ascension. Dodge and
  parry no longer stop all of a creature's melee damage. Block, absorbs, armor and damage reduction still apply.
- Existing damage rules for 975011 keep applying to the new casts: the Normal-dungeon scaling and cap in
  `CoADungeonNormal` and the Vaults rewrite on maps 936 and 937.
- C++-scripted creatures without a Fierce Blow of their own get their first one about 20 s into the fight rather
  than after 6-9.5 s.
- Entries that gain a SmartAI or kit Fierce Blow at runtime without a restart are still covered by the
  `CanPrepare` marking.
- Fierce Fire Strike for Baron Geddon and Ragnaros is a separate change. Sons of Flame already have it.
- Rollback: set `CoA.FierceBlow.Enable = 0`. No data migration is involved.
