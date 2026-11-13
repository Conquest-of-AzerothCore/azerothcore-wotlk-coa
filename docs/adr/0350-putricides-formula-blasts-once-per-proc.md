# 0350. Putricide's Formula blasts once per proc

- Status: accepted
- Date: 2026-11-13

## Context

Putricide's Formula 707001 / 707882: "Damage dealt by Undead minions has a $h% chance to blast up to $707002i nearby
enemies". $707002i is 707002's MaxAffectedTargets, 3. The proc cast 707002 at up to Amount(707001) = 2 nearby enemies
(AscensionNecromancerEvents.cpp), and 707002 is itself an area spell (Effect[0] TargetA 6 TARGET_UNIT_TARGET_ENEMY,
TargetB 16 TARGET_UNIT_DEST_AREA_ENEMY, MaxAffectedTargets 3). With four dummies one proc blasted 6 to 8 of them
(diagnostic 20261113-003226: 23 procs, 6 x11, 7 x10, 8 x2). Fix note F-route-1, approved by the mentor (G-37).

## Options

- Cast 707002 once at the hit target, no data change.
- That, plus a contract on 707002 so the explicit target is not added on top of the area's 3.
- Keep the loop with a cap of 3 single-target blasts (a contract clearing TargetB).

## Decision

The smallest design first. A single cast at the hit target still blasted 4 distinct dummies in 4 of 26 procs
(diagnostic 20261113-013620: the explicit target plus 3 from the area), so `AscensionNecromancerContracts.cpp` also
sets 707002 Effect[0] TargetA to TARGET_DEST_TARGET_ENEMY (the area is centred on the target, as Starcaller's
contracts do), and MaxAffectedTargets 3 alone picks the enemies. No "N in all" ruling is applied.

## Consequences

- With both changes, 23 of 23 procs blasted exactly 3 distinct dummies of four (diagnostic 20261113-013932).
- One proc no longer blasts at most 2 enemies on a single-enemy pull and up to 8 on a pack: it blasts up to 3.
- The proc chance and 707002's amount are unchanged; the Necromancer proc rate entries stay the regression.
