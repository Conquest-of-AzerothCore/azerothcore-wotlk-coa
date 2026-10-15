# mod-worldforged-pickups

Worldforged items are picked up off the ground on CoA: a pouch, a bucket, a pile of bones, a
packet, a crate - a world object **named after the base item it holds**. Every character may
open each one **once per prestige cycle**; it is spent for that character until a successful
Chromie prestige resets that character's pickup ledger. Existing items stay in the inventory,
and item equip requirements are unchanged. This follows the player reports in
[CoA Worldforged recovery](https://www.reddit.com/r/ProjectAscension/comments/1vyu132/coa_worldforged_recovery/),
which describe prestiging and leveling again to recover the pickups.

The objects themselves are data, restored by this module's
`data/sql/db-world/2026_09_16_00_worldforged_pickups.sql`,
`data/sql/db-world/2026_09_22_00_worldforged_pickup_spawns.sql`,
`data/sql/db-world/2026_09_22_01_worldforged_missing_pickups.sql`,
`data/sql/db-world/2026_09_22_02_worldforged_crossrealm_spawns.sql`,
`data/sql/db-world/2026_09_22_03_worldforged_appearance_and_ground.sql`,
`data/sql/db-world/2026_09_23_02_worldforged_appearance_records.sql` and
`data/sql/db-world/2026_09_23_03_worldforged_positions.sql`: **1,742 pickups,
each holding exactly its own base item, their appearance read from Ascension's own records
and their places checked against the position the Exiles database publishes for every base
item**. Later passes restore the realm's own objects that this world never
carried, one zone at a time - the Redridge chest (`2026_09_23_14_worldforged_redridge_mountains.sql`),
three in Dun Morogh (`2026_09_23_16_worldforged_dun_morogh.sql`) and four in Searing Gorge
(`2026_09_23_19_worldforged_searing_gorge.sql`). The tenth pass, `data/sql/db-world/2026_09_23_05_worldforged_map.sql` with
`2026_09_23_06_worldforged_recorded_heights.sql` and
`2026_09_23_07_worldforged_spare_spawns.sql`, then stands the world on the placements the
realm map itself records, and on nothing else - see that pass below. What data cannot express
- *who* has already looted *which* pickup - is this module.

## What it restores

| | |
| --- | --- |
| Objects | 1,745 pickup templates: 1,556 in the realm's own catalog ids, 184 created for the items no object held, 2 that the client's own cache holds and the catalog pass missed, 1 that the Redridge pass restores as its own marker names it |
| Spawns | 2,469 placements standing over the four continent maps, from the realm map's own 2,480 placements (the tenth pass), plus Elwynn's two objects the realm had never had, less the placings the marker-by-marker passes removed, plus the one the Redridge pass restored; 1,577 pickup objects stand somewhere, one visible companion prop among them |
| Items | every pickup holds the one item its own name and the realm's catalog say it holds, at 100% |
| Placement | the realm map's own marker for each pickup, in the zone it plots it in, with the height the client recorded for it |
| Rule | one open per character per prestige cycle, then inert for that character until prestige |
| Discovery | an unspent pickup sparkles for the character who can still loot it |

Nothing is invented: every template field is a captured value, every loot row is the realm
catalog's own row, and every position is an observed position.

### The second pass: what the first one could not place

The first pass placed each pickup **once**, at the single example position it holds, and only
from the community's zone dumps - which cover the open world, one file per zone. That leaves
three gaps, all three closed by `2026_09_22_00_worldforged_pickup_spawns.sql`:

| | |
| --- | --- |
| Zones | one spawn per object, not one per object per zone: a pickup seen in nine zones stood in one |
| Maps | seven pickups came from the two region dumps, whose map id is a fallback and was wrong; each is corrected to the Kalimdor zone dump that records the same object at the same coordinates |
| Everything else | dungeons, mines, caves, starter sub-zones and TBC zones have no zone dump at all. The archive's pins reach inside them: a pin carries the object's own world XYZ and its map |
| One object | the pickup holding `Adventurer's Lost Sack` (1450513) never existed - no catalog loot row, so nothing pointed at it. Its template comes from the client cache, field for field |

Evidence for the second pass, and what it covers:

* **5,147 CoA pins**, 4,159 of them on an item this restoration hands out. Before the second
  pass 2,119 (51%) had a pickup within 30 yd; after it **4,154 (99.9%)** do. The five that
  remain are each 30-44 yd from a spawn of the same object - the same pickup seen slightly off.
* Where both corpora hold the same object they agree to a **median 27 yd**, so a pin with no
  spawn within 30 yd is a position nothing else records.
* Heights: a pin carries X and Y only. A pin takes the height of a dump row of the same
  object within 60 yd when there is one, otherwise the height of the nearest object the realm
  already has on that map (2,136 rows, none left without a neighbour).
* No object is placed twice: a copy is added only where no spawn of the same object already
  stands on that map within 30 yd.
* `zoneId`/`areaId` stay `0` on both passes; the zone is recorded in the row's `Comment`, the
  way the first pass records it.

### The third pass: the items no object hands out

The first two passes restore the pickups the realm's catalog knows - an object, the item its
loot row names, and a position. An item that never got an object has no pickup at all,
however often the community recorded it on the ground. Discounting the tiered copies of items
already placed, **184 such items** remain, and every one of them is pinned on Conquest of
Azeroth with the zone, the map and the position it was looted at. They are created by
`2026_09_22_01_worldforged_missing_pickups.sql`:

| | |
| --- | --- |
| Objects | 184 templates in their own entry range (1345000+), named after the item they hold, carrying the appearance the catalog records for that object where it has one and otherwise the appearance this restoration already gives an item of the same class and subclass, with the size and the lock every other pickup uses |
| Loot | one row each, at 100%, the item and nothing else - none of those 184 items is in any creature loot, reference loot, vendor list or quest reward |
| Spawns | 461, one per pinned zone, at the pin's own X/Y in the pin's own map, with the height of the nearest object the realm already has on that map |
| Scrolls | the 14 `Worldforged Scroll:` items are included; the `Mystic Scroll:` family is deliberately not - it is a separate family with nothing tying it to a pickup object |

### The fourth pass: the pickups recorded on the other realms

The first three passes read the archive's pins through a filter that kept only the pins
recorded on Conquest of Azeroth. Of the archive's 5,264 worldforged pins, 117 are not on a
CoA realm but on Area 52, Darkmoon, Dawnrise or Bronzebeard - the same pickups, the same
world coordinates, the same item ids, the same zones. `
2026_09_22_02_worldforged_crossrealm_spawns.sql` closes what that filter cost:

| | |
| --- | --- |
| Positions | 74 recorded positions on 67 pickups the realm already had, each one a place no spawn stands within 30 yd |
| Objects | 2 pickups that are real templates in the client's gameobject cache and had no object at all: `254156 Ancient Furbolg Totem` (holds 354068 `Totem of the Vale`) and `254193 Broken Highborne Lamp` (holds 354096 `Light of the Highborne`). Both rows are the cache's own, field for field - type, display, size, lock and Data fields |
| Effect | `Arkonite Orb` (254255) went from no position to its five recorded ones: Ammen Vale, Azuremyst Isle, Coldridge Pass, Dun Morogh and Elwynn Forest |

What the four passes together could not place, and will not invent: **27 objects stand in the
realm's catalog with a loot row and no position anywhere in the evidence** - 21 whose only
recorded positions were never recorded at all, and 6 whose only recorded position lay in deep
water and was removed by the fifth pass, below - no archive pin on
any realm, no LootCollector sighting, no row in the community's zone dumps, no entry in the
object catalogue, nothing in the client cache. They are named, they hold an item, and nothing
records where they stood, so they are left as they are rather than moved to a guess.

### The fifth pass: what each pickup looks like, and the ground it stands on

Two defects the first four passes left behind, both fixed by
`2026_09_22_03_worldforged_appearance_and_ground.sql`.

**Appearance.** 381 of the 1,742 templates carried `displayId = 980926`, which the client's own
`GameObjectDisplayInfo.dbc` resolves to `world\Generic\DOODADS\invisible_cube.mdx` - a
placeholder. In the world such a pickup was a bare sparkle with no prop. Each of the 381 now
shows a real model, taken from the archive's own captures and never invented:

| | | |
| --- | --- | --- |
| 152 | the exact name | the model the realm uses for an object of that name (a crate, a sack, a corpse), at that captured row's size |
| 76 | the prop word in the name | the model the realm uses for that word - a sack, a corpse, a ring, a totem, a fragment, a scrap, a bracer |
| 139 | the item's kind | the model the realm's own visible pickups use for an item of the same class and subclass (a necklace, boots, a bag, a gun rack) |
| 14 | neither | the treasure chest the realm uses for its containers (`259`, size 1.00) |

Every chosen id resolves to a real model in the client's own table, none is the placeholder,
no size falls outside 0.6-1.5, and the result uses 156 distinct models across the 381 objects.

**Height.** A pickups' position was recorded as X and Y only: a pin marks where a player stood
when the loot window opened. The first pass took its heights from the community's zone dumps,
which record the object's own stored height - 26% of those are interiors or structures the
terrain surface sits far above, so they are already right and are left exactly as they are.
Every later pass derived its height from whatever object stood nearest on that map, which left
1,465 of the 4,346 placements more than 10 yd off the ground - floating, or buried.

First, **230 placements whose recorded position lies in deep water are removed**. A pin is a
player's position when a loot window opened, and on those the pin's own coordinates land 50 to
500 yd below sea level, in ocean, with a zone on the pin that is a different zone from where
the coordinates fall - the position was never usable, and a pickup there was a sparkle over
open water. 162 of the 168 objects involved keep their other placements; the remaining 6 keep
none, as 21 already do.

Each of the 2,606 remaining later placements now takes its height from:

| | |
| --- | --- |
| 126 | a first-pass placement of the same object within 60 yd - the very row the second pass took its height from, so those heights are measured |
| 843 | the closest object the realm itself placed within 25 yd: the terrain surface for 626 of them, the floor the object stands on for 217 (a mine, a cellar, a pier, a room) |
| 1,571 | the terrain surface the worldserver itself reads (`maps/*.map`, the same `GridTerrainData::getHeight` call the core makes), where nothing is close enough to say |
| 24 | the only floor the realm placed, where the map has no terrain surface at all |
| 42 | unchanged: neither a surface nor anything nearby |

2,264 of them move. The rule was measured, not assumed. Run against the 1,510 first-pass
heights - the only independent ground truth in the data - it reproduces 67% within 2 yd and
79% within 5 yd, better than the eight other variants tried, including "always the terrain
surface" (64% and 74%). After the migration, the later placements sit a median 0.00 yd from
the terrain where a surface exists, 89% within 2 yd, and the 7% that sit further out are the
interiors and structures the floor rule deliberately keeps.

### The sixth pass: the rows the realm's own occupants disagree with

`2026_09_22_04_worldforged_ground_refine.sql` re-reads every one of the 4,116 placements
against every occupant of the world - the 95,665 authored objects and the 194,914 creatures it
has always had - and corrects the ones the fifth pass could not settle. 69 rows move:

| | |
| --- | --- |
| 34 | three or more objects or creatures stand within 15 yd, agree with each other to within 20 yd, and their median differs from the row by more than 5 yd: the row takes that median, which is the floor of the room, cave or terrace the pickup was looted on |
| 35 | nothing at all stands within 15 yd and the row hangs between 8 and 40 yd above the terrain: it floats in open air and takes the terrain |

The rows that stand far from both the surface and any occupant and match neither rule are
left exactly as recorded. Above a heightfield, a row more than 40 yd up is far more likely to
be standing on a structure the surface cannot see - a tree-city, a pier, a canopy - than to
hover, and a row below the terrain with nothing near it is what a cave, a mine or an
undercroft looks like from above. Neither is moved on a guess.

### The seventh pass: off the plane a map does not have

`2026_09_22_05_worldforged_noheight_terrain.sql` deals with the rows that have no height of
their own at all - and with a trap in the map files. A tile can carry one constant height for
a whole grid instead of a surface (`MAP_HEIGHT_NO_HEIGHT`): `0` across an interior map such as
Scarlet Monastery or Razorfen Downs, the `-500` sentinel on a continent grid with no terrain
under it. The core uses that constant as a fallback, so a pickup parked on it still loads - it
simply stands on a plane the map does not have, which is to say underground and out of sight.
61 rows:

| | |
| --- | --- |
| 43 | sat on such a plane - 39 of them in Scarlet Monastery, 2 in Shadowfang Keep, 1 in Razorfen Downs, 1 in Eversong Woods - and take back the height the pass that created them recorded |
| 15 | were left at exactly `0`, the number a generator writes when nothing gave it a height, and take the terrain surface |
| 2 | were left at exactly `0` and take the height their creating pass recorded |
| 1 | a row the sixth pass moved to a height this reading does not support, put back |

4 rows stay at `0` and cannot be helped: they are the Blackrock Caverns pickups, and that map
has no tiles extracted in this repack and no creature or object of any kind standing on it, so
nothing in the realm can say where its floor is. They are named here rather than moved to a
guess.

After all seven passes: **3,498 placements stand on the terrain, 255 on a floor the realm's own
occupants define, and 363 are left with the height the data gives them - interiors, structures,
and the four rows above.**

### The appearance, checked against the client itself

Every display id any pickup uses - **1,072 distinct ids** - was checked against the client's
own `GameObjectDisplayInfo.dbc` and against the model file behind it in the client's archive
chain (the tables name models `.mdx`, the archives hold them as `.m2`): **0 ids are unknown to
the client and 0 resolve to a model that is not in the archives.** No pickup carries
`displayId = 0` or the `980926` placeholder.

### The eighth pass: the appearance and the places Ascension itself records

The seven passes above filled the appearance from the shape of a name and from the item a
pickup holds - reasoned guesses, and several of them were wrong in ways a player notices at
the first click: a pair of bracers standing as a treasure chest, more than one object in the
same zone wearing the same prop. This pass replaces every one of those with a record, and
adds the placements the Exiles database documents. Two migrations:

| File | What it settles |
| --- | --- |
| `2026_09_23_02_worldforged_appearance_records.sql` | the appearance of all 1,721 spawned objects - the final value, not a diff |
| `2026_09_23_03_worldforged_positions.sql` | the heights, the facings, 142 placements no earlier migration defined, and 198 the community recorded looting |

#### What was decoded for it

| Corpus | Size | What it gives |
| --- | --- | --- |
| the client's own `gameobjectcache` | 74 distinct caches across the realms and modes, union **14,290 object definitions** | the server's own `SMSG_GAMEOBJECT_QUERY_RESPONSE`: entry, type, display, size, `Data[]`. All **167,507 records decoded consume exactly their declared record size**, so the field layout is proved rather than assumed |
| the archive's `gameobject` collection | 174,539 rows | the same records, over more realms and capture dates |
| the archive's `world-object` catalogue | **7,651 objects**, a display for 7,358, an example position for 7,626 | the community dumps, folded by object id - what the realm has, and one worked place for each |
| Coin's GameObject dumps | 8,165 objects, 9,340 CSV rows and 26,151 TXT rows | a real map id plus the object's own position and stored height, and the DisplayId the dumper read |
| the Exiles database | 1,688 of the 1,703 base items behind these objects | the item's AtlasLoot provenance - `Silithus (63, 56)` - and, where AtlasLoot names one, the object it is found at |

The two independent display corpora agree wherever both describe the same object: **427 of
428**. The one disagreement is `Sack of Defias Gear`, by a single id.

#### The appearance, tier by tier

An object is given an appearance only from a record of it or of something Ascension gives the
same name. Where none exists it keeps the value it already ships, rather than taking another
guess.

| | | Tier |
| --- | --- | --- |
| 1,323 | the object's own record in the client cache | A |
| 12 | the object's own record in the archive | B |
| 134 | the dump catalogue's sighting of an object with that exact name | C |
| 22 | another entry Ascension gives the same name, and that entry's own record | D |
| 27 | the object the Exiles database names as the source of the item it drops, then C or D for it | E |
| 203 | no record in any corpus: the value it already ships, unchanged | - |

**60 objects change.** 23 of them were carrying a model a different zone also used, which is
the visible half of the complaint: `Blackrock Armor Supplies` and eight others shared one crate,
`Nightwatch Circlet` and `Stolen Rot Hide Circlet` shared one ring, and `Abandoned Supplies`,
`Warmonger's Supplies` and `Dark Iron Supplies` shared a third. The Exiles tier is what names
the props for the objects created in the third pass: `Duskwither Hatchet` is the `Ether-Touched
Axe`, `Spellribbon Wand` is the `Disused Wand`, `Silt Shore Hammer` is the `Buried Hammer`,
`Mystwood Glaive` is the `Flowering Glaive`.

Scale follows the object's *own* record only, and only where the stated scale is one an object
can be drawn at (0.2 to 5.0): a same-named neighbour's scale describes a different prop, and
the dump catalogue carries values such as 0.04 which would render a pickup invisible.

**The 203 with no record are named in `.scratch` evidence, not here**: they are objects whose
name exists in no client cache, no archive collection and no dump, so no source can say how
Ascension drew them. They keep the appearance the earlier passes gave them.

#### The places

The Exiles database publishes, for the base item behind each object, the zone and map position
AtlasLoot records. Read as server coordinates through the client's own `WorldMapArea` bounds
(the reader reproduces the realm's own reference point - item 132418 in Razorfen Kraul at map
(0.1273, 0.3504) is `2178.0, 1965.2`, which the realm's pins independently measured):

* **1,202 objects already stand within 25 yd of it, and 1,430 within 60 yd** - the positions
the captures found are the positions Ascension documents, which is why most of them do not
move.
* **142 objects have no placement within 60 yd** of it on that map, and gain one there. This
is additive: nothing is moved and nothing is removed, so no place a capture recorded is lost.
These 142 had been written straight into the database by an earlier pass and had no migration
behind them; the file now carries them, so a fresh database has them too.

#### The places the community recorded looting at

The realm's loot records hold **7,156 positions** across its realms and modes, for 2,537 of the
items behind these objects. A pin is where the looter stood, so one a few yards from a
placement that already exists says nothing and is left out; where the restoration has the
object nowhere on that map, or nothing within 150 yd of the pin, the pin becomes a placement -
**198 added**, of which 49 are in Un'Goro Crater, 30 in Maraudon, 17 in Gnomeregan, 14 in
Wailing Caverns, 11 in Molten Core and 10 in Magisters' Terrace. Additive: nothing is moved and
nothing is removed.

#### The heights, and what a height may be taken from

A community loot pin records where a player stood - X and Y only, no height at all. So does an
AtlasLoot coordinate. Every added placement therefore takes its height from what a player
actually meets at that spot, in order: the median height of the realm's own occupants
(creatures and objects already spawned) within 80 yd, then within 200 yd, then the terrain
surface the worldserver itself reads, then a realm dump of that same object nearby - a
collector's eye level, the weakest of these for a placement. **No witness at all means no
placement is added: 17 of the 238 recorded positions are left out for that reason and are
named in the evidence rather than stood on a guess.**

Two findings about the terrain, both of which had produced pickups a player could see were
wrong:

* this map set has tiles the converter never filled, and they carry a stand-in height with no
  flag to mark them - `-500` on the continents. Read as ground, that is how a pickup ends up a
  few hundred yards under the world. A tile whose value is that stand-in is now reported as
  unknown instead.
* where the extract's own surface disagrees with everything the realm has within 200 yd of it
  by more than 40 yd, the extract is the one that is wrong (Blackrock Mountain reads 782 where
  its occupants stand at 172 to 286; the Ebon Hold floats 250 yd over the Eastern Plaguelands,
  so a height nothing local shares is the tell). **90 placements were standing on nothing** -
  no prop or creature within 80 yd within 60 yd of their height - and now take the floor their
  neighbours share.

#### The facing

The first pass wrote the orientation each placement was recorded with. The ones added later
carried none, which draws them all facing north. Where another placement of the same object
carries a recorded orientation, it is copied along with its quaternion: **401 placements gain a
facing**, and the 12 whose object has no other placement keep what they had.

#### How the numbers were checked

* the terrain reader against a recorded height: the dump catalogue puts `Old Lion Statue` at
  `-9253.08, -3404.90, 104.348`; the reader returns `105.52` for that spot. Its axis order is
  validated against the realm's own authored spawns: 1,216 sampled objects land within 2 yd of
  the reader's surface at the median, and the transposed reading is 104 yd out.
* the appearance statement is the *final* value for all 1,721 spawned objects, so a fresh
  database and this one cannot diverge however the earlier migrations are re-run.
* the worldserver boot after the migrations reads `Loaded 101092 Gameobjects` against
  `SELECT COUNT(*) FROM gameobject` returning `101092` - every row, including all 198 new ones.
* the module's own placements when the file is applied: **4,464**, of which 4,452 carry a
  facing, and 0 left at the stand-in height or at zero.
* `apps/coa-gameplay-test/scenarios/worldforged-pickups.json` - 82 steps, 35 assertions,
  passed.

### The ninth pass: one placement where the restoration put two

`2026_09_23_04_worldforged_duplicates.sql` removes 262 placements that were each the same
object, or the same item, standing twice. Every one of them was made by a pass above, and
all three causes lie in the data those passes used rather than in how they read it.

| # | What was doubled | Rows | Why it happened |
| --- | --- | --- | --- |
| 1 | one object standing twice: the same entry, on the same map, within 60 yd of itself | 185 | the two corpora that recorded these objects hold the same placement and agree to a **median of 27 yd** - one carries the object's own stored XYZ, the other a position read off a zone chart - and the passes separated positions at **30 yd**. Most objects the second corpus saw a second time were therefore placed a second time |
| 2 | one item offered by two objects: two entries whose loot is the same item within 60 yd | 32 | a pin names the *item* its looter picked up, never the object it came from. Where Ascension defined two objects that hand out one item - an entry whose client record is the invisible placeholder, and the prop a player sees - a pin of that item fits both, and both were placed on it |
| 3 | a position from another season: a row whose only evidence names Area 52, Bronzebeard, Darkmoon or Dawnrise | 45 | every one of these names another realm rather than Conquest of Azeroth |

Which row survives where one object stands twice, best evidence first:

1. the spot a player was recorded looting at - a pin, and among pins the one the most people
   recorded;
2. else the object's own catalogue position;
3. else, for one item held by two objects, the entry whose own record is a real prop, then
   the variant the realm has most of.

Two spots the community recorded *more than once each* 30 to 60 yd apart are left alone:
those are two spawns, not one placement seen twice. Six such object pairs stay.

Nothing here takes an item out of the world. A row is spared where it is the last placement
of the item it holds - one row. A second object may lose every placement of its own where the
object kept hands out the same item: seven entries end that way, and the item each holds is
still found, through the object that stands. The rows kept keep their position, height and
facing exactly as the eighth pass left them. The 26 rows this file removes that the eighth
pass stated as its own block `b` are also taken out of that insert, so a fresh database never
creates them.

#### How the numbers were checked

* before the file: 4,456 pickups - the 4,464 of the eighth pass counted 8 starting-zone
  mailboxes that share the same guid block; after it: **4,194 placements, 1,714 objects
  standing, 30 maps, 4,182 of them with a facing**.
* no item loses its last carrier: the one row that would have was spared.
* no object stands twice: the only pairs within 60 yd are the six community-recorded ones
  above, 12 rows in all.
* every surviving row still resolves its template, and none is left on the invisible
  placeholder (`0 displayless, 0 templates missing`).
* the leftover gaps are not from this file: **21 objects were never spawned by any pass**, so
  their 21 items (the Azuremyst, Bloodmyst and Eversong starter pickups, `Farmstead Carver`
  among them) still stand nowhere; and four placements - all in Blackrock Caverns, map 645 -
  carry no height and stand at 0.
* the worldserver boot after the file reads the same row count, and
  `apps/coa-gameplay-test/scenarios/worldforged-pickups.json` passes.

### The tenth pass: the realm's own map, and nothing else

`2026_09_23_05_worldforged_map.sql` makes the world stand exactly what the realm map records.
Every pass above placed a pickup wherever any single record put it - one per recorded position,
per realm, per zone dump, per loot pin - which is why one object could be found several times in
a zone and why some stood where the realm never had them. This file clears every spawn of a
`worldforged_pickup` template and stands its own set as the whole of what remains:
**2,480 placements over 76 zones, 1,576 pickup objects, four continent maps**.

| The value | Where it comes from |
| --- | --- |
| which pickup | the map's own name. The realm names a pickup after the item it holds, so the name is usually both; where the name is a prop (`Old Grave`, `Waterlogged Chest`, `Black Powder Barrel`) the realm has an object of precisely that name, and its loot row names the item, so it is the object the map means. |
| position | the map's marker, converted to world coordinates through each zone's own world rectangle. Against the archive's loot pins - recorded world positions for the same item in the same zone - the conversion agrees to a **median of 2.5 yd over 1,872 markers**. |
| height | never invented. In order of use: the height the pickup already stands at in this world; the height the client recorded for that object at that spot; the floor the realm's own occupants stand on within 70 yd - a marker's coordinate carries a few yards of slack, and a few yards sideways on a slope is tens of yards of height; the floor the pickups around it share; and only where the realm has put nothing at all, the server's own terrain, read exactly as the core reads it. **45 markers whose height nothing in the realm states are left unplaced**, named at the end of the file rather than stood on a guess. |
| template | a pickup the realm already has keeps its own entry and appearance, untouched. A name the realm has no pickup for is not placed. |

A marker that pairs with a mystic scroll at the same spot is a scroll source and is left out:
scrolls are not part of this restoration.

`2026_09_23_06_worldforged_recorded_heights.sql` then stands **278 pickups on the height the
client itself recorded them at** - its own dumps are sightings of an object, its map and the
world XYZ the client saw it at - wherever that sighting is within 12 yd of the placement. A
pickup inside a mine or on a tower balcony is under, or over, the surface the terrain reader
can see, so the recording is the only one of the two that is true. The same file adds the zone's
two objects the realm had never had, from the realm's own client-cache records: Elwynn's
**Brother's Cherry Pie** (90634, the invisible chest that hands out Brother Danil's Cherry Pie,
with the visible Cherry Pie prop - display 5493 - beside it, as at every other starter-zone pie)
and the **Bloodied Axe** (93008, a chest whose own appearance is the axe, display 175455) at
both spots the client recorded it: Duskwood/Elwynn and Thousand Needles.

`2026_09_23_07_worldforged_spare_spawns.sql` removes **eight placements that are a second
placing of an object the map records elsewhere**, four of them left hanging high on a hillside:
the Crystallized Shield, Gareks Personal Belongings, the Tattered Goblin Cargo Sack, the Ancient
Relic, the Glinting Silt-Encrusted Necklace, the Shoulderguards of the Ancient Prophet, the
Cursed Branch and The Rock Binder. Every one of the eight already stands at exactly the spot the
map records for it, and after this file it stands nowhere else.

#### The zone checked end to end against the map

Elwynn Forest - with Northshire, which `AreaTable` parents to nothing of its own, so the zone is
two area trees - is the first zone verified row by row against the map:

* **71 of 71** markers on the zone's page stand, none is missing, and the only rows the page
does not account for are six that sit at **exactly 0.0 yd** from a marker the map files under a
neighbouring zone page (Westfall, the Burning Steppes). There the zone's label differs from the
server's own area table; the placement does not.
* **68 worldforge pickups** stand in the zone, 1 visible companion prop among them.
* every template standing in the zone resolves its display in the client's own patched
`GameObjectDisplayInfo.dbc`; the only invisible-placeholder display is the pie chest above, by
design, with the visible pie prop beside it.
* six rows stand more than 6 yd from the terrain reader's surface - two mine floors (Echo Ridge
Mine's shovel, and the kobold corpse among the realm's own copper veins), the Tower of Azora's
upper room, the Ridgepoint Tower balcony and two interiors. Each stands at the height the
client itself recorded: a mine floor or a tower floor is under, or over, the surface the terrain
reader can see. Nothing is buried under the ground a player walks on and nothing floats without
a record.

