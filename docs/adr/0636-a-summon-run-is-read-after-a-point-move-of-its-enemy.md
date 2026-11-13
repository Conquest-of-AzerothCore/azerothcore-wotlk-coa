# 0636. A summon's run is read after a point move of its enemy

- Status: accepted
- Date: 2026-11-13
- Builds on: ADR 0588, ADR 0604

## Context

Necromancer claim 278.1, Muck Summoner 806086 "summon $806087s1 Rotlings that will run towards the enemy". The event
code summons the Rotlings at the hit target (AscensionNecromancerEvents.cpp:126-127) and `Summon()` places each one
1.5 + 0.5 i yd from it and has it `AttackStart` the target, so a Rotling starts inside melee reach and a stationary
enemy never shows a run (cycle 9 design flag, mentor-approved design `summon_chase`). `owned_creature_distance_2d`
reads a present creature only, and the Rotling explodes 5000 ms after it spawns (807640 Effects[1].Amplitude).

## Options

- Read the Rotling once at spawn against a stationary dummy: it is already in reach; no run is visible.
- Keep a second stationary dummy at the spawn point as the reference: Blight's area hits it too and a Rotling can
  spawn at it.
- Move the enemy after the summons and read the Rotling against it and against the caster.

## Decision

Kind `summon_chase` (kinds/summon_chase.py, no C++). A forcing fixture (ADR 0588) raises the talent's roll. Control:
casts of the trigger at a movable dummy without the talent; no summon may appear. Treatment: a burst of casts with the
talent, then the talent is unlearned and the fixture removed (read gone), so no later summon spawns beside the moved
dummy. The dummy gets a running point move (`move_point`, ADR 0604) of 8 to 20 yd; after a window that ends before the
fuse, a summon must stand within NOMINAL_MELEE_RANGE (5 yd, ObjectDefines.h:47) of the dummy and have moved away
from the caster by at least 0.75 of the yards the dummy did. A dummy that moved less than 0.75 of its order leaves the
verdict unmeasured. The metric is `owned_creature_distance_2d`, an event read (as in `follow_bearing`).

## Consequences

- A summon left where it spawned ends about 10 yd from a dummy moved 12 yd, and alerts.
- Seeded tests in kinds/test_summon_chase.py: a following summon passes; a summon that stays or runs short alerts; a
  summoning control or a forcing fixture left active alerts; no summon or an unmoved enemy is unmeasured; a read past
  the fuse or a move inside melee reach is refused; the verdict is behaviour evidence only through its evidence row.
