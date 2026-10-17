# Manastorm Open-World Segment Discovery

**Date:** 2026-10-07  
**Repository:** `Duff-SPP/azerothcore-wotlk-coa-dev`  
**Branch:** `feature/acension-manastorm`

## Purpose

This document preserves the current recovery findings for **Vanilla open-world Manastorm content**: stages that are neither dungeon nor raid encounters, but instead correspond to outdoor Vanilla Azeroth locations.

The important recovery detail is that Ascension did **not** necessarily store these stages with physical Azeroth map IDs `0` (Eastern Kingdoms) or `1` (Kalimdor).

Instead, `Manastorm.dbc` uses custom/native Manastorm map identities such as `1761`, `1762`, `1765`, `1766`, `1767`, `1769`, and `1770`. These native identities must remain preserved for client/native Manastorm identity, while the server can execute the stage on the corresponding physical Vanilla world map.

This is the same architecture already used for Mazthoril / Manaclaw:

```text
native Manastorm identity: map 1770
physical runtime location: Kalimdor map 1
```

## Recovered open-world families

The following are high-confidence Vanilla outdoor Manastorm families recovered from the current `Manastorm.dbc`, `DungeonEncounter.dbc`, `ManastormMessages.dbc`, and imported `manastorm_segment` data.

| Vanilla area | Objective | Native segments | Native Manastorm map | Expected physical world |
|---|---|---|---:|---:|
| Moonbrook, Westfall | Marisa du'Paige | 526 / 527 | 1769 | Eastern Kingdoms (0) |
| Purgation Isle | Justicar Keltraesa | 540 / 541 | 1765 | Eastern Kingdoms (0) |
| Mazthoril, Winterspring | Manaclaw | 411 / 476 | 1770 | Kalimdor (1) |
| Lost Rigger Cove, Tanaris | Andre Firebeard | duplicate native rows exist | 1767 | Kalimdor (1) |
| Ruins of Alterac | Muckrake | 407 / 480 | 1761 | Eastern Kingdoms (0) |
| Tainted Scar: Part I | Grol the Destroyer | 409 / 478 | 1762 | Eastern Kingdoms (0) |
| Tainted Scar: Part II | Archmage Allistarj | 552 / 553 | 1762 | Eastern Kingdoms (0) |
| Altar of Storms, Blasted Lands | Lady Sevine | 554 / 555 | 1762 | Eastern Kingdoms (0) |
| Dark Portal / Blasted Lands | Razelikh the Defiler | 542 / 543 | 1762 | Eastern Kingdoms (0) |
| Dalaran Crater | Corestone of Dalaran | 556 / 557 | 1766 | Eastern Kingdoms (0) |

## Exact recovered segment rows

### Moonbrook / Marisa du'Paige

Recovered imported rows:

```text
526 -> map 1769 -> difficulty 0 -> encounter 5018 -> objective 84270
527 -> map 1769 -> difficulty 2 -> encounter 5020 -> objective 84270
```

The recovered unlock progression explicitly identifies:

```text
Level 5:
Unlocked Moonbrook!
You have unlocked Moonbrook in your next Manastorm!

Level 6:
Moonbrook Unlocked
You have unlocked the Moonbrook map and creatures in future Manastorms!
```

This strongly establishes Moonbrook as an authentic outdoor map/creature Manastorm stage rather than a dungeon.

### Purgation Isle / Justicar Keltraesa

```text
540 -> map 1765 -> difficulty 0 -> encounter 5021 -> objective 84271
541 -> map 1765 -> difficulty 2 -> encounter 5023 -> objective 84271
```

Recovered progression:

```text
Level 35:
Unlocked Purgation Isle!

Level 36:
Purgation Isle Unlocked
You have unlocked the Purgation Isle map and creatures in future Manastorms!
```

### Mazthoril / Manaclaw

```text
411 -> map 1770 -> difficulty 0 -> encounter 5012 -> objective 83859
476 -> map 1770 -> difficulty 2 -> encounter 5014 -> objective 83859
```

This is the first open-world family already partially reconstructed in our current DB:

```text
native map_id = 1770
runtime_map_id = 1
start_game_tele_id = 2041
```

Recovered progression:

```text
Level 38:
Unlocked Mazthoril!

Level 39:
Manaclaw Defeated!
You have unlocked Manaclaw in future Manastorms!
```

### Ruins of Alterac / Muckrake

```text
407 -> map 1761 -> difficulty 0 -> encounter 4994 -> objective 83261
480 -> map 1761 -> difficulty 2 -> encounter 4996 -> objective 83261
```