#### How the numbers were checked

* before the tenth pass: 4,194 placements; after it: **2,480 placements, 1,576 objects, four
  continent maps**, and after the two files that follow it **2,475 placements standing**. The
  worldserver's boot reads 99,112 gameobjects, four fewer than before the eight removals.
* no item loses its last carrier: every object the eight removed rows belonged to still stands
  elsewhere, at the spot the map records for it.
* the map's own Elwynn page: 71 markers listed, 71 standing, 0 missing.
* the pickups that stand at the height the client recorded them at were checked one by one
  against the recording: each within 12 yd of its own sighting, none standing on an invented
  height.

### The eleventh pass: Westfall, paired marker by marker

`2026_09_23_08_worldforged_westfall.sql` is the second zone taken end to end against the map, and
the first that pairs rather than compares. Every marker on the zone's page is matched with a
pickup of the same object, one marker to one pickup, greedily by nearest standing; then a paired
pickup more than half a yard off its marker is moved onto it, and a pickup that pairs with no
marker of any page is a stray placing and is removed.

* **123 of 136** markers stand. The 13 that do not are accounted for, not missing: seven are the
  realm's book/scroll/crystal fixtures (Ancient Priest Tome, Light and Shadow Vol: 1, Scroll of
  Curses, Arcane Crystal, Unlit Twilight Candle, Evil Chest, Whispering Book) and six are
  `Worldforge Drops (N items)` **cluster labels**, not placements - three sit on Saldean's Farm
  and two of those label the same two drops, the rest at spots where nothing in the realm stands
  within 60 yd. The fixtures' objects are in the realm's own dump with their displays, but their
  loot tables exist in no source held here, so nothing is invented for them. No marker with a
  real object behind it was lacking a pickup.
