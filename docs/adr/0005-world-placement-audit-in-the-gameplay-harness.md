# 0005. Check world placement inside the gameplay harness

- Status: accepted
- Date: 2026-10-26

## Context

Players keep reporting spawns that float, sit under the ground or show no model (design §4, Niveau 2, of the
automated in-game testing plan). Each fix so far moved one row by a position a player read in game. Finding such
rows before players do needs the ground height, the liquid level and the display stores the server uses. They exist
only inside a running worldserver: the `.map` terrain, the vmap models, the DBC stores (file rows plus the `*_dbc`
world tables) and the loaded `creature` and `gameobject` spawns.

## Considered options

1. A harness action and metrics in the in-process gameplay harness (`src/server/coa/CoAGameplayTest.cpp`), with
   the report in the case result.
2. A GM chat command writing a report file.
3. An offline Python tool reading `.map`/`.vmtile` files and the SQL.
4. Azeroth World Editor (AWE) through its MCP server.

## Decision

Option 1. A pure module, `CoAGameplayPlacement`, classifies a sample; the harness feeds it:

- Ground is the static `.map` terrain and vmap height on the spawn's base map (`Map::GetHeight` without the dynamic
  tree, searched 50 yards down from 2 yards above the spawn), so the result is deterministic and independent of
  which grids other lanes loaded. Gameobject models are not ground.
- Verdicts: `grounded`, `floating`, `under_ground`, `exempt` (creatures that may fly or hover, triggers, the hover
  anim tier, swimmers in liquid, objects on a liquid surface, gameobjects without display and transports) and
  `unchecked` (a grid without `.map` or vmap data, or only liquid).
- Metrics return the raw gap; a verdict metric requires the scenario's own `tolerance`.
- A display is known to the client when its id is a record of the `DataDir/dbc` client file, the client set that
  `DBCStores.cpp` enforces. A display only in the server store is reported apart as `server_only_display`, not as
  an anomaly, because the display patch service (`AscensionDisplayPatchService`, `CoA.SendDisplayPatches`) streams
  those rows to clients.
- Spawns that a game event adds (positive event ids in the server's `game_event_creature` and
  `game_event_gameobject` data) are listed apart with their event id, not counted as anomalies: they exist only while
  the event runs and are often hung on buildings or doodads. In Moonglade they are 128 of the 145 rows at 0.8 yards.
- The audit's default tolerance is 0.8 yards, chosen from the Moonglade calibration below.

verify_all integration: the gameplay stage only. Catalog scenarios guard the mechanism
(`placement-metrics-reported-spawns`, and `placement-audit-moonglade`, which asserts only that the audit ran); a zone
audit on demand is an exploratory scenario file (`--scenario <file>`), which ends `INCOMPLETE` by design and never
blocks a PR. No verify_all stage or harness selection is added: the harness stage runs server-less scripts, and a
second server launcher would duplicate the gameplay stage's isolation.

Option 2 adds a command surface and its own output path for what a scenario step already records. Option 3 would
re-implement the map and vmap readers and the SQL loading order of the server, and drift from them. Option 4 is a
visual editor (GPL-3.0) meant for a person; it stays an external check for reported rows and nothing from it enters
the repository.

### Tolerance calibration (Moonglade, 2026-10-26)

An audit of zone 493 on map 1 with tolerance 0.01 yards selected 354 creatures and 495 gameobjects (1 exempt,
0 unchecked, 0 server-only displays, 84 ms):

| Gap band (yards) | Creatures above / below | Gameobjects above / below |
| --- | --- | --- |
| within 0.01 (or exempt) | 9 | 265 |
| 0.01 to 0.1 | 242 / 0 | 9 / 19 |
| 0.1 to 0.25 | 89 / 0 | 5 / 9 |
| 0.25 to 0.5 | 10 / 0 | 2 / 12 |
| 0.5 to 0.75 | 4 / 0 | 2 / 24 |
| 0.75 to 1 | 0 / 0 | 0 / 19 |
| 1 to 2 | 0 / 0 | 26 / 39 |
| 2 to 5 | 0 / 0 | 30 / 5 |
| more than 5 | 0 / 0 | 26 / 3 |

Every creature lies above its ground by at most 0.744 yards (p99 0.481); gameobjects split into rows placed on the
ground and a spread on both sides. The reported defects measured in the placement scenario are 0.830 yards above
(Silk Drape before #9146) and 1.011 yards below (Right Hand of His Majesty before #9176). 0.8 yards sits above every
Moonglade creature gap and below the smallest reported defect; 1.0 would miss the Silk Drape.

The gameobject data do not separate good from bad positions. The Drudger Smash after #8891, a position confirmed
in game on the oil platform deck, measures 0.998 yards above the static ground found under it, so 0.8 flags it as
floating, while the Silk Drape defect measures 0.830. No single tolerance keeps the confirmed Drudger Smash and
catches the Silk Drape: 0.8 trades one false positive for one caught defect, 1.0 the reverse. What that surface
1 yard under the deck is (a lower part of the platform model, or the deck being a gameobject the static data do not
hold) is not established. Three Moonglade signposts also sit at 0.80 to 0.81 yards below their floor, at the edge.
0.8 stays the default because the audit produces a list for triage: a false positive costs one look, a missed
defect stays in the world until a player reports it, and every creature measured so far stays below 0.8. Scenarios
that need another bound pass their own `tolerance`.

## Consequences

- Known limits: a spawn on the wrong floor layer (a cave spawn on the terrain above the cave) reads as grounded; a
  wrong but existing model needs an external reference; positions changed at runtime by scripts or waypoints are not
  read; ground visible in game but absent from map and vmap data is not seen. The Mossy Shortbow fix (#8943) is such
  a case: its pre-fix position reads 0.0 yards from static ground although players saw it 2.3 yards under the
  ground, and its in-game position after the fix reads 4.3 yards above it. On a map without `.map` terrain, a spawn
  more than 48 yards above the floor below it reads `under_ground`, flying creatures included.
- The audit runs in one world tick and creates terrain grids on the base map; a zone of a few hundred spawns takes
  tens of milliseconds.
- No SQL changes; confirmed anomalies are fixed one by one in their own issues, each with a targeted
  `spawn_ground_gap` regression.
