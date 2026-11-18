# 1011. Zealotry hits proc Libram of Consecration; auto attacks still do not

- Status: accepted
- Date: 2026-11-18

## Context

Libram of Consecration 801441, 803890-803893 reads "causing damaging abilities to deal an additional Holy damage to
your target and 4 nearby enemies for $d". Its proc, `aura_ascension_templar_event` (`AscensionTemplarEvents.cpp`),
casts 804148 on a damaging, non-periodic hit that passes `Ability()`. Zealotry 801450 was excluded in three places:

- `Ability()` (`AscensionTemplar.cpp`) rejects every spell listed in `Derived()`, and 801450 is on that list;
- `Check` returns early for any `Derived()` spell;
- `Check` also returns early while another Templar event is in its `Proc` (`State(player).event`). The Level 10
  passive Zealotry 92108 casts Zealotry from inside its own `Proc` when an off-hand auto attack hits. The cast is
  triggered and has no travel time, so its hit is processed inside that `Proc` (`Spell::prepare` with
  `TRIGGERED_CAST_DIRECTLY`, then `handle_immediate`).

Issue #12670 reports a 1 s internal cooldown. Our data has none: `spell_proc` 803893 has Cooldown 0, and the script
keeps no timer for it (`.agents/plans/templar-followup/determined-libram.md`). Live combat logs
(`~/Projects/coa-log-history`, isolated hits followed by an 804148 proc within 150 ms) show 256 of 281 Zealotry hits
and 0 of 160 auto attack swings proccing it. The owner ruled on 2026-11-18 that Zealotry damage triggers the Libram's
extra Holy damage and that auto attacks do not.

## Options

- Remove 801450 from `Derived()`. Rejected: every Templar event that excludes derived damage would change with it
  (Deliverance, Uther, the other Librams and more).
- An exception for Zealotry, for the Libram of Consecration ranks only, at the three exclusion points. Chosen.

## Decision

`Check` computes `consecratedZealotry`: the aura is a Libram of Consecration rank (801441, 803890-803893) and the hit
is Zealotry 801450. Such a hit passes the event guard and the `Derived()` exclusion, and the Libram case accepts it
next to `Ability()`. The other Librams and events are unchanged. Auto attacks still fail `Ability()` (they have no
`SpellInfo`), so a swing never procs the Libram.

The proc's own cast, 804148, is a `Derived()` spell and casts no Zealotry. Letting Zealotry through the guard
therefore adds no recursion.

## Consequences

- Regression: `templar-libram-of-consecration-repeated-procs`:
  - under one Libram buff, five Holy Cleave 573049 hits give five 804148 hits;
  - under the same buff, five direct Zealotry casts 1000 ms apart give five;
  - under a fresh buff (the old one removed and its absence asserted), auto attack with both hands and without
    92108 gives no 804148 hit;
  - under another fresh buff, with 92108 and auto attack, the 804148 hits equal the Zealotry hits from off-hand
    swings.
- The scenario spaces the Holy Cleave arm 1300 ms apart. Holy Cleave's own global cooldown is 1250 ms
  (StartRecoveryTime 1250, category 133, melee class, so `Spell::TriggerGlobalCooldown` applies no haste), and the
  scenario asserts it. A second Holy Cleave submitted 1000 ms after the first therefore cannot execute immediately.
  With `SpellQueue.Enabled = 1` and `SpellQueue.Window = 400` in `worldserver.conf.dist` it may instead be queued
  until the global cooldown ends; the scenario waits 1300 ms and does not establish whether it is refused or queued.
  This is engine behaviour, not a Libram cooldown, and is recorded as an observation for #12670. It was not measured
  on a client.
- Zealotry from Sermon repeats, Condemnation 706325, One With The Light 504807 and Oath: Vindication also reaches
  the Libram now. The regression covers only the direct cast and the 92108 path.
- Not changed: other derived Templar damage, such as Scourgebane 801832, which live logs did not single out.