* **nine pickups moved onto their markers**, the furthest 15.6 yd (Sharp Bone Necklace, Raven
  Hill Cemetery), the rest 1.3 to 5.4 yd. Heights: the pickup's own height where the move is
  short, else the client's recording for that object at that spot, else the realm's own recorded
  height when the ground agrees, else the floor the realm's own occupants share, else the
  server's terrain.
* **two strays removed** - the Misplaced Pitchfork at Jangolode Mine and the Quarry Sledge at
  the Gold Coast Quarry, each a second placing of an object that already stands at every spot
  the map records for it.
* **two markers are one placement recorded twice**: the map files Rower's Jerkin and Madness
  Cursed Notes on the Westfall page *and* a neighbour's, with coordinates 12 and 18 yd apart,
  while the realm's own record agrees with the neighbour's. The recorded spot is kept, and the
  file says so at the row rather than hiding it.
* one height was rejected on the way: the realm's own record for Sharp Bone Necklace says 1.8,
  but that is 31 yd under the ground the rest of Raven Hill Cemetery stands on and no source
  carries its x/y, so the marker takes the server's own terrain (33.34) instead.

#### How the numbers were checked

* the map's Westfall page: 136 markers listed, 123 standing on a pickup of their own object,
  13 accounted for above, **0 missing**.
* pickups in the zone that stand on no marker anywhere: **0**; the two that did before the pass
  are the removals above.
* each of the nine moved rows was read back from the live database after the file ran: marker
  coordinates to the decimal, none more than 6 yd from the ground it stands on except where the
  client's own recording for that object says otherwise (People's Militia Stolen Badge, seen at
  40.3 within a yard of the marker, in a hollow the terrain reader reads as 52.5).
* the worldserver applies the file on boot (`Applying update "2026_09_23_08_worldforged_westfall.sql"`)
  and reads **99,109 gameobjects**, two fewer than before the removals.

### The twelfth pass: Duskwood, paired marker by marker

`2026_09_23_09_worldforged_duskwood.sql`. The zone's page lists **50 markers**: **44 real
placements**, four fixtures whose objects and loot tables exist in no source held (Omen of Doom,
Whispering Book, Arcane Crystal, Scroll of Curses - the realm's scroll family, left alone), one
`Worldforge Drops` cluster label, and one chest the map names after the item it is, `Discarded
Junk`, which this world carries as the object Haren's Tankard (entry 1345067, display 184947,
standing 0.0 yd from that marker).

* **35 of the 44 placements already stood**; the other **nine** are placements the map records on
  two of its own pages 3.5 to 15.6 yd apart (Darkest Night Loop, Raven Hill Backscratcher, Honed
  Steel Axe, Ruby Skeletal Ring, Venom Sample, The Jitters, Nightshot, Vul'Gol Torch, Poisoned
  Pendant). In each case the pickup already stands on the neighbouring page's copy at the spot
  the realm itself recorded, so nothing moved and the file says so at the row.
* **two pickups moved onto their markers** - Murloc Voodoo Toy 10.1 yd and Dark Scythe 13.0 yd.
* **nothing removed**: six of the zone's objects have two spawns, and all twelve spots stand 0.0 yd
  on a marker of their own name (the map lists the object-name label and the item-name label as
  two separate placements, e.g. Casket Will / Will in the Casket 1,032 yd apart).
* pickups in the zone that stand on no marker anywhere: **0**. The worldserver applies the file on
  boot (`Applying update "2026_09_23_09_worldforged_duskwood.sql"`).

### The thirteenth pass: Stranglethorn Vale, paired marker by marker

`2026_09_23_10_worldforged_stranglethorn_vale.sql`. The zone's page lists **98 markers**: **90
real placements**, four scroll chests (Priestess Cache, Beating Heart, Armed Trap, Mysterious
Pirate Cache - objects the realm had, whose loot is a Mystic Scroll, left out like the rest of
that family), three markers that name nothing in this world (Mysterious Cauldron, Demonic Skull,
Skull Crusher - the last likewise a chest handing out Mystic Scroll: Skull Crusher), and one
cluster label.

* **89 of the 90 placements already stood**, including Gregan Tanning Rack, which serves the
  marker the map names *Thunder Fur Cloak* after the item it hands out (0.0 yd, archive loot pin
  2.6 yd away, 8 records).
* **one pickup moved**: Ancient Sea-dweller Charm, 14,719.9 yd off its marker. The realm's own
  sightings of that chest put it 20.9 yd from the marker at a recorded height 9 yd above the sea
  floor the terrain reader finds there, so the marker takes the terrain; the archive's own loot
  pin for the item (9 records across six realms) sits 4.7 yd from that marker.
* **one stray removed**: a second Rugged Leather Runners at -11338.2 -268.2, 22.8 yd from the
  single placing the realm recorded for that object (height 47.7) and with no marker of its name
  anywhere on the map. The surviving spawn matches the realm's record exactly.
* four rows sit inside caves (Mai'Zoth's Artifact, The Ironjaw, Kurzen Eviscerator, Stonesplitter)
  where the terrain reader sees the surface 100 to 186 yd above them; each matches the realm's own
  recorded height for that object to the decimal, so they stay.
* the worldserver applies the file on boot
  (`Applying update "2026_09_23_10_worldforged_stranglethorn_vale.sql"`) and reads **99,108
  gameobjects**, one fewer than before the removal.

### The fourteenth pass: Deadwind Pass, paired marker by marker

`2026_09_23_11_worldforged_deadwind_pass.sql` holds **no statements**: this zone needed no change,
and the file exists so the check has a record beside every other zone's. The page lists **41
markers**:

* **37 real placements**. 36 stand 0.0 yd on them. The 37th, **Betrayal's Edge**, is one placement
the map records twice - on its Duskwood page as 'Dark Scythe' (-10452.2 -1720.3) and on its
Deadwind page as 'Betrayal's Edge' (-10449.5 -1733.0), 13 yd apart. The realm's own sightings of
that chest (entry 254494, -10452.6 -1719.7 at height 85.8, seen twice, tagged Duskwood) agree with
the spot the pickup stands on, so nothing moved.
* **two fixtures** whose objects this world and the realm's records both have, but whose loot
tables exist in no source held: Lost Tome (100049, display 430) and Old Book (254512/254513/254514,
displays 8128/8133/60737), chests the realm itself saw in DeadwindPass. Nothing is invented.
* **one scroll chest**: Mysterious Goblet (2180754, display 565), whose archive loot pin 1.9 yd away
names Mystic Scroll: Divine Symmetry - left out with the rest of that family.
* **one cluster label**, `Worldforge Drops (3 items)`.

Three of the page's markers are served by pickups the world's own area data files next door, so
their rows live on that zone's sheet - Bloodied Gauntlets (Blasted Lands), Lifesap Blade
(Duskwood), Furbolg War Drum (which the world does call Deadwind Pass). All three stand 0.0 yd on
the marker. Six rows read 9 to 157 yd from the terrain reader's surface because they sit inside
Karazhan's cellars and crypts; each matches the realm's recorded height for that object to the
decimal, so they stay.

### The fifteenth pass: Blasted Lands, paired marker by marker

`2026_09_23_12_worldforged_blasted_lands.sql` holds **no statements**: this zone needed no change,
and the file exists so the check has a record beside every other zone's. The page lists **71
markers**:

* **65 real placements**. 64 stand 0.0 to 2 yd on them. The 65th, **Nethergarde Mining Cap**, is one
placement the map records twice - on its Swamp of Sorrows page 9.5 yd from its Blasted Lands page -
and the realm's own record for that object agrees with the spot the pickup stands on (10.1 yd from
the Blasted Lands marker, 0.9 yd from the realm's record), so nothing moved.
* **three objects the realm has and this world does not**: Hanging Ogre Scraps (518081, display
254263), Monolith of Earth (660405, display 1018549) and Charred Staff (518029, display 188424). The
realm's own sightings place all three in the Badlands and nowhere else, and the page lists the first
two at the very same top/left its Badlands page uses, so no pickup is invented for them here. Their
Badlands placements stand and are served there.
* **two names no source held knows**: Capacitor Totem and Arrow of Binding. Neither object, item nor
pin exists under either name.
* **one cluster label**, `Worldforge Drops (2 items)`.

Every one of the zone's **57 pickups** stands within 3 yd of a marker of its own object name or of
the item it hands out, so nothing here is a stray, and no marker of the page is left without the
object it names. Their appearance is a record: 52 carry the entry's own record from the realm's
client cache, and the five whose record there is the invisible placeholder cube (Blood Covered
Metal, Extra Crate, Spark of Infernus, Venture Co. Ring, Vulture Effigy) carry the same-name
counterpart the eighth pass resolved, not a placeholder. Ten rows read 8 to 152 yd from the terrain
reader's surface and every one is explained: five sit on the floor of the mine tunnels under the
zone (Shining Wand, Forgotten Flower, Marsh Bonebreaker, Swamp Talker's Crossbow, Shadowsworn Staff
- Mithril, Gold, Truesilver and Thorium deposits share those heights to under a yard within 25 yd),
one stands 28 yd above the ground on the deck of the Necropolis that shares its height to 0.1 yd
(Charred Slicer), and four are interiors whose height is the realm's own record for that object
(Discharged Sawblade, Blood-soaked Bag, Sacrificial Knife, Mojo's Chest).

One property of the realm map is worth recording here, because it explains rows in this zone that
would otherwise look like duplicates. The map lists **202 of its markers on two zone pages with the
same top/left on both**, so each page projects its own world spot for them. **Twenty-four** of this
zone's pickups are that second listing - an object whose other listing stands in the Badlands some
5,000 yd east (17 of them: Ancient Relic, Ancient Wand, Awkwardly Placed Hammer, Barbarian King's
Circlet, Blood Covered Helm, Blood Covered Metal, Extra Crate, Gareks Personal Belongings, Lit
Lantern, Ogre Fire Poker, Scorched Knife, Shadowforge Shotgun, Shadowforged Deflector, Spark of
Infernus, Tattered Sack, Throkaf's Project, Windhorn Longbow), across the Deadwind Pass border about
1,300 yd north (4: Forgotten Flower, Intact Boots, Fallen Hero's Shield, Shining Wand), or in
Mulgore, the Western Plaguelands and Teldrassil (Venture Co. Ring, Charred Slicer, Vulture Effigy).
The realm's own loot pins corroborate one of the two spots in each of those 24 cases; the map plots
both, so both stand, and nothing is moved or removed on the strength of the other. The twenty-fifth
pickup the realm's records do not corroborate, Unloaded Shipment, has a second spawn in the Moonlit
Ossuary that no record corroborates either; it stands as well, because the page plots it.

### The twentieth pass: Searing Gorge, paired marker by marker

`2026_09_23_19_worldforged_searing_gorge.sql`. The zone's page lists **56 markers**, and 54 of
them stand in the zone's own twelve areas (Searing Gorge and its children, down to the Cauldron,
Grimesilt Dig Site, Dustfire Valley and Blackrock Mountain). The other two project into the
neighbouring areas their own positions fall in - Blackbreach Handaxe into Blackrock Stronghold,
Defias Special Bucket into the Burning Steppes - and the world's own pickups already stand exactly
on the page's plots for them (6940122 at -7527.5 -1270.6, 6940346 at -7421.8 -1415.7), so the
passes for those areas keep them and nothing here touches them. With the markers a neighbour's
page files inside the same areas, the pass judges **59 placements**; the zone holds **55 pickups**,
every one of its own object with its own loot row.

* **four chests the map lists twice**, once by the item the pickup hands out and once by the
  object it is, each pair on this zone's page and a neighbour's:
  * **Incendiosaur Bone String** (this page) and **Pile of Bones** (Dun Morogh page), 3.4 yd apart;
  * **Dark Iron Legplates** (this page) and **Dwarf Corpse** (Dun Morogh page), 3.4 yd apart;
  * **Dark Iron Wristbands** (this page) and **Broken Chain** (Dun Morogh page), 4.7 yd apart;
  * **Taskmaster's Blade** (this page, the object's listing) and the item it hands out,
    **Searsteel Claymore** (Blackrock Mountain page), 4.1 yd apart.

  In all four the realm's own record for the object agrees with the object's listing - 1.5, 0.8,
  1.7 and 0.3 yd - and stands 3.9 to 4.5 yd from the item's, so the pickup stands on the object's
  listing and the item's is the map's redrawing of it, the reading the Westfall pass took for its
  two such markers. **Three pickups move** onto those object listings, each keeping the height it
  already stood at: Pile of Bones (3.4 yd), Dwarf Corpse (3.4 yd) and Taskmaster's Blade (4.3 yd).
  **One is kept where it stands**: Dark Iron Wristbands' pickup (6940190, the object Broken Chain)
  already stands 4.7 yd from the item's listing and 0.0 yd from the object's.
* **four objects this world never carried are restored field for field** - entry, type, display,
  size and data - each on the spot the realm's own client saw it, and each keeping the loot-table
  id its own record names:
  * **Incendiary Ammo Cache** (1344096, display 300027, guid 6942486, 0.6 yd), at the height the
    client saw it (196.0, the floor the realm's own props in that cave share - the ore veins at
    196.6 and the Dented Footlocker at 194.7, under terrain the map reader puts 46 yd above them).
    No item of its name exists in any source held, so no loot row is written for it.
  * **Ripped Diary Page** (90449, display 1015781, guid 6942487, 0.5 yd), which is the name of the
    item it hands out and takes that loot row (item 1029571, 100%).
  * **Mysterious Orb** (90044, display 515667 - the orb the client draws - size 0.9, cast bar
    'Consuming', guid 6942488, 0.8 yd).
  * **Volatile Lava** (518367, display 980926 - the client's `invisible_cube`, the placeholder the
    realm used for hidden interactive chests - guid 6942489, 0.4 yd). Its display is the only
    placeholder in the zone, and it is what the realm's own record says stands there; nothing
    visible stands within 25 yd of it in the realm's sightings (the nearest is the Stone Anvil
    22 yd off, which this world already carries), so no visible prop is restored beside it.

  The first two the pass reached through the client-cache corpus it reads. The last two that corpus
  does not carry at all, and their records are the realm's own archive for the entry instead:
  Mysterious Orb's fetched from the part the archive index names, Volatile Lava's from the capture
  kept beside it. Nothing is guessed: every field is a value one of those records states.