Recovered progression:

```text
Level 65:
Unlocked Ruins of Alterac!

Level 66:
Muckrake Defeated!
You have unlocked Ruins of Alterac in future Manastorms!
```

### Tainted Scar / Blasted Lands family

Ascension groups several distinct outdoor encounters under native Manastorm map `1762`.

#### Grol the Destroyer

```text
409 -> map 1762 -> difficulty 0 -> encounter 5000 -> objective 83617
478 -> map 1762 -> difficulty 2 -> encounter 5002 -> objective 83617
```

Recovered progression:

```text
Level 70:
Unlocked The Tainted Scar: Part I!

Level 71:
Grol the Destroyer Defeated!
```

#### Archmage Allistarj

```text
552 -> map 1762 -> difficulty 0 -> encounter 5036 -> objective 83618
553 -> map 1762 -> difficulty 2 -> encounter 5038 -> objective 83618
```

Recovered progression introduces:

```text
Unlocked The Tainted Scar: Part II!
```

and later confirms Archmage Allistarj as a persistent boss unlock.

#### Lady Sevine

```text
554 -> map 1762 -> difficulty 0 -> encounter 5045 -> objective 83619
555 -> map 1762 -> difficulty 2 -> encounter 5047 -> objective 83619
```

Recovered progression:

```text
Unlocked the Altar of Storms!

Altar of Storms Unlocked
You have unlocked the Altar of Storms map and creatures in future Manastorms!
```

#### Razelikh the Defiler

```text
542 -> map 1762 -> difficulty 0 -> encounter 5030 -> objective 84272
543 -> map 1762 -> difficulty 2 -> encounter 5032 -> objective 84272
```

Recovered progression:

```text
Unlocked the Dark Portal!

Razelikh the Defiler Defeated!
You have unlocked Razelikh the Defiler in future Manastorms!
```

### Dalaran Crater / Corestone of Dalaran

```text
556 -> map 1766 -> difficulty 0 -> encounter 5051 -> objective 254189
557 -> map 1766 -> difficulty 2 -> encounter 5053 -> objective 254189
```

Recovered progression:

```text
Level 100:
Unlocked Corestone of Dalaran!

Level 101:
Dalaran Crater Unlocked
You have unlocked the Dalaran Crater map and creatures in future Manastorms!
```

## Recovered Ascension-custom outdoor families intentionally deferred

Several additional outdoor Manastorm families are now resolved far enough to preserve their native identities, but their objective creatures are **Ascension-custom creatures that are not present in the current AzerothCore world DB**.

These stages must remain disabled until their original creature data/mechanics are recovered or a faithful reconstruction is authored. Do **not** invent a Vanilla replacement merely to make the segment runnable.

| Family | Normal / Endgame segments | Native map | Native objective | Recovered objective name | Current status |
|---|---:|---:|---:|---|---|
| Grim Marsh | 584 / 585 | 1771 | 254285 | The Witch's Brew | Deferred — custom objective absent from current DB |
| Iskarr Village | 577 / 579 | 1775 | 254295 | Njernthir | Deferred — custom objective absent from current DB |
| Forgotten Mine | 580 / 581 | 1781 | 254272 | Geolord Vek | Deferred — custom objective absent from current DB |

Recovered rows:

```text
Grim Marsh
584 -> map 1771 -> difficulty 0 -> encounter 5072 -> objective 254285
585 -> map 1771 -> difficulty 2 -> encounter 5074 -> objective 254285

Iskarr Village
577 -> map 1775 -> difficulty 0 -> encounter 5066 -> objective 254295
579 -> map 1775 -> difficulty 2 -> encounter 5068 -> objective 254295

Forgotten Mine
580 -> map 1781 -> difficulty 0 -> encounter 5069 -> objective 254272
581 -> map 1781 -> difficulty 2 -> encounter 5071 -> objective 254272
```

The recovered progression messages independently confirm all three as authentic Manastorm outdoor families:

```text
Grim Marsh:
depth 10 -> unlocked in next Manastorm
depth 11 -> Grim Marsh map + creatures enter future Manastorms

Iskarr Village:
depth 18 -> unlocked in next Manastorm
depth 19 -> Iskarr Village map + creatures enter future Manastorms

Forgotten Mine:
depth 48 -> unlocked in next Manastorm
depth 49 -> Forgotten Mine map + creatures enter future Manastorms
```

### Deferred-content rule

For recovered Ascension-custom objectives that are absent from the current DB:

```text
preserve native segment IDs
preserve native map IDs
preserve native objective IDs
keep the stages disabled
document the missing objective
do not substitute an unrelated Vanilla creature
resume only when original data or a faithful reconstruction is available
```

This is the same preservation-first principle used when Purgation Isle / Justicar Keltraesa cannot be mapped to a trustworthy current runtime objective.

## Additional open-world candidates still needing exact resolution

The following recovered non-dungeon families still need their exact physical representation and/or objective mapping resolved before implementation:

```text
Temple of Eternity
Gadgetzan's End
Caer Darrow
Scarlet Mage Tower
Lost Rigger Cove Docks
```

The recovered `manastorm_segment` catalogue also contains additional custom-map rows around maps `1767`, `1768`, `1771`, `1775`, `1776`, `1781`, etc. These should be resolved from `DungeonEncounter.dbc` + `ManastormMessages.dbc` rather than guessed.

### Lost Rigger Cove duplication

Andre Firebeard is confirmed as an outdoor Tanaris Manastorm objective on native map `1767`, but the imported catalogue contains duplicate/equivalent rows for this family.

Do not arbitrarily discard duplicates until the original purpose of each row is understood.

## Important runtime-map representation problem

Current runtime map resolution is:

```cpp
uint32 const runtimeMapId =
    fields[2].Get<uint32>();

segment.MapId =
    runtimeMapId
    ? runtimeMapId
    : segment.NativeMapId;
```

Current schema semantics are therefore:

```text
runtime_map_id = 0
=> no override
=> execute on native map_id
```

This works for Manaclaw because Kalimdor is physical map `1`:

```text
native map 1770
runtime map 1
```

However, **Eastern Kingdoms itself is physical map `0`**.

Therefore the current representation cannot express:

```text
native map 1769
runtime map 0
```

because `0` is currently treated as the sentinel for "no override".

Before enabling Moonbrook and the other Eastern Kingdoms outdoor Manastorm stages, the runtime-map override representation must be adjusted so physical map `0` can be represented explicitly while preserving backwards compatibility for existing rows.

## First restoration target: Moonbrook / Marisa du'Paige

Moonbrook is the recommended first outdoor restoration because its evidence is especially clean.

Recovered native identity:

```text
Normal segment:   526
Endgame segment:  527
Native map:       1769
Native objective: 84270
Normal encounter: 5018
Endgame encounter:5020
```

### Current AzerothCore physical equivalent

Ascension used a duplicate/custom objective entry `84270`.

Our current world database does **not** contain that Ascension duplicate.

The physical Vanilla creature to use is:

```text
Marisa du'Paige
Creature entry: 599
```

Therefore Moonbrook should preserve:

```text
NativeObjectiveCreatureEntry = 84270
```

for recovered/native identity, while using:

```text
runtime_objective_creature_entry = 599
```

for server objective detection.

### User-authored runtime teleport

The physical Moonbrook start teleport is now:

```sql
INSERT INTO `acore_world`.`game_tele`
(`id`, `position_x`, `position_y`, `position_z`, `orientation`, `map`, `name`)
VALUES
(2103, -11242.1, 1473.88, 24.041, 2.57614, 0,
'Manastorm_OpenWorld_Marisadu\'Paige');
```

Runtime target:

```text
game_tele_id = 2103
physical map = 0
objective entry = 599
```

## Moonbrook restoration authored

The first outdoor restoration is now authored in SQL as:

```text
segment 526 / 527
native map_id = 1769
runtime_map_id = 0
runtime_map_override_enabled = 1
native objective = 84270
runtime objective = 599
game_tele = 2103
```

The datastore now uses an explicit runtime-map override enable bit, so physical
Eastern Kingdoms map `0` no longer collides with the historical
`runtime_map_id = 0` "no override" sentinel.

Existing non-zero runtime-map overrides are backfilled as enabled by the
migration, preserving current Manaclaw/Kalimdor behavior.

## Restoration principle

For these outdoor segments, preserve the same split already established elsewhere:

```text
native Manastorm identity
    !=
physical runtime representation
```

Do not rewrite recovered/native DBC identity fields merely because the original Ascension server used duplicate creature entries or custom staging maps.

Instead:

```text
map_id
    = recovered/native Manastorm identity

runtime map
    = physical AzerothCore world map

objective_creature_entry
    = recovered/native Ascension objective identity

runtime_objective_creature_entry
    = physical AzerothCore creature identity
```

This preserves native client compatibility and archaeological fidelity while allowing the restored server to execute the encounter using Vanilla world content.
