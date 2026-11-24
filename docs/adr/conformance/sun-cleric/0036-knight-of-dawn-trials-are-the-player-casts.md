# 0036. Knight of Dawn's trials are the player casts of Glorious Execution

- Status: accepted (incorrect test, row 371, ledger 389; mentor D-220 asked for the cause, 2026-11-22)
- Date: 2026-11-22

## Context

Knight of Dawn 805647: "Your Glorious Execution now has a $h% chance to strike 1 additional time." (ProcChance 20.)
Glorious Execution Rank 6 803913: "Strike with both weapons dealing Weapon Damage plus $s1 Physical damage and
regenerate mana equal to $807451s1% of the damage dealt." Its Effect[0] 142 casts the main-hand strike 800691.

Check case 805647 (`AscensionSunClericEvents.cpp:128`) rolls `Chance(player, 805647)` on each damage event of 800691.
Proc sets `State(player).event` (`:163`) and casts `Highest(player, 800626)` at the target (`:309`). The cast is
instant (CastingTimeIndex 1, Speed 0 for 803913 and 800691), so the extra strike reaches Check while the flag is set
and returns false at `:46`: an extra strike never rolls and never chains.

The diagnostic run 20261122-212422 (4 parts, rank 1 800626) was read as "0 extra strikes in 1174 landed". The 1174 is
the case-cumulative `spell_cast_count` of 800626 (`ProcCounter`, reset only at case start), which counts the player
casts and the extra casts alike, compared with itself. From the same raw counters: 1174 casts in total, 21 baseline
and 968 player casts with the aura, so 185 extra casts in 968 player casts (19.1%). The withdrawn c4 entry counted
every landed 800691 strike as a trial, the extra strikes included (185 in 1153, 16.0%).

## Options

1. Server change at `:46` or `:309`. Rejected: the server already gives about 20% per player cast, with no chaining,
   as the tooltip says ("1 additional time").
2. Trials = landed 800691 strikes (`trigger_spells`). Rejected: counts strikes that cannot roll.
3. Trials = completed player casts of 803913: `trial_casts` with the reading `minus_events` and
   `events_exclude_trigger_casts` (existing options, no tool change).

## Decision

Option 3. The `procs` entry of 805647 in `classes/sun_cleric.json` triggers on 803913 (the level 60 rank, which
`Highest` returns), with a 21-cast baseline arm before the learn as its control.

## Consequences

- No C++, SQL, client text or engine change; no other class's spell is touched.
- The c4 pilot figure (5820 casts, 5820 strikes, 5820 events, raw results no longer on disk) cannot be re-read; it is
  consistent with the same cast-count-against-itself reading.

## Verification

Counted pair at level 60, 20261122-215130 / 20261122-215337 (worldserver 0787d4b36b6d, 121 parts, no flip, no
failed cast): 5826 procs in 29282 player casts (19.90%) and 5832 (19.92%), Wilson 99.95% intervals inside the band
18-22%, no event in the 21 baseline casts of either run. `residual_target` 0.001 with `min_detectable` 4: false alert
at the chance 7.74e-07 per pair.