**How the numbers were checked.** 55 of the 59 placements stand within 3 yd of a pickup of their
object, and the four that do not are exactly the item's listings of the chests listed twice, 3.4 to
4.7 yd off on the redrawing. **No marker is left with nothing behind it, and no pickup standing in
the zone honours no marker of any page** - so nothing was removed and nothing else was added. The
two objects restored from the archive's own record are the only rows in the file that do not come
from a client-cache capture, and both the archive's captures and the realm's own sightings place
them within a yard of their markers (0.8 and 0.4 yd). Fourteen of the zone's rows read 6 yd or more
from the terrain the worldserver reads: thirteen carry the realm's own recorded height for that
object, agreeing to 0.2-6.8 yd (the deepest is Pile of Bones, 223.8 yd below the surface at 129.7,
which is exactly the realm's own recorded height for it), and the fourteenth, the Steam Pressure
Totem (233.7), stands at the height the realm's own props share - the Twilight Crystal Bases read
233.2 to 235.2 within a yard of it.

The worldserver applies the file on boot and reads **99,124 gameobjects** and **2,486 worldforged
pickups**, four spawns more than before the pass and two objects among them this world had never
carried.

### The final authored pass: Redridge Mountains, item by item

`2026_09_24_29_worldforged_redridge_authored.sql` is the zone's own check in the map editor, the
same shape as the Elwynn one below: thirty-three changesets, one save each, read in the order they
were written with the last write to a row winning. Every one of the zone's **33 pickups** was gone
over by hand, so all 33 rows appear in the file: **26 of them moved** - the furthest **Unclaimed
Sack** (6941289, 140.2 yd), **Ilgalar Stolen Neckpiece** (6941149, 67.1), **Aqualon's Core**
(6940068, 63.7), **Ribchaser's Loop** (6940958, 39.0) and **Tharil'zun's Extra Boots** (6941206,
33.7) - and **10 of them turned**, the largest turns **Ribchaser's Loop** (2.87 rad), **Lexicon of
Azora - Part II** (2.31), **Gnollish Sword** (2.22) and **Yowler's Howl** (1.95). The remaining
**6 rows were re-saved unchanged**: Apprentice Staff, Wax Stained Bag, Sword in a Board, Defias
Special Bucket, Old Grave and Forgotten Sack all still stand exactly where the earlier pass left
them, so the save is the editor saying so and the rows are re-asserted to the same values.

Four objects were also placed beside the murloc camp at Lake Everstill, and they are **props, not
pickups** - their templates are scenery (type 5), not chests, so they carry no script: they do not
sparkle and hand out nothing. They keep the guids the allocator gave them:

* **Temporary Spawned Murloc Hut 01** (186742) twice, guids 6960013 at -9453.5 -3347.1 and 6960014
  at -9465.4 -3340.6, and **Temporary Spawned Murloc Hut 02** (186743) at -9442.9 -3337.7, guid
  6960012;
* **Murloc Cage** (182164), at -9461.1 -3341.0, guid 6960015.

One row from the Elwynn pass is corrected here at the same time. The **Gypsy Wagon** (178666, guid
6960011) that was placed beside the Traveler's Forest Cloak is scenery too - its template is a
wagons-and-carts doodad, not a chest - but it had been written with this module's script on it,
which made a prop sparkle and open an empty loot window. The script is taken off it, so what stands
there is what the editor placed: a wagon, not a pickup. (It is one row fewer in the pickup counts
below, which is why the count moves by the four props rather than five.)

The file writes the position and the rotation quaternion exactly as the editor emitted them, and
the orientation column as the yaw that quaternion represents; nothing else in a row is touched, so
spawn masks, phase, loot table and each row's earlier comment history survive. **All 37 rows of the
zone - 33 pickups and 4 props - were then read back from the live database and match the file
exactly**, positions, facings, entries and scripts alike.

### The placements and rotations authored in game: Elwynn Forest

`2026_09_23_18_worldforged_authored_in_game.sql` is not a map pass: every row in it was authored
by hand in the map editor (Noggit, against the client's own data), which writes one changeset per
save. The forty-three changesets of the two editing projects are read in the order they were
written, the last write to a row winning, and the migration is what they say, digit for digit:
**39 rows moved and/or turned, and 5 placements added**. A save covers the whole selection, so most
of those 39 rows arrive as the editor already had them; what the editor actually changed in Elwynn
is **4 rows moved** - Old Buckler 211.62 yd, Appropriated Goods 99.55 yd out of the hole it had
been buried in, Riverpaw Pack Chieftain's Lunch 18.02 yd and Dryad's Bow 6.40 yd - and **4 rows
turned** (the same four, by 0.51, 0.06, 1.06 and 0.40 rad). The orientation column is written as the
yaw the quaternion represents, which is what the model is drawn with - the editor's own column
disagreed with its quaternion on two rows (Apprentice Staff and the Cherry Pie prop) and the
quaternion is the one written.

* **two rows were rejected as copies of a neighbour's record.** A save writes every row it touched,
  including ones the editor never moved, and when two objects go into one save the editor can write
a row with the *other* object's loaded coordinates verbatim. Old Buckler's row (6940412) arrived
holding the buried spot (z -74.86) Appropriated Goods had just vacated, 1,096 yd away; Lookout
Scope's (6940712) arrived holding Old Buckler's own live spot. Both are exact to the centimetre,
which is how a copy shows itself, and both rows are left at their own value: Old Buckler stands at
the spot its author saved for it in the previous save (-9558.30, -1416.90, 101.10), Lookout Scope
where it already stood. Nothing is placed underground by this file.

* **five placements added**, each keeping the loot row its object already had: Morale Boosters
  (95692, guid 6960005, Party Pants), Scorched Tome (520063, guids 6960006 and 6960007, Forsaken
  Tome), Rock Smasher (95655, guid 6960008, Barrel Smasher) and Glinting Kobold Corpse (90223, guid
  6960009, Mother's Loose Fang). The editor wrote the same Scorched Tome placement twice in one
  changeset; one row is placed.
* **the rows that are not this module's are left alone** and named in the file: a Campfire (guid
  26867) and James' Journal (guid 27022), both the world's own objects, moved a few inches or turned
  a full circle by a stray selection.
* **the interiors keep the editor's heights** - Appropriated Goods is out of its hole and stands
  above ground (70.83), while Glinting Kobold Corpse, Worn Shovel and Deepmoss Fang are where the
  editor left them in the Jasperlode and Echo Ridge workings, on the mine floor rather than on the
  surface the terrain reader describes.
* **the realm map's marker checks in the passes above describe where those rows stood before.** The
  authored rows carry the authored position, and where that differs from the map's own marker the
  file says so row by row.

Every statement is an UPDATE on a guid or a REPLACE on a guid the file allocates, so it is safe to
re-run, and the rows' earlier Comments are kept, with the authored-in-game note appended once.

### The final authored pass: Elwynn Forest and Northshire, item by item

`2026_09_24_20_worldforged_authored_in_game_final.sql` is the same reading as the Elwynn authored
section above, over a later and larger set of saves: **72 changesets** from the two editing
projects (`pro`'s eight and `pro2`'s sixty-four), read in the order they were written, the last
write to a row winning. This is the pass in which every Elwynn and Northshire item was walked,
repositioned and realigned, so it supersedes the earlier authored file's values for the rows it
touches.

* **60 rows of this module were moved and/or turned.** Most arrive as the editor already had them
  - a save writes the whole selection - and **twenty-three actually moved more than half a yard**,
  the furthest Ziz's Alchemy Goggles by 638.19 yd, then Timbermaw Defender 380.92, Chocked Fish
  Corpse 243.14, Gore Covered Bow 235.35 and Overseer's Axe 180.40 yd. Position and the rotation
  quaternion are the editor's own, digit for digit, and the orientation column is written as the
  yaw that quaternion represents; where the editor's own orientation column disagreed with it the
  quaternion is the one written and the file says so at the row.
* **5 rows were removed**, each a duplicate or the item's own listing standing beside the
  object's: Lost Shipment's old placing (6940243, -9490.0 251.1 53.9, re-placed on a fresh guid
  in the same save), The Wanderer's Stirring Rod (6941224, -9446.4 526.8 56.2), Thunder Falls
  Finest Gun Selection's duplicate (6941243, -9304.9 563.4 87.6, while 6941240 keeps the chest),
  and the two extra placements the earlier authored pass had made in Echo Ridge Mine: Scorched
  Tome (6960006) and Glinting Kobold Corpse (6960009).
* **one of the deletes was not a removal at all.** `spawns_20260924_094425.sql` clears guid
  6940160 and writes nothing else - the shape a changeset has when a save carries no rewrite -
  and the object (Homer's Boar Harvester, at the Stonefield Farm) was never taken out of the
  map. `2026_09_24_21_worldforged_boar_harvester_restored.sql` stands it back on the last row
  the editor authored for it (`spawns_20260924_094300.sql`: moved 3.48 yd, turned 1.043 rad),
  field for field, template and loot row untouched.

* **5 placements stand for this module after this pass**, each keeping the loot row its object
  always had: Morale Boosters (95692, guid 6960005, Party Pants), Scorched Tome (520063, guid
  6960007, Forsaken Tome) and Rock Smasher (95655, guid 6960008, Barrel Smasher) - the three the
  earlier authored file stands that the editor kept - plus two the editor placed in this pass,
  **Lost Shipment** (97108, guid 6960010, the chest that hands out Charred Spaulders, re-placed
  where the editor moved it) and the **Gypsy Wagon** prop (178666, guid 6960011) it stands beside
  the Traveler's Forest Cloak at Jerod's Landing, which is a prop and hands out nothing, like the
  Cherry Pie prop in Northshire.
* **the two rows that are not this module's are left alone** and named in the file: a Campfire
  (guid 26867) and James' Journal (guid 27022), the world's own objects.

`2026_09_24_22_worldforged_removed_by_hand.sql` then honours the last thing the pass left open:
walking the sheets row by row, the realm's author deleted three rows, and one of the three was a
placement no authored save had touched. **Loose Stone, guid 6940971** (-10006.6 321.8) - the object
that hands out Robe of Woven Dreams, standing on the Westfall side of the border the realm map files
under its Westfall page while the server's own area table calls the spot the Stonefield Farm, which
is why it was listed on the Elwynn sheet - is removed. The item keeps its other placings: the same
object stands in the Swamp of Sorrows (6940970) and on Sunstrider Isle (6942474). The other two rows
deleted by hand - The Wanderer's Stirring Rod (6941224) and Thunder Falls Finest Gun Selection's
duplicate (6941243) - were already gone, because the editor's own saves deleted those guids.

**How the numbers were checked.** Every statement is an UPDATE on a guid, a REPLACE on a guid the
file allocates, or a DELETE on a guid the editor deleted, so re-running it leaves the same rows:
the file was applied to the live database and applied again with no error. After it, `acore_world`
holds **99,121 gameobjects and 2,482 worldforged pickups**, none of the five removed guids remains,
and all five placements above stand with the coordinates the file writes.

**The workbook was then checked against the server, row by row.** `worldforged-items.xlsx` carries
**697 placement rows over 15 sheets** (Searing Gorge added from the pass above); every row's guid
was read back from the live database - **0 rows with nothing behind them, 0 entry mismatches** -
each row's position, height and facing were refreshed from the database, each row the editor
touched is marked `Rotation complete`, and the rows for the six deleted objects are gone from the
sheets while the two new placements and the re-placed Lost Shipment are in them at their final
guids.

### The last two rows of the Elwynn and Northshire pass

`2026_09_24_30_worldforged_elwynn_last_rows.sql` carries the two rows of that pass that the editor
moved once more, after the file above was written, so the world and the file no longer agreed:

* **Ziz's Alchemy Goggles** (254229, guid 6941368, Jasperlode Mine) stands 0.2 yd higher than the
  pass left it, and its x and y were nudged by a thousandth of a yard at the same time.
* Northshire's **Cherry Pie prop** (90635, guid 6960002) is back on the spot the pass before the
  last one wrote, 0.35 yd from where the last pass left it.

Both rows are written as the world holds them, read back from `acore_world` down to the digit - the
quaternion as well as the position - and both are UPDATEs keyed on guid, so the file is idempotent
and touches nothing but the position, the rotation and the comment.

### The placements and rotations authored in game: Deadwind Pass

`2026_09_24_36_worldforged_deadwind_pass_authored.sql` is the zone's own check in the map editor,
the same shape as the Elwynn and Redridge ones above: the editing project's **thirty-five
changesets**, one save each, read in the order they were written with the last write to a row
winning. Every one of the zone's rows was gone over by hand, and the file holds **22 rows moved
and/or turned**, **6 rows removed by the editor** and **6 placements added** - and then **two more
rows removed** when the zone was walked in game, each one an object the pass had just left standing
twice. Position and the rotation quaternion are written exactly as the editor emitted them, digit
for digit, and the orientation column as the yaw that quaternion represents - the editor's own
orientation column agreed with its quaternion on every row here, so there is nothing to reconcile.

* **twenty-two rows moved, every one of them by more than a yard**, the furthest **Scorched Tome**
  (520063, guid 6940502) by **914.0 yd**, **Heirloom of the Whisperwind** (515436, guid 6941336)
  284.5, **Cellar Rubble** (254498, guid 6941305) 168.4, **Unique Bush** (90554, guid 6941003) 149.2,
  **Celestial Edge of Starfall** (515434, guid 6941143) 89.4, **Arlithrien Moon Orb** (515430, guid
  6940080) 70.7, **Chainmail Gauntlets** (90508, guid 6940537) 67.6 and **Red Plumage** (90565, guid
  6940593) 28.3; the remaining fourteen moved between 1.5 and 20.1 yd. **Thirteen were also
  turned**, the largest **Red Plumage** (3.082 rad), **Cursed Branch** (2.946), **Timberbane's Old
  Hatchet** (2.926), **Blade of the Faithful** (2.565), **Foreboding Banner** (1.873) and **Dark
  Scythe** (1.725).
* **six rows were removed by the editor's own changesets**, each a placement it took out of the
  client's own data: **Forgotten Cane** (90552, guid 6940765 at -10832.9 -2408.0 270.5), **Lunar
  Tome** (515431, guid 6940728 at -10849.5 -2483.0 207.9), **Small War Drum** (515388, guid 6940519
  at -10932.9 -2483.0 176.2), **Stuck Scimitar** (90562, guid 6940248 at -10716.2 -1983.0 129.0),
  **Wooden Maul** (90553, guid 6941253 at -11032.9 -2183.0 50.5) and **Shining Wand** (254488, guid
  6941307 at -11113.2 -2083.0 50.4). Five of them stood exactly on the surface the terrain reader
  describes - that is where their heights came from - and each of those five has its object placed
  again below, on the terrain of the spot the author chose.
* **six placements added**, on the guids the allocator gives them, each keeping the loot row its
  object already had: **Forgotten Cane** (90552, guid 6960016) at -11064.2 -2154.9 27.9, **Small War
  Drum** (515388, guid 6960017) at -10996.7 -2312.5 117.0, **Lunar Tome** (515431, guid 6960018) at
  -11116.2 -2085.4 49.4, the zone's **Timberling Ritual Blade** (515433, guid 6960019) at -11156.9
  -2479.2 105.3, **Wooden Maul** (90553, guid 6960020) at -10855.6 -2286.4 117.2 and **Stuck
  Scimitar** (90562, guid 6960021) at -10837.0 -2089.3 124.5. Five of the six stand on the ground
  the worldserver reads at their own spot (0.0 to 2.4 yd); **Timberling Ritual Blade** stands 107.6
  yd below the surface the terrain reader gives there, inside the crypt, as the zone's other rows
  in Karazhan's cellars and crypts do. The world's own area data files that spot in the Blasted
  Lands area, outside this zone's bounds.
* **two more rows were removed when the zone was walked in game**, each a second row of an object
  the pass above had just answered for:
    * **Timberling Ritual Blade** (515433) was still standing on the realm map's own listing of it
      at -11116.2 -2183.0 (guid 6941255) while the editor placed the same object at -11156.9
      -2479.2 (guid 6960019), so the older row goes and the object stands once.
    * **Shining Wand** (254488) is the item the map draws on two pages, the Deadwind Pass page at
      -11113.2 -2083.0 and the page for the zone below it at -10764.4 -3369.2 (guid 6941308). The
      Deadwind row went in the editor's own changeset above; the other went on the walk, so **both
      of the item's listings are gone** and it is handed out by no pickup of this module now.
* **nothing that is not this module's is touched.** Every guid the file addresses is one of this
  module's own pickups, so it edits no object the world itself owns.

**How the numbers were checked.** All 22 rewritten rows, the 6 added placements and the absence of
all **8** removed guids were read back from the live database afterwards: **278 assertions, none
failing** - entry, position, quaternion, orientation, script and the placement note all exactly as
the file writes them, and every added placement holds a loot row. Every statement is an UPDATE on a
guid, a REPLACE on a guid the file allocates, or a DELETE, so the pass is idempotent: applied a
second and a third time it leaves the same rows. The pass moves the realm's own totals the way its
rows move: six placements leave and six arrive in the editor's changesets, and two more rows go on
the walk, so the realm stands two pickups fewer than it did before the pass.

**The workbook was then checked against the server, row by row.** `worldforged-items.xlsx` carries
**962 placement rows over 15 sheets**; every row's guid was read back from the live database -
**0 rows with nothing behind them, 0 entry mismatches** - each row's position, height and facing
were refreshed from the database, the 28 rows the editor touched are marked `Rotation complete`,
the five rows whose object it removed and placed again carry the guid the allocator gave the new
placement and its coordinates, the one placement it added that had no row is in the sheet at its
final guid, and the two rows removed on the walk are gone from their sheets (Deadwind Pass stands
35 pickups, the zone below it 56).

### The twenty-sixth pass: Silverpine Forest, paired marker by marker

`2026_09_24_40_worldforged_silverpine_forest.sql` judges the zone's own page marker by marker,
`2026_09_24_41_worldforged_silverpine_forest_records.sql` restores the two objects the page's
markers name that this world never carried, and
`2026_09_24_42_worldforged_silverpine_forest_drop_pins.sql` stands the three objects the zone's own
drop listing names on the realm's own recorded spots. The zone is Silverpine Forest and its
twenty-six areas (Ambermill, Beren's Peril, Bucklebree Farm, Deep Elem Mine, Fenris Isle and Fenris
Keep, Lordamere Lake, Malden's Orchard, the North Tide's Hollow and Run, Olsen's Farthing, Pyrewood
Village, Shadowfang Keep, the South Tide's Run, The Dawning Isles, The Dead Field, The Decrepit
Ferry, The Great Sea, The Greymane Wall, The Ivar Patch, The Sepulcher and its Crypts, The Shining
Strand, The Skittering Dark and Valgan's Field). The page lists **50 markers**, every one of them a
worldforge item. **Forty-four of them stand in those areas**; the other six fall in the areas the
world's own table gives to neighbours - Dandred's Fold, The Uplands, the Ruins of Alterac and the
Lordamere Internment Camp, all four in the Alterac Mountains, and The Great Sea twice, off the
coast - and belong to those zones' passes. Markers of other pages that land inside this zone's areas
(Stolen Rot Hide Circlet on the Alterac Mountains page, Meat Wagon Small Claw and Adventurer's
Lost Sack on the Tirisfal Glades page) are judged here, so the pass reads **47 markers** - and
**one name is drawn twice**, so it judges **46 placements**. The zone holds **46 pickups**.

* **one placement the map draws on two pages**: **Stolen Rot Hide Circlet** - this page's listing
  at 798.0 173.2 and the Alterac Mountains page's listing at 798.4 167.2, 6.6 yd apart, both inside
  The Dawning Isles. The realm's own record of the object agrees with the Alterac listing to 0.6 yd
  and the pickup that stands there (guid 6941153, entry 90319) is 6.0 yd from this page's listing,
  so it is one placement the map recorded twice, it stands where the realm had it, and nothing
  moves.
* **one placement is kept where it stands**: **Small Claw of the Meat Wagon** - the pickup
  (guid 6940748, entry 90349) is 6.0 yd from this page's marker (1158.0 1896.8) and the realm's own
  record for the object agrees with the pickup rather than with the mark, so the two plots are one
  placement the map recorded twice and nothing moves.
* **three markers stand farther out and are second placings of objects whose pickups already honour
  a marker of their own in another zone**: **Drowned Adventurer** (entry 101911, 7,226 yd from its
  Loch Modan pickup), **Forgotten Book of Healing** (99010, 6,405 yd) and **Light and Shadow Vol:
  1** (100011, 7,669 yd). The realm's own dump saw each of the three in this zone within two yards
  of the marker that names it, so the zone had a placing of its own, and one is added for each at
  the height the realm's own client recorded: guids 6942539 (705.9 988.8 z 27.006, on the bed of
  Lordamere Lake), 6942540 (-727.1 1534.8 z 17.696) and 6942541 (-21.8 1354.2 z 60.894). The
  Drowned Adventurer's own record is the invisible placeholder (display 980926), which is what the
  realm's record says stands there.
* **five markers name an object this world never carried, and the realm's own client-cache record
  holds each of them standing within two yards of its marker**. Each is restored field for field
  from that record - entry, type, display, cast bar, size, its own lock and its own loot-table id -
  on the realm's own sighting of it: **Ancient Priest Tome** (101912, display 255, guid 6942542 at
  -195.3 921.6, 1.1 yd from the mark), **Codex of Divine Mending** (99018, display 184777, guid
  6942543 at 770.3 1350.0, 1.3 yd), **Cold Crystal** (101914, display 2770, guid 6942544 at -164.5
  778.8, 0.6 yd), **Shadow Portal** (111017, display 1048997, guid 6942545 at -167.3 770.4, 1.5 yd)
  and **Sorcerer's Cache** (835958, display 336, guid 6942546 at -94.6 955.2, 1.1 yd). **No loot
  row is written for any of them**: the item each held is recorded in no source in hand, as
  everywhere else in these passes.
* **two markers are restored by the file beside this one**: **The Law of Light**'s own record here
  is a *second book of that name* - entry 111004, display 184795, cast bar 'Inspecting', size 1.00,
  where the entry this world already carried (111000, display 184790) is the one the map plots in
  Loch Modan, Darkshore and Westfall - and the realm's own client saw it 1.7 yd from this marker
  (-376.529 1116.350 z 84.151); its loot row hands out the item the marker names, The Law of Light
  (9200812), which the same-named Loch Modan placing already hands out. **Maddening Aura** (101913,
  display 515662 - the shadow-leech orb the realm uses for it - cast bar 'Inspecting', size 1.00)
  stood 1.7 yd from its own marker at -379.307 1659.130 z 12.179, in Pyrewood Village. No item of
  that name is recorded in any source held, so no loot row is written. The same object is plotted
  on the Redridge Mountains page too, where the realm's own dump sees it 1.2 yd from that marker;
  that page's own pass left it among the markers whose object no item could be tied to, and it is
  restored here for the Silverpine listing the realm's own record stands on.
* **one marker is deliberately left out, and the marker's own description says why**: **Arcane
  Crystal**'s description is *"Item that gives Arcane Cascade mystic enchant."* - that is Mystic
  Scroll: Arcane Cascade (item 201595), and the Mystic Scroll family is outside this module's
  scope. The realm's own records agree rather than contradict: both entries of that name it holds
  (99503 and 680016) draw display 980926, the invisible placeholder, so what stood in the world
  was the scroll's own sparkle and not a world object. This is also why the eighth and ninth
  passes (Westfall, Duskwood) left that marker alone.
* **one marker is the map's own drop listing, and it names four world objects**: **Worldforge
  Drops (4 items)** over Fenris Isle (1003.5 706.1). Its description lists the items looted there
  (Ravenous Eye, Gnoll Subjugator, Thule's Curse Parchment, Rot Hide Mantle) and the lootable world
  objects it saw - **Gnoll Subdue Wand**, **Rot Hide Stash**, **Thule's Curse Parchment** and
  **Cursed Fang Remains**. All four are this module's already, each with the display its own record
  gives it and the loot row for the item its own pin names, and the realm's own records give each
  its spot in this zone: **Gnoll Subdue Wand** (90312) at 1007.410 689.796 z 77.775, 16.8 yd from
  the pin (guid 6942549); **Rot Hide Stash** (90313) at 991.098 695.872 z 63.341, 16.1 yd (guid
  6942550) - this is that object's only row in the world, its own record naming no other zone; and
  **Cursed Fang Remains** (90314) at 1020.430 732.173 z 59.395, 31.1 yd (guid 6942551). The fourth,
  Thule's Curse Parchment, already has a marker of its own on the page and its pickup (guid
  6941239) stands exactly on it, 2.4 yd from the realm's own recorded spot, so nothing is added
  for it. Gnoll Subdue Wand and Cursed Fang Remains are the very objects the Loch Modan page's own
  'Worldforge Drops (2 items)' listing names, and each already stands there on the realm's own
  recorded spot for that listing (guids 6940556 and 6940934); nothing is carried across, and each
  zone keeps its own listing's object.
* **one row is removed**: **Meat Wagon Small Claw** (guid 6930016, entry 90349) stood at 1246.2
  1938.0 in The Skittering Dark, 97 yd from any marker of its own name and with no record of the
  realm's near it. The object itself is not lost - the same item's Tirisfal Glades placing (guid
  6940748) and its Loch Modan placing (guid 6941103) both stand.
* **nothing else moves.** Two pickups read 6 yd or more from the terrain the worldserver finds and
  both heights stand: **Grimson Cloak** (guid 6940579, -43.0 yd against the terrain at Deep Elem
  Mine) stands inside the mine on its own floor - the Copper Vein 18.9 yd away reads 107.5, the Tin
  Vein 108.4 and the Silver Vein 108.4, against this row's 107.8, while the surface over the mine
  reads 150.8, so the terrain reader is seeing the hilltop - and **Victim's Empty jar** (guid
  6940904, -163.5 yd, on the bed of Lordamere Lake) at the height the realm's own record gives it,
  12.5. Two more of the restored rows (Cold Crystal 6.5 yd over the surface, Ancient Priest Tome
  6.1 yd) agree with the realm's own record of the object to within 1.1 yd.

**How the numbers were checked.** Every marker of the zone's 46 was paired by hand against the
map's own page and its own drop listing, and the three files were read back from the database row
by row afterwards: **160 assertions, 0 failures** - seven templates and thirteen spawns field for
field (the guid, entry, map, position, script and comment of each), the five loot rows, the removed
row gone, and no object of the restored ones standing twice anywhere in the world. The files are
idempotent and were applied twice to prove it. Re-running the pass's own verifier over the live
world reads **46 pickups in the zone** against the page's 46 placements, **43 of the 46 honoured
within 3 yd** by a pickup of their own object, the two left being Arcane Crystal (the scroll marker
above) and the drop listing itself, and **1 pickup in the zone drawing the placeholder display** -
Drowned Adventurer, which is what the realm's own record says stands there. Three pickups in the
zone honour no marker of any page: the three objects the drop listing names, which is what a drop
listing's objects are. The worldserver applies the files on boot and reads **99,482 gameobjects**,
**2,536 worldforged pickups**, **1,798 pickup templates** and **1,750 loot rows**.

### The placements and rotations authored in game: Silverpine Forest

`2026_09_24_47_worldforged_silverpine_pass_authored.sql` is the zone walked by hand in the map
editor once the pass above stood in the world, the same shape as the Elwynn, Redridge and Deadwind
files: the editing project's **forty-six changesets**, one save each, read in the order they were
written with the last write to a row winning. Every placement of the zone was gone over, and the
file holds **25 rows moved and/or turned**, **13 rows removed** and **5 placements added**.
Position and the rotation quaternion are written exactly as the editor emitted them, digit for
digit, and the orientation column as the yaw that quaternion represents - the editor's own
orientation column agreed with its quaternion on every row here, so there is nothing to reconcile.

* **twenty-five rows were moved**, the furthest **Turtle Shell** (515379, guid 6940842) by **489.3
  yd**, then **Sorcerer's Cache** (835958, guid 6942546) 152.5, **Siren's Wand** (517323, guid
  6940291) 137.8, **Deadman's Dagger** (515385, guid 6940321) 60.4, **Dirt Covered Gown** (90325,
  guid 6940807) 46.7, **Misplaced Pitchfork** (515224, guid 6940757) 29.7, **Boom Barrel** (95526,
  guid 6940196) 29.4, **Thule's Curse Parchment** (90320, guid 6941239) 24.9, **Victim's Empty jar**
  (90327, guid 6940904) 22.2 and, among the rest between 1.5 and 21.9 yd, the two restored objects
  the walk keeps - **Ancient Priest Tome** (101912, guid 6942542, 17.4 yd) and **Cold Crystal**
  (101914, guid 6942544, 17.4) - and the drop listing's **Rot Hide Stash** (90313, guid 6942550,
  14.1). **Ten rows were also turned**, the largest **Grimson Cloak** (1345063, guid 6940579,
  1.207 rad), **Siren's Wand** (0.908), **Dirt Covered Gown** (0.781), **Gilnean Crate** (90328,
  guid 6940546, 0.541) and **Stolen Lordaeron Jewel** (90322, guid 6940049, 0.471).
* **six of the thirteen rows removed are the objects the pass above had just restored**, taken out
  on the walk because each is a Mystic Scroll's own prop and that family is outside this module's
  scope: **Shadow Portal** (111017, guid 6942545), **The Law of Light** (111004, guid 6942547),
  **Light and Shadow Vol: 1** (100011, guid 6942541), **Codex of Divine Mending** (99018, guid
  6942543), **Forgotten Book of Healing** (99010, guid 6942540) and **Maddening Aura** (101913,
  guid 6942548). Four of them pair, at another of their own listings, with the scroll the realm's
  own loot pin beside them names: Shadow Portal with *Mystic Scroll: Shadow Reserves* 1.8 yd (its
  Darkshore listing), Light and Shadow Vol: 1 with *Mystic Scroll: Light and Shadow* 3.2 yd (The
  Barrens) and 3.8 yd (Westfall), Codex of Divine Mending with *Mystic Scroll: Promise of Renewal*
  2.3 yd (Redridge Mountains) and The Law of Light with *Mystic Scroll: Long Arm of the Law* 2.1 yd
  (The Barrens). The other two - Forgotten Book of Healing and Maddening Aura - have no item of any
  kind recorded beside any of their listings in any source in hand, and nothing is written in their
  place either.
* **five of the other seven removed rows are the same objects placed again** where the editor put
  them, on the guids the allocator gives them, each keeping the loot row its object already had:
  **Old Shoulderpad** (517314, guid 6960022) at 1018.6 708.8 62.6, **Hidden Ring** (97100, guid
  6960023) at 419.0 1843.2 12.6, **Well Kept Hatchet** (95946, guid 6960024) at 848.2 1874.9 2.9,
  **Heavy Shovel** (515383, guid 6960025) at 1293.8 1963.7 22.9 and **A "Fishy" Staff** (95947,
  guid 6960026) at 1183.6 1043.4 35.0.
* **the last two are gone and placed nowhere else**: **Ivar's Femur** (90324, guid 6940663 at
  1276.9 1284.1 53.8, the object whose item the realm's own worldforged catalogue lists at item
  level 16) and **Rot Hide Supplies** (90317, guid 6940977 at 994.2 594.0 55.2). The zone's own
  markers record both objects, and the walk leaves neither standing.
* **nothing that is not this module's is swept in.** The same saves also move eighteen objects the
  world itself owns around Ambermill - **Cozy Fire**, **Wooden Chair** and **High Back Chair** rows,
  the **Ambermill Strongbox**, **Bruiseweed** twice and **Mageroyal** - and write **ten creature
  rows**. Every one of them is left exactly as it stands, and the file's own header lists them, so
  a reader can see what was deliberately left alone.

**How the numbers were checked.** All 25 rewritten rows and the 5 added placements were read back
from the live database afterwards, each against its own position, its rotation quaternion, the yaw
that quaternion represents, its entry and its script, and the absence of all 13 removed guids:
**91 assertions, none failing**. Read together with the marker pass's own check - **166 assertions**
over the same database once the tables of the two files above are taken through this one's plan -
the zone's rows are **257 assertions, none failing**. Every statement here is an UPDATE on a guid, a
REPLACE on a guid the file allocates, or a DELETE on one that is gone, so the pass is idempotent.
It leaves the realm standing **2,538 pickups over 1,639 distinct ids**, **1,805 pickup templates**,
**13 templates on the display the placeholder prop uses** and **99,475 gameobjects** - thirteen
rows fewer than the pass above left and five more, eight fewer in all.

**The workbook was refreshed from the server, row by row.** `worldforged-items.xlsx` carries the
zone's rows on its Silverpine Forest sheet; the 25 rows the editor touched and the 5 it placed
again were rewritten from the live database - position, facing and teleport - marked complete and
filled green, the five whose object moved to a new guid carry the guid the allocator gave it, and
the eight rows the walk left empty are kept on the sheet and marked removed, so the markers the
walk took out stay visible. The sheet stands **38 pickups, 30 of them authored in game**, and its
Index row says the same.
### The final authored pass: Tirisfal Glades, item by item

`2026_09_26_63_worldforged_tirisfal_final.sql` is the zone reconciled against the realm map marker
by marker and then walked by hand in the map editor, written as one file that carries the zone's
final verified state and supersedes every earlier state of it, so a database converges from any of
them.

The marker pass reads the zone's eighty-one judged placements and moves four onto the marker of the
object's own name (Nightweb Spider Egg 4.2 yd, Stashed Goods 5.3 yd, Rattlecage Cauldron 7.4 yd,
Oathblade 7.5 yd, each keeping the height the realm's own record gives it), takes five extra
placings out (a Quivering Web and a Sturdy Arrow far from any marker, and three Apothecary's
Lantern rows whose marker the object of that name already answers), and restores the pair the
undead starting ground kept for its own starting NPCs exactly as the realm recorded it: Joshua's
Cherry Pie (90641) with the loot row its marker is named after, the Cherry Pie prop (90635) beside
it, and Maquel's Fallen Water Pouch (90642, empty, as the realm kept it).

The review that follows takes twelve stands out - two duplicates whose surviving stands are the
Ceremonial Mace (6940229) and Quivering Web (6940921) rows, and ten the review's own judgement.

The walk afterwards - the editing project's **45 changesets** (`spawns_20260926_*`, written on
2026-09-26), one save each, the last write to each guid winning - leaves **41 sheet pickups** at
the spots it verified, with the full authored quaternions the editor emitted, and re-creates three
of them (Long Fishing Spear, Interloper's Loop and Fallen Hardwood Plank) on the guids its own
editor allocates, 6960206-6960208. Six further stands the walk marked red are taken out, and four
Undercity creatures stand where the walk verified them. Scenery the walk nudged is moved without
its script or comment being touched, so the module's pickup census counts only what it should.
The zone's sheet reads **50 pickups**, and its Index row says the same.

Every row was read back from the live database: 429 assertions with none failing - each of the 36
written rows standing at the audited spot with the quaternion the editor emitted, the twenty-six
deleted guids gone, the re-created trio holding its entry under its new guid with the module's
script and its own loot row, and the four creatures standing where the walk left them.

### The final authored pass: Duskwood, item by item

`2026_09_25_48_worldforged_duskwood_pass_authored.sql` is the zone walked by hand in the map editor,
read from the editing project's **58 changesets** (`pro2`, written on 2026-09-25), one save each, the
last write to a row winning. The tract is Duskwood itself and the ten areas that stand inside it -
Raven Hill, Raven Hill Cemetery, Darkshire, The Darkened Bank, Brightwood Grove, Addle's Stead,
Beggar's Haunt, Vul'Gol Ogre Mound, Forlorn Rowe and Manor Mistmantle - and **48 pickups** stand in
it when the walk is done: **39 placed by hand in this pass** (the 30 rows below and the 9 placements
after them) and **9 that the earlier passes left standing**, each on the marker the realm map records
for it. Position and the rotation quaternion are the editor's own, digit for digit, and the
orientation column is written as the yaw that quaternion represents.

* **30 rows of this module were moved and/or turned, 27 of them by more than half a yard.** The
  furthest: **Sizzling Potion** (1345132, guid 6941088) 150.67 yd, out of the Westfall-side listing
  it stood on and onto the Vul'Gol Ogre Mound spot the editor gave it; **Axe of the Frostmane**
  (95514, 6940510) 115.73; **Catacombs Relic Torch** (90282, 6940226) 78.02; **Lantern of Endless
  Sorrow** (254366, 6941115) 50.22; **Darkshire Grave** (90272, 6940393) 33.56; **Spare Bag** (95821,
  6940709, the placing that hands out Lohgan's Best Bag) 26.40; **Catacomb Grave Dirt Pile** (90286,
  6940603) 24.90; **Suspiciously Brown Discarded Pants** (95824, 6941180) 23.78; **Fallen Warrior's
  Axe** (95942, 6940459) 19.56; **Silk Covered Spaulders** (95823, 6941083) 18.41; **Haren's Tankard**
  (1345067, 6940361) 16.46; and sixteen more from **The Dark Soul** (95822, 6941212) at 14.01 yd down
  to **Emerald Shard** 0.62.
* **11 rows turned**, the largest **Defias Night Blade** (90274, guid 6940342) **3.051 rad** (174.8
  deg), then **Sizzling Potion** 2.491, **Catacombs Relic Torch** 2.203 (126.2 deg), **Emerald
  Shard** 1.025, **Darkest Night Ring** (6940309) 0.448, **Suspiciously Brown Discarded Pants**
  0.333, **Nightwatch Circlet** (6940811) 0.301, **The Jitters** (6941215) 0.212 and three more below
  a tenth of a radian.
* **Three of the saves' own orientation columns disagree with the quaternion beside them**, and the
  file says so at each row: **Catacomb Grave Dirt Pile** (6940224, column 1.7031 against 2.0029),
  **Emerald Shard** (6940431, 0.9171 against 2.3663) and **Sharp Bone Necklace** (6930015, 2.2626
  against 2.5623). The quaternion is the field the client draws the model with, so the quaternion is
  what is written.
* **14 markers were emptied by hand**, and no guid of them is left in the world: Distant Wanderer's
  Pack (6940366), Emerald Shard (6940430), Grimtotem Totem (6940576), Holy Atal'ai Band (6940633),
  Ice Beard's Furled Finger (6940516), Lost Mountaineer's Bow (6940722), Racing Goggles (6941285),
  Resonite Band (6940952), Ritual Blade (6940705), Sharp Bone Necklace (6940905), Spear of Emerald
  (6941122), Will in the Casket (6940223), Wood Pile (6940862) and Woven Ceremonial Belt (6941354).
* **Eight of those fourteen stand again where the editor placed them, on guids this file allocates**,
  each keeping the loot row its object already had - the row hangs on the object, not the placement:
  **Spear of Emerald** (254369, guid 6960027), **Ritual Blade** (515438, 6960028), **Resonite Band**
  (254230, 6960029), **Woven Ceremonial Belt** (254231, 6960030), **Distant Wanderer's Pack**
  (254384, 6960031), **Lost Mountaineer's Bow** (95507, 6960033), **Will in the Casket** (90281,
  6960034) and **Sharp Bone Necklace** (90285, 6960035).
* **One placement is new rather than a re-placing.** The editor's save of 10:32:01 creates **Crimson
  Blade** (254562, guid 6960032) at -11232.0 -886.6 in the zone, and the object is written whole, with
  its comment naming the save that stands it.
* **Six markers are left nowhere else**: **Emerald Shard** (90290, was 6940430 at -10922.0 -516.5),
  **Ice Beard's Furled Finger** (95515, was 6940516 at -10691.8 -205.8), **Grimtotem Totem** (254227,
  was 6940576 at -9999.4 -1067.5), **Holy Atal'ai Band** (254368, was 6940633 at -10728.4 256.3),
  **Wood Pile** (90348, was 6940862 at -11192.0 -435.5) and **Racing Goggles** (515537, was 6941285 at
  -10753.1 426.7).
* **Two placements the zone's own sheet had missed are in it now**, both found by reading every
  changeset row against the world: **Sharp Bone Necklace** (90285, guid **6930015**, Raven Hill
  Cemetery), whose spawn row carries no `ScriptName` at all while its template carries
  `worldforged_pickup`, and **Crimson Blade** (254562, guid **6960032**, Duskwood).
* **Nothing that is not this module's is touched.** The same saves move two objects the world itself
  owns - **Bruiseweed** (guid 207693) and **Mageroyal** (guid 207604) - and the file names both in its
  header as deliberately left alone.

**How the numbers were checked.** Every statement is an UPDATE on a guid, a REPLACE on a guid the
file allocates, or a DELETE on a guid the editor deleted, so re-running it leaves the same rows; the
file was applied to the live database and applied a second time to prove it. Afterwards every row was
read back from the database one by one: **118 assertions, none failing** - each of the 30 moved rows
against its position, its rotation quaternion, the yaw that quaternion represents, its entry and its
script; the placement on guid 6930015 and each of the nine guids the file allocates, field for field;
and the absence of all fourteen removed guids. The worldserver applies the file itself on boot
(`Applying update "2026_09_25_48_worldforged_duskwood_pass_authored.sql"`), and the realm then reads
**99,470 gameobjects**, **2,822 worldforged pickups** over **1,662 distinct ids** and **1,805 pickup
templates**.

### The thirty-fourth pass: Westfall revised, walked in the map editor and reviewed on the sheet

`2026_09_25_54_worldforged_westfall_revision.sql` is not a marker pairing. Westfall was taken through
the map by hand this time, in the client's own editor: **41 changesets** written in the pro2 project
between 17:41 and 19:03 on 2026-09-25, each one a save of the zone - **34 rows re-placed, 4 objects
taken out of the client's own data and 3 objects placed on fresh guids** - and then the zone's own
sheet of `worldforged-items.xlsx` was marked up by hand: **41 rows green** (kept) and **45 rows red**
(out). This file is both halves read together, and where they disagree the review wins.

* **The green 41 are the rows that stay.** **35 of them were re-placed in the walk** - 33 the editor
  moved and/or turned, and 2 whose object it emptied at its old spot and placed again elsewhere in the
  zone, which take the guid the editor allocated: **6960037** for Defias Mage Stash in Moonbrook
  (entry 90252, from the Longshore spot at 1,187 yd) and **6960038** for Harvest Golem Scythe at The
  Dead Acre (entry 1345068, from The Molsen Farm). **5 the review kept exactly as they stood**: Defias
  Toe Knife, Field Boots, Flexible Gloves, Stolen Thunderbrew Flask and Worn Quel'thalas Heirloom.
  Position and rotation quaternion are what the editor emitted, down to the digit, and `orientation`
  is the yaw that quaternion represents. The zone's sheet now carries **40 rows**: the forty-first,
  the **Deadman's Signet** (515510), was moved out of the zone in the same walk - the editor emptied
  its Alexston Farmstead spot and placed it in **Raven Hill Cemetery**, in Duskwood - and its row went
  with it, to that zone's sheet, in walk order. It is the one row the walk took out of Westfall
  without the review taking it out of the world.
* **45 rows are gone**, every one of them marked red on the sheet by hand. **48 objects are deleted**
  for them, because three of the rows whose objects the editor emptied and placed again are among the
  green - 6940322 (Deadman's Signet), 6940347 (Defias Mage Stash) and 6940594 (Harvest Golem Scythe) -
  so their old spots go and their placements are written above. 44 distinct object entries stand
  behind the 45 rows. **The review has a shape**: every row it kept holds an item of **level 16 to
  25**, and **43 of the 45 it took out hold items of level 31 to 58** - the two exceptions being
  Defias Magus Staff (level 18, which the editor had also nudged in the same walk: a removal is the
  last thing said about a row, so the nudge is not written) and Rehomed Belt (level 25).
* **The review is a statement about the zone, not about the realm.** Those 44 entries hold **118
  spawns in 62 areas** across the world - Westfall's own 45 of them, then Longshore 9, Teldrassil 5,
  Thousand Needles 5, Swamp of Sorrows 3, Arathi Highlands 3, Darkcloud Pinnacle 3 and the rest - and
  **every one of them outside the zone is left exactly as it was**, in the world and in the book: the
  realm-map design gives each object one placement per realm map, and this zone gave up only its own.
  The book's other twenty-one sheets are unchanged, the two exceptions being the zone's own row and
  Duskwood's.
* **Four items lose their last carrier**, which is what the review asks for and is written down here
  rather than left to be found later: **Defias Magus Staff** (451117), **Drowned Diver's Ring**
  (515511), **Scuba Slayer's Blade** (515524) and **Rehomed Belt** (521266) each stood on one object
  in the world, and that object is gone. The other 43 items of the red rows keep carriers wherever
  their own realm maps put them.
* **Heavy Bone** (95819, guid 6940607) drew the Desolace giant's femur,
  `world\expansion07\doodads\desertzone\8des_bones_femur01.m2`, whose own bounding box in the
  client's `GameObjectDisplayInfo.dbc` is **26.1 yd long, 8.1 wide and 5.8 tall at size 1** - a
  landmark lying in the grass rather than a bone you pick up. Its size becomes **0.01**, a femur 26 cm
  long, which is the size the review asked for. That entry backs this one placement and nothing else
  in the world, so nothing else changes shape with it.
* **Four pickups stand in the zone that its sheet has never listed**, and they are neither kept nor
  taken out because the review never saw them: two rows of the realm's own, kept under
  `AscensionWorldforged ... | AtlasLoot Westfall` (**6930005** Defias Rusty Gun Rack at Moonbrook,
  **6930030** Zun'watha Cleaver at Longshore), and two a later pass restored on markers the earlier
  Westfall pass could not project (**6940755** Misplaced Pitchfork at Jangolode Mine, **6940915**
  Quarry Sledge at the Gold Coast Quarry). They are the only rows of the zone's 44 that are not on its
  sheet, and nothing was done to them; the zone's sheet lists 40 because the review's own set was 40,
  not because the zone holds 40.

**How the numbers were checked.** Every statement in the file is an `UPDATE` keyed on guid, a
`DELETE` keyed on guid, or a `REPLACE` on a guid the file allocates, so re-running it leaves the same
rows: the file was applied to the live database and applied a second time with no error. Afterwards
every claim was read back from the database one by one (`.scratch/wf24/check.py`): **198 assertions,
none failing** - each of the 33 moved rows standing at the position and quaternion the changeset
emitted with its `orientation` the yaw they mean, each of the three new guids holding its entry at the
spot the editor left it with the module's script and its own in-game note and still handing out its
item, all 48 removed guids gone, the five kept rows still this module's pickups, the zone's areas
holding exactly the 40 reviewed rows plus the 4 its sheet never listed, the world outside the zone
holding the same 2,732 pickups it held before plus the signet where the walk put it in Duskwood,
Heavy Bone's template at 0.01 with that entry backing one placement, and the items of the removed rows
counted to name the four whose last carrier they were. The book was then read back against the world
as well (`.scratch/wf24/book_vs_live.py`): **279 assertions, none failing** - every row's object,
entry, coordinates, facing, sub-zone and teleport command the world's own, the 35 authored rows marked
complete and the 5 kept ones left as they were, no red row anywhere on the zone's sheet, Duskwood's
sheet carrying the signet in walk order with every row it carried before saying exactly what it said,
and every other sheet of the workbook identical to what it said before the review. The file is
idempotent and the worldserver applies it on boot. The realm then reads **99,431 gameobjects**,
**2,777 worldforged pickups** over **1,688 distinct ids** and **1,834 pickup templates**.

### The thirty-fifth pass: Westfall cross-checked against the reference realm

A gameobject dump of the live reference realm the book's atlas was drawn from
(`GameObjects-Bronzebeard(1).zip`, its `curated/dump_Westfall.csv`) stands **30 worldforge pickups in
Westfall**; twenty of them this world already stood within 0 to 15 yd of where the dump puts them.
Of the ten it held that the zone did not, four are the Travel Sack and the Defias Magus Staff the
review of the same day took out on purpose and four are books and chests this world's earlier passes
had restored into other zones - the dump puts **Evil Chest** in The Dust Plains, **Light and Shadow
Vol: 1** on Sentinel Hill and **Ancient Priest Tome** in Moonbrook, and all three stand **empty** -
no loot row at all, on either realm - so they are left out: a pickup that gives nothing is scenery,
not a pickup. `2026_09_25_55_worldforged_westfall_missing.sql` restores the dump's four remaining
Westfall pickups, each with the loot row it already carries and none handing out a mystic scroll -
the four armour pieces are class 4:

* **Salma's Summer Wardrobe** (95777) at Saldean's Farm, handing out Salma's Summer Dress (515677) -
  at the spot and with the rotation the map editor re-authored the same evening
  (changeset `spawns_20260925_214907.sql`, quaternion -0.880449588 / 0.474139772);
* **Unlocked Chest** (95809) at Saldean's Farm, handing out Field Trousers (450775);
* **Heavy Stompers** (95817) at Stendel's Pond, handing out Heavy Boots (450721);
* **Stolen Supplies** (518322) by Sentinel Hill, handing out Rehomed Belt (521266).

An earlier draft of the file also stood **The Law of Light** (111000) in The Dagger Hills, handing
out the item of its name; it is not wanted and the file as it now stands takes that spawn back out,
so a database that ran the draft and one that runs only this file end in the same state. Every
template and loot row is restated in the file, so it stands alone; it is idempotent, it was applied
to the live database twice by hand and a third time through the worldserver's boot path
(`Applying update ... '785987E'`), and `.scratch/wf24/check_missing.py` read every claim back:
**61 assertions, none failing** - each spawn at its intended spot, Salma's Wardrobe carrying the
editor's quaternion, each with its loot row and no mystic scroll among the items, the three empty
objects gaining no new spawn anywhere, The Law of Light's guid gone, and the realm reading
**99,435 gameobjects** and **2,781 worldforged pickups**. The zone's sheet follows: **44 rows**,
the four restorations marked complete, and the items no pickup in this world hands out drop from
sixteen to twelve.

### The nineteenth pass: Dun Morogh and Coldridge Valley, paired marker by marker

`2026_09_23_16_worldforged_dun_morogh.sql` is the pass that moved the marker set itself, and
`2026_09_23_17_worldforged_subzone_markers.sql` carries the repair that followed from it. The map
keeps a page of its own for its sub-zones - the Grizzled Den, Coldridge Pass, Chill Breeze Valley,
Gol'Bolar Quarry, Jangolode Mine, Gold Coast Quarry, Blackrock Mountain, Northshire Valley and
thirty-two more - and those pages carry **380 markers between them**. The bounds table the earlier
passes projected markers through had no rectangle for any of those pages, so every one of those
markers was invisible to them. With the complete set, **twenty-one of them stand in Dun Morogh and
Coldridge Valley**: the Grizzled Den's own chests, at the back of the zone by Chill Breeze Valley
and the pass.

Two consequences, both fixed before this pass was applied:

* **five rows the earlier passes dropped are put back** (`..._17_worldforged_subzone_markers.sql`):
  Misplaced Pitchfork (515224) on the Jangolode Mine marker of its name, Quarry Sledge (95785) on
  the Gold Coast Quarry one, and Blackbreach Handaxe (686898), Darkest Night Ring (90288) and
  Taskmaster's Blade (254660) on Blackrock Mountain's. Each is written back with the guid it had, on
  its own marker, so a database that has already run the dropping migrations and one that has not
  both end in the same state.
* **the new pass's own drop list was corrected before it ran**: it did not exclude the rows the
  pass had already decided about, and two it had just moved onto their markers (Forgewright's
  Scepter, Obsidian Axe) were listed for deletion as well. Every previously applied zone file was
  swept for the same overlap afterwards; all clean.

The zone's own page lists **83 markers** in Dun Morogh and Coldridge Valley together - **74 real
placements** and **9 cluster labels** over drops. After the pass:

* **70 placements stand 0.0 to 2 yd on the marker of the object's own name**.
* **four stand on the twin listing the map plots a few yards away under the item's name** and are
  moved onto the marker of the object's own name, each keeping the height the realm's own record
  gives it: Miner's Pickaxe (3.9 yd, height 361.82, which the realm recorded 2.9 yd away),
  Frostwalker's Boots (4.1 yd), Radiant Helmet (4.9 yd) and Forgotten Sack (4.9 yd, height 408.38,
  recorded 3.5 yd away).
* **nothing is removed**: every pickup standing in the zone honours a marker of its own object or of
  the item it hands out; the zone holds 69 pickups, 69 distinct objects, each with its loot row.
* **three markers name objects this world never carried**, and all three are restored field for
  field from the realm's own client-cache records, each standing where the realm's own client saw
  its chest: **Adlin's Cherry Pie** (entry 90639, standing 0.5 yd from its marker, its loot row
  handing out the item the marker is named after, 694541 - and because the chest the realm recorded
  is its own *invisible* one, display 980926, the visible Cherry Pie prop it stood beside, entry
  90635 display 5493, is restored with it, guid 6942485), **Brynja's Water Pouch** (90640, display
  1033132, 1.2 yd, handing out 969160) and the **Black Powder Barrel** (93002, display 30, 2.7 yd,
  keeping the loot-table id its own record names because no source held records the item it held).

**Heights inside the caves.** Nineteen of the zone's rows read 6 to 150 yd from the terrain the
worldserver reads - eighteen of them under it and one, Officer's Pike, 11.5 yd over it - which is
what an interior looks like: the Grizzled Den, Chill Breeze Valley and the Frostmane caves are all
under the zone's surface. Fourteen of them carry the height the realm's own client recorded for
that object (eight of those agreeing within 3 yd, the other six within 25). Five have no sighting
of their own object near them, and their height is read from the realm's own occupants instead of
from the terrain:

* **Forsaken Cart Crate** (356.0), **Phylactery Shard** (354.3) and **Skeletal Club** (365.1) stand
  in the Frostmane cave, where the realm's own Wendigos stand at 353.4 to 358.3 within 40 yd, its
  Copper Vein nodes at 354.3 to 361.6, and its Battered Chests at 354.3 and 354.9 - the vein 9.7 yd
  from the Skeletal Club reads 365.5 against the row's 365.1. The realm's own record of each of
  these three chests is in the Tirisfal Glades or the Western Plaguelands, where its other placing
  stands; in this cave the floor is the one its occupants share.
* **Edan's Stripe** (350.5) stands 32.9 yd from the realm's own chest 95513 (346.9), the floor of
  the same chamber; **Warm Mug** (391.5) is 30.4 yd from the realm's own record of its own entry
  95508 (392.7, agreeing to 1.2 yd).

Its appearance is a record too: no row in the zone carries the placeholder, and the one that does
by design - Adlin's Cherry Pie's own chest, which the realm itself recorded as invisible - stands
with the visible prop restored beside it.

### The eighteenth pass: Burning Steppes, paired marker by marker

`2026_09_23_15_worldforged_burning_steppes.sql` is the first marker-by-marker pass that also had
to move and remove. The page lists **78 markers**, of which **74 are real placements**, **two name
nothing in any source held** and **two are cluster labels**. The zone held 77 pickups before it;
after it, **73 stand 0.0 to 2 yd on their marker** and one is kept where the realm's own record
puts it.

* **three placements stood a few yards off and are snapped onto their markers**: Half Buried Chest
  5.7 yd, Forgewright's Scepter 3.8 yd, Obsidian Axe 3.3 yd. Each of those markers' own spots is
  corroborated by the realm's own dump, which sees those chests 0.7, 0.6 and 0.8 yd from it.
* **Half Buried Chest is a placement the map records twice**: its Burning Steppes page plots 'Half
  Buried Chest' at -7481.9 -2272.4 and its Badlands page plots the same chest as the item it hands
  out, 'Focusing Spirit Band', 5.7 yd away. The realm's own dump sees the chest at -7481.6 -2271.9
  - 0.7 yd from the Burning Steppes marker and 6.1 yd from the Badlands listing - so the pickup
  stands where the realm had it, and the Badlands page's twin is left to that zone's own pass.
* **one placement is kept**: Obsidian Boltthrower stands 5.2 yd off its marker, while the realm's
  own record for that chest agrees with the pickup rather than with the marker (3.4 yd off it).
* **three rows stood on no marker of any page and are removed**: Blackbreach Handaxe (127.7 yd away),
  Darkest Night Ring (85.6 yd) and Taskmaster's Blade (120.7 yd). Each is a second spawn of an
  entry whose other spawn stands on the realm's own recorded spot (1.2, 1.1 and 4.4 yd from it),
  so removing them takes out a duplicate the pin-based build left behind and loses no documented
  placement.
* **two markers name nothing in any source in hand**: 'Charred Corpse' (no object of that name, no
  loot pin, and nothing of the realm's own within 60 yd at all) and 'Burning Heat' (no object of
  that name; its own Conquest of Azeroth pin 2.0 yd away names *Mystic Scroll: Cataclysmic
  Sundering*). Nothing is invented for either.
* **two cluster labels**, `Worldforge Drops (2 items)`, over the Firegut camp.

### The seventeenth pass: Redridge Mountains, paired marker by marker

`2026_09_23_14_worldforged_redridge_mountains.sql` moves nothing and removes nothing: the page
lists **39 markers**, and all **thirty-one** of them that this world has an object for stand 0.0 to
2 yd on it, with no pickup in the zone standing on no marker of any page. Its other **eight**
markers are objects the realm had and this world does not carry; every one of them is in the
realm's own client-cache dump and in the archive's world-object index:

* **five are Mystic Scroll chests** - the item a Conquest of Azeroth loot pin within four yards of
the marker names, and that family is out of scope, so nothing is invented for them: Codex of
Divine Mending (99018, display 184777) *Mystic Scroll: Promise of Renewal* 1.9 yd, Drowned
Adventurer (101911, display 980926) *Mystic Scroll: Divine Reprieve* 3.1 yd, Cultivated Blazethorn
(735923, display 1010579) *Mystic Scroll: Sudden Aftermath* 3.1 yd, Pilfered Shield (90210, display
1011608) *Mystic Scroll: Revengeful Block* 3.7 yd, Redfang's Cache (835953, display 336) *Mystic
Scroll: Stalker's Mark* 3.5 yd.
* **three have no item record in any source inside sixty yards**, so nothing is invented for them
either. Each is a chest the realm's own dump sees standing on its marker: Flourishing Flowers
(1190585, display 1060657) 0.5 yd, Shadowbound Doll (95024, display 1046185) 0.6 yd, Maddening Aura
(101913, display 515662) 1.2 yd - the nearest pin to either of the last two, 37 and 43 yd away,
belongs to the treasure those yards away and not to them.

**Redfang's Cache** is the one the realm's own records can restore, and is: the map plots the
marker at -9793.4 -2219.1, the realm's own dump sees its chest (entry 835953) **0.5 yd** from that
spot, and a Conquest of Azeroth loot pin **5.5 yd** from it names **Melika's Ring** (item 500813).
The object is written as the realm's own client cache holds it - its own entry and name, display
336 (the crate the realm uses for 35 of its chests), its cast bar, the chest lock 1689 and its own
loot-table id 835953 - and the loot row hands out that one item, which is this module's shape: one
pickup, one item. The chest's own loot table is a server-side table this world has never carried,
so it cannot be read; the realm's loot pin is what ties the item to the spot, and the chest's other
pin, a Mystic Scroll, is out of scope with the rest of that family. Its spawn (guid 6942481) stands
on the marker at the terrain's own height, which agrees with the realm's record for that chest to
2 cm.

### The sixteenth pass: Swamp of Sorrows, paired marker by marker

`2026_09_23_13_worldforged_swamp_of_sorrows.sql` holds **no statements**: this zone needed no
change, and the file exists so the check has a record beside every other zone's. The page lists
**68 markers**:

* **64 real placements, and all 64 stand 0.0 to 2 yd on their marker** - the first zone in which
nothing at all was off. Nethergarde Mining Cap is one placement the map records twice: at this
pickup's own spot on its Swamp of Sorrows page (0.0 yd) and 10.1 yd away on its Blasted Lands page.
* **one object the realm had and this world does not**: 'Paladin Corpse' (object 93024, six
sightings, filed by the realm under DeadwindPass and SwampOfSorrows) stood 0.7 yd from the marker,
but Ascension's own record of it is the invisible placeholder model and no loot pin within 60 yd
names anything it held. Nothing is invented for it.
* **one name no source held knows**: 'Travel Cloak'. No object of that name exists, no loot pin sits
under it, and no item called Travel Cloak is handed out by any object, creature or reference table
in this world.
* **two cluster labels**, `Worldforge Drops (2 items)`.

All **58 pickups** standing in the zone sit within 3 yd of a marker of their own object name or of
the item they hand out; they are 58 distinct objects, no two within 0.5 yd, and every one holds its
loot row. Their appearance is a record: 51 carry the entry's own record from the realm's client
cache, five whose record there is the invisible cube (Holy Atal'ai Band, Defiled Necklace,
Dusksinger Band, Ruby Giant's Eye, Long-Abandoned Circlet) carry the same-name counterpart of the
appearance migration's tier C, and two (Sentinel Wrap, Unusual Emerald Scales) carry the archive's
own catalogue value, tier K. No placeholder stands in the zone. Nine rows read 8 to 135 yd from the
terrain reader's surface, every one of them at a height the realm recorded for that same object:
five in the Sunken Temple's undercroft (Atal'ai Alchemy Supplies, Kazkaz's Ceremonial Mask, Sunken
Axe, Sharpened Dragon Bone, Shoulderguards of the Ancient Prophet), one in the mine under
Nethergarde (Nethergarde Mining Cap), and three on shelves or ledges of the swamp itself (Mire
Leaves, Defiled Necklace, Splinterspear Armor Crate).

The map's double listings appear here too, and are left as the map has them: **eleven** of the
zone's pickups are the second page's listing of an object whose other listing the realm's own pins
corroborate - six across the Deadwind Pass border about 1,320 yd north (Long-Abandoned Circlet,
Ogrish Handaxe, Foreboding Banner, Dark Scythe, Cursed Branch, Ancient Formula), three in the
Badlands some 5,100 yd east (Gravesword, Ramshackled Crate, Real Big Bone), one in Westfall 4,410 yd
away (Klaven's Wardrobe) and one in Mulgore 9,154 yd away (Discarded Wagon Wheel). Two pickups,
Arcane Tinged Water and Sentinel Wrap, have no corroboration at either end and stand because the
page plots them.

## How it works

| Piece | Where |
| --- | --- |
| Marker: every pickup carries `ScriptName = 'worldforged_pickup'` | `gameobject_template`, `gameobject` |
| Ledger: `acore_characters.character_worldforged_loot (guid, spawn_id, entry, looted_at)` | `data/sql/db-characters/` |
| `WorldforgedPickupAI` | `src/WorldforgedPickups.cpp` |
| Core hook: `GameObjectAI::BuildClientFlags`, called from `GameObject::BuildValuesUpdate` | `src/server/game/` |

* **Sparkle**: a pickup this character may still loot gets
  `GO_DYNFLAG_LO_ACTIVATE | GO_DYNFLAG_LO_SPARKLE` - that is how they are found in the world.
* **Spent, for one character's current prestige cycle**: a pickup this character already looted stays visible
  (as on the realm) but is given `GO_FLAG_LOCKED | GO_FLAG_NOT_SELECTABLE`, so it cannot be
  opened again. Every other character still sees it sparkling and lootable.
* **Prestige**: the prestige save transaction carries the deletion of only this character's
  ledger rows. Once that transaction has committed, the in-memory ledger is cleared and nearby
  pickup flags are refreshed; if the character database rolls the save back, the ledger stays
  spent in memory and in the database. Pickup awards and the prestige save commit synchronously
  so earlier claims finish before the reset, and the reset finishes before a new claim.
  Relogging preserves the new cycle; ordinary level changes leave spent pickups locked.
* **Recording**: the pickup is recorded the moment its base item reaches a character, by any
  of the three paths that hand one out: `OnPlayerLootItem` (clicked, auto-stored or picked from
  the group window), `OnPlayerGroupRollRewardItem` (won by a Need or Greed roll) and
  `OnPlayerMasterLootItem` (given by the master looter). A pickup whose template sets group loot
  rules (`Data15 = 1`, Redfang's Cache) hands its item out through the last two in a group.
  The item and the ledger row are written in one character-database transaction, so a crash
  cannot mark a pickup spent without the item it was spent for.
* **`OnAllowedForPlayerLootCheck` refuses the item itself** for a character who has already
  looted this pickup. This is the one that closes the remaining hole: a loot session that
  outlives its claim. The chest holds a single shared loot, so the next character's open
  re-rolls it under the first character's still-open window, and `Player::StoreLootItem`
  would otherwise hand over a second copy to whoever clicks the slot first. Note that the
  core's hook reads backwards: `ScriptMgrMacros.h` treats a script returning `true` as a
  refusal, so true is what withholds the item.
* **Four server-side refusals in total**, because a client can always ask anyway:
  `BuildClientFlags` (what this viewer is shown), `GossipHello` (whether the use opens
  anything - `GameObject::Use` returns before `SendLoot`), the loot-slot check above (whether
  the item may be handed over), and `OnStateChanged` (which opens nothing, and clears a spent
  loot the player left open).

Identity is the **spawn id** (`gameobject`.`guid`), never the runtime object GUID: this core
uses map-local generated GUIDs (`Map::GenerateLowGuid`), which are neither the database row
nor stable across grid reloads. The restoration writes its spawns in the fixed block
6900001+, so ids stay stable across re-imports.

## Requirements

1. **The client's gameobject display table.** A spawn whose `displayId` is missing from the
   server's `Data/dbc/GameObjectDisplayInfo.dbc` is thrown away at load:

   ```
   Gameobject (GUID: 6900001 Entry 1344099 GoType: 3) has an invalid displayId (87226), not loaded.
   ```

   A stock table holds 3,792 rows; CoA's client ships 120,871, and the restored pickups use
   1,009 ids from it. Against the stock table 1,489 of 1,510 pickups never reach the world and
   the world stays empty however good the data is (it also silently drops ~1,222 stock objects).
   Extract the client's DBC set with the [client DBC tool](../../apps/coa-dbc/README.md) and copy
   it into the worldserver's `DataDir/dbc`; it includes this table.

2. **The SQL applied.** With `Updates.EnableDatabases = 7` (all three databases) the core
   applies `data/sql/db-world/` and `data/sql/db-characters/` at startup by itself; use `6`
   if you want the characters and world databases only. `1` is the auth database alone and
   would leave the migrations unapplied. On a repack that runs with the updater off, apply
   the files by hand, exactly as they are:
   `data/sql/db-world/2026_09_16_00_worldforged_pickups.sql`,
   `data/sql/db-world/2026_09_22_00_worldforged_pickup_spawns.sql`,
   `data/sql/db-world/2026_09_22_01_worldforged_missing_pickups.sql`,
   `data/sql/db-world/2026_09_22_02_worldforged_crossrealm_spawns.sql`,
   `data/sql/db-world/2026_09_22_03_worldforged_appearance_and_ground.sql` and
   `data/sql/db-characters/2026_09_16_00_worldforged_loot.sql`. The world files are
   idempotent: the templates and loot rows are written with `REPLACE INTO` (keyed on `entry`,
   and on `Entry, Item`), each block of spawns is preceded by a `DELETE` on its own `guid`
   range, the map corrections and the appearance and height fixes are `UPDATE`s on their own
   entries and guids - so re-applying any file is safe, twice in a row or a hundred times.
   Appearance and height are read at startup with the rest of the world, so a placement that
   moves needs a worldserver restart to be seen.

## Verify it went in

Boot log:

* `>> Loaded <n> Gameobjects` - equal to `SELECT COUNT(*) FROM acore_world.gameobject`, so
  nothing was skipped for a display id
* 3,784 C++ scripts with this module loaded (`GameObjectScript`, `GlobalScript`,
  `PlayerScript`)
* no `Script named 'worldforged_pickup' is assigned in the database, but has no code!`
* no `has an invalid displayId (...)`, and no invalid-rotation warnings

```sql
SELECT COUNT(*) FROM acore_world.gameobject WHERE ScriptName='worldforged_pickup';              -- 4116
SELECT COUNT(DISTINCT id) FROM acore_world.gameobject WHERE ScriptName='worldforged_pickup';     -- 1715
SELECT COUNT(DISTINCT map) FROM acore_world.gameobject WHERE ScriptName='worldforged_pickup';    -- 30
SELECT COUNT(*) FROM acore_world.gameobject_template WHERE ScriptName='worldforged_pickup';      -- 1742
SELECT COUNT(*) FROM acore_world.gameobject_loot_template WHERE Comment LIKE 'AscensionWorldforged%';  -- 1742
-- appearance: an invisible placeholder is what a bare sparkle looks like
SELECT COUNT(*) FROM acore_world.gameobject_template WHERE ScriptName='worldforged_pickup' AND displayId=980926;  -- 0
SELECT COUNT(*) FROM acore_world.gameobject_template WHERE ScriptName='worldforged_pickup' AND displayId=0;       -- 0
```

In play: `.go xyz -8769.1 -174.1 83.9` (Wax Stained Bag, 185 yd from Stormwind). It should
stand on the ground with its own prop visible, sparkle, hand over its own base item once, and
then be inert **for that character** while another character still sees it sparkling. A
character's ledger:

```sql
SELECT * FROM acore_characters.character_worldforged_loot WHERE guid = <character guid>;
```

## Two things that only show up in play

* **When the ledger is read matters.** It is read in `Player::LoadFromDB`, not in
  `OnPlayerLogin`. The core sends a player the gameobjects around them before
  `CharacterHandler` calls `OnPlayerLogin`, so a ledger loaded at login arrives after the
  client has already been told the pickup sparkles and can be opened - and nothing corrects
  it, because the object's own state never changes. The symptom is: loot a pickup, log out
  and back in, and it is glowy and clickable again (the server still hands over nothing).
  Loaded during `LoadFromDB`, the first update a player receives already carries the right
  flags.
* **A loot window closed by logging out leaves the object `GO_ACTIVATED` with empty loot**,
  and `Player::SendLoot` only re-rolls a chest that is `GO_READY`. `OnStateChanged` notices
  the spent loot and re-arms the object for that character - once, guarded, never in a loop -
  so an abandoned loot window cannot deny the next character their item.

## Why the pickups can be re-looted at all

The data deliberately sets `Data3` (consumable) to `0` and `Data2` (restock) to `0`. A
consumable chest despawns on loot and returns on a respawn timer - that would make a pickup a
realm-wide roll per respawn instead of one open per character per prestige cycle. Non-consumable keeps the object
in the world for everyone, and the core re-rolls its loot for each new opener:
`Player::SendLoot` clears and re-fills the loot while the object is `GO_READY`, and
`GameObject::Update` puts a chest back to `GO_READY` once a loot is released.

No respawn timer is involved either, so none is invented: the spawns carry
`spawntimesecs = 0`. `GameObject::LoadGameObjectFromDB` copies that into `m_respawnDelayTime`,
which is only consulted when something despawns the object - and for a chest with
`consumable = 0` the deactivation branch sets `GO_READY` and returns before it can schedule a
respawn. Any other value would be dead data; 0 also happens to be what
`ObjectMgr::LoadGameobjects` accepts silently, since it only reports a zero spawn time as an
error when `IsDespawnAtAction()` is true and for a chest that is `chest.consumable`.

## Placement: where the positions come from, and what is not recoverable

Positions are the archive's per-object observations - one world XYZ each, the object's own
coordinates, not the looter's. Two independent checks say so: the realm's own dump records,
for each item, the distance from the loot position to the nearest object of that entry, and
that distance equals the distance from the loot position to the observed position (median
difference 0.0 yd, 89% within 1.5 yd, n=2,954); and where a placement is more than 10 yd from
the dump's loot position it is re-anchored to it (13 spawns). Heights are the observation's
own, corroborated by the dump's stored object height (175 of 182 spawns that sit >15 yd below
this repack's terrain grid - real interiors - agree within 1.5 yd).

**Facing is not recoverable.** None of the six sources available holds the realm's own
orientation for these objects: not the client's gameobject cache, not the realm's catalog
export (its `gameobject_spawn` table is empty and has no orientation column anyway), not the
community position dumps, not the archive atlas. Each restored spawn therefore carries a
stable per-object facing with the matching unit quaternion
(`rotation0 = rotation1 = 0`, `rotation2 = sin(a/2)`, `rotation3 = cos(a/2)`, the convention
the rest of `gameobject` uses). Stable rather than random so a re-import reproduces the same
world. A zero quaternion - what the captures actually carry - is not unit length and the core
rejects it row by row.

## Undo

```sql
SOURCE data/sql/manual/worldforged-pickups-revert.sql;
DROP TABLE IF EXISTS acore_characters.character_worldforged_loot;
```

The undo lives under `data/sql/manual/` rather than beside the migration because it *deletes*
rows from `gameobject_template`, which the repository's SQL lint asks updates never to do.
All three migration files pass that lint; the undo is the one file that deletes on purpose.

To re-test one pickup from scratch, clear the character's row and re-log (the module drops its
in-memory copy on logout):

```sql
DELETE FROM acore_characters.character_worldforged_loot WHERE guid = <character guid>;
```
