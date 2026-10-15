# mod-woodworking

Restores the Woodcutting (skill 732) and Woodworking (skill 757) professions:
the harvestable trees, the logs they pay, and the skill gate that makes the
profession advance.

The module is data only. The behaviour lives in the core, which already had
everything the profession needs except one mapping: `SkillByLockType()` did not
know the woodcutting lock type, so the eighteen woodcutting locks were treated
as "no skill required", which both let anyone harvest a tier they had not
trained and stopped the profession from ever gaining a point. With
`LOCKTYPE_WOODCUTTING` (lock index 24) mapped to `SKILL_WOODCUTTING`, opening a
tree behaves exactly like a herb or an ore node: the lock's own required skill
is enforced, one skill-up is granted per node per respawn, and the loot is
handed out through the ordinary chest path.

## What the trees are

Every tree is `gameobject_template` type 3 (chest) with

* `Data0` = lock 1876-1893, the woodcutting ladder. `Lock.dbc` gives those
  eighteen locks `Type 2` (skill lock), `Index 24`, and a required skill of
  0, 50, 75, 100, 125, 150, 175, 200, 225, 250, 275, 305, 325, 350, 375, 400,
  425, 450.
* `Data1` = its own loot table.
* `IconName` = `AxeCursor`, `castBarCaption` = `Collecting`, display 170000+ or
  a zone's own tree model.

The player harvests with the Woodcutting spells (`13977859` and its rank-ups
`13977882`-`13977884`, learned from the Book of Artisans trainers) and refines
the logs into planks at a sawmill - one of the realm's twenty marked spots, or
anywhere a portable sawmill has been placed. See "Where a sawmill is" below.

The recipes are not bought anywhere, because no other trainer in the realm
carries a row for skill 732 or 757: the trades have no trainer to buy one from,
and the book teaches only the ranks. `Refine Forestwood Plank` and
Woodworking's three Forestwood intermediates are marked learned on skill value
by the client itself; `WoodworkingRecipePlayerScript` is the same thing for the
rest, reading the list out of the client's own `SkillLineAbility` at startup and
learning each recipe as the skill reaches it. The gate is the skill the client
declares for the recipe - its `MinSkillLineRank` where that is above 1, which is
how the four Refine planks above Forestwood are gated (65, 125, 165 and 230),
and its `TrivialSkillLineRankLow` otherwise, which is where the wood tiers sit:
Forestwood from 10, Wildwood from 60, Everwood from 115, Grovewood from 165,
Heartwood from 220. The whole ladder is therefore reachable without a shop: 106
Woodworking recipes and four Refine spells, on top of the four the client grants
on its own.

## Provenance

The templates and their ladder positions are recovered from the client
gameobject caches of the live realm, not authored. Every template below was
cross-checked against the core's own `SMSG_GAMEOBJECT_QUERY_RESPONSE` layout,
and the recovered set reproduces 2826 cached templates of the local realm byte
for byte against the world database it was validated on.

Recovered exactly: entry, type, display, name, icon, cast bar, size, the lock
ladder position, the loot id, and the open counts.

Authored, because no live record of it survives: the contents of the loot
tables (the log each ladder step pays and the chance of a magical log) and the
tree spawn positions. The logs are assigned by the ladder step the tree sits on and
by the item level the log itself carries, which is what fixes Forestwood to the
lower steps and Heartwood to the upper ones; the magical logs are the same
family's rare variant.

Every zone's nodes stand on that zone's own trees. Elwynn is the reference: its
45 nodes sit 3 yards from a real `ELWYNNTREEMID01.M2` doodad, each one inside a
clump of at least two neighbours within 25 yards, chosen from the 766 unique
placements by farthest-point sampling so the clumps cover the zone (nodes end up
at least 106 yards apart). Stepping off the doodad origin keeps our own tree
model out of the vanilla one - the chosen step clears every other doodad by 2.7
yards or more - and the node's height is the doodad's own base height plus the
terrain's rise across that step, which puts it on the ground without trusting the
map file's absolute height.

The other 28 zones are placed by that same rule, applied to every tree the zone's
map data actually carries rather than to one model: a node stands on the closest
ring around a real tree doodad that keeps half a yard clear of every other solid
doodad's footprint, and its height is the anchor's own plus the terrain's rise
across that step, clamped to three yards. A giant anchor starts its ring at the
tree's footprint instead of at three yards, which is what Teldrassil and Felwood
need, being all giants. Effect doodads are not obstacles - wisps, smoke and steam
have no footprint to collide with.

Every candidate position is also tested against the zone's own `WorldMapArea`
rectangle. The tiles along a zone's edge are shared with its neighbours, so a tree
found near one can belong to the next zone along, and without that test a node
placed off it lands in the wrong zone entirely; with it, all 45 nodes of all 29
zones are inside the zone they are for.

The spawn rows are the third authored file, and they own a guid block: `8000000`
to `8200000` is this module's, and the file clears the whole block before it
writes its 1305 rows, so a re-apply always leaves exactly the nodes above and
never touches another module's objects. Three of the 32 templates - the three
`Scadeald Tree` rows, displays `300529`-`300531` - carry no spawn yet, and they
are the only templates in the file without one.

## Ladder to log

| Lock | Required skill | Log |
| --- | --- | --- |
| 1876, 1877 | 0, 50 | Forestwood Log (8210210) |
| 1878, 1879, 1880 | 75, 100, 125 | Wildwood Log (8210211) |
| 1881, 1882, 1883 | 150, 175, 200 | Everwood Log (8210212) |
| 1884 | 225 | Grovewood Log (8210215) |
| 1885, 1886 | 250, 275 | Heartwood Log (8210217) |

The Outland and Northrend ladder steps (1887-1893) carry no tree in any cache
we hold: this realm's world data stops at Winterspring. `Fel Iron Wood`
(8210218), `Adamantite Wood` (8210219) and the TBC ores behind them are left
for whoever extends the ladder outward.

## Where a sawmill is

Woodworking's five Refine spells carry `SpellFocusObject 1653`, which
`SpellFocusObject.dbc` names "Sawmill". Nothing in this repository ever
supplied one, so the profession could not be used at all, and the client's own
answer is that a sawmill is a *place*: twenty spots are published as pins in
`Interface/FrameXML/Ascension_POI/StaticPOIs/GameObjectPOIs.lua` (the
`Sawmill-*` map entries, each with an exact position and map id) with a
`MINIMAP_TRACKING_SAWMILL` tracking entry of their own. They land on the
realm's lumber camps - the Westfall Woodworker camp, Durotar's `Logsplitter`,
the Stranglethorn `Splinter Guard`, the Scarlet Worker camp in the Western
Plaguelands, and so on - and on the live realm refining worked at them with
nothing drawn there. The pins carry no height; the heights used here come from
the server's own extracted terrain - the `*.map` height fields the worldserver
loads, 129x129 samples to the tile - with Orgrimmar's taken from its neighbours
because that pin stands on a WMO floor above the raw canyon.

The core answers a focus by searching the caster's grid for a gameobject
(`Spell::CheckSpellFocus` -> `Acore::GameObjectFocusCheck`), so a place cannot
satisfy it as it stands - and nothing should be put in the world to make it, or
the workbench the realm never had would start being drawn at twenty camps.
Instead the core now asks scripts before it searches:

```
Spell::CheckSpellFocus -> ScriptMgr::OnSpellFocusAnswered(spell)
```

`src/woodworking.cpp` answers true inside `SAWMILL_SPOT_RANGE` (40 yards) of any
of the twenty coordinates, and only for the spells that carry focus 1653 -
exactly the five Refine spells. Anywhere else it answers false and the core's own
search runs, which is what lets a sawmill a player has actually placed count:
`mod-portable-sawmill` owns the two real focus objects (`2201004` Portable
Sawmill and `2201005` Compact Portable Sawmill) that the shop item and the
Tinker's spell place, and those answer the cast wherever they stand. The marked
places are the profession's home, not its only location.

The spell's own `RequiresSpellFocus` is deliberately left at 1653. The server
sends that field with a refused cast and the client fills the name in from it, so
a Woodworker who tries to refine away from a sawmill reads **"Requires
Sawmill"**. Clearing the field - the first version of this gate - made the
server print the raw `Requires %s` instead, nameless, which is a worse thing to
hand a player than no refusal at all.

Where the spots are, and how far they reach, is the `SawmillSpots` table and
`SAWMILL_SPOT_RANGE` in `src/woodworking.cpp`.

### The Elwynn pin, and the one pin that moved

Two of the client's pins stand on the lumber NPC the camp is built around: the
Westfall pin is 2 yards from the `Westfall Woodworker` (6670) and the
Stranglethorn north pin 11 yards from a `Venture Co. Lumberjack` (921). The
Elwynn pin was the exception - `-9545.3, -1401.1`, 145 yards of empty ground
southeast of the Eastvale Logging Camp, where `Terry Palin` (1650, the lumber
vendor) and the `Eastvale Lumberjack` (1975) stand. That place is the camp, so
the spot is now `-9404.85, -1343.52, 50.11` and the whole camp - vendor and both
lumberjacks - works.

The *marker* needs no client change, even though the client draws it: the pins
are not client data. The client's pin store `DB_MapPOI`
(`Interface/FrameXML/Data/MapPOI.lua`) is rebuilt from what the server sends -
the JSON channel Extensions.dll opens on `SMSG_COA_AREA_POI_PAYLOAD` (0x77C,
category `AREA_POI_PAYLOAD`) - and its `CreatePOI` removes any pin already
holding the incoming ID. So `WoodworkingSawmillPinPlayerScript` sends one POI
per login under the client's own pin key, `Sawmill-Elwynn-Forest`, at the camp,
and that replaces the client's static pin: the file inside `Data/patch-B.MPQ`
still says `-9545.33, -1401.10` and is never read. The payloads are cached
client-side and replayed on every `PLAYER_ENTERING_WORLD`, so one send per login
covers the session, and the name and description travel with the payload as
`GlobalStrings.dbc`'s `MINIMAP_TRACKING_SAWMILL` (`Sawmill`) and `_DESC`.

An earlier attempt did try to patch the client - the corrected
`GameObjectPOIs.lua` written into `patch-B.MPQ`, or shipped as an override
archive of its own - and `patch-B.MPQ` is ACL-protected against ordinary writes,
so neither took: no override archive is installed and the archive is unchanged.

Where the pins are sent from is the `SawmillPins` table and
`SAWMILL_PIN_CACHE_ID` in `src/woodworking.cpp`.

### What the gate does, measured

`apps/coa-gameplay-test/scenarios/woodworking-refine-sawmill.json` walks the
whole requirement in one run and passes on all seven assertions: the cast is
refused 411 yards from the nearest spot (cast error 102, no plank produced),
it completes at the Eastvale place with nothing placed there, and it completes
again at a `Portable Sawmill` that the shop item was used to place far from any
spot. The Refine spells are 1.5 second casts (cast time index 16) and each
accepted one pays its plank, so the assertions also see the crafted item and not
only the cast error.

## The Lumber Axe

The Woodcutting tool is `Lumber Axe`, item 6954: the miscellaneous weapon
whose only purpose is the profession, the same shape as the Mining Pick (2901),
Blacksmith Hammer (5956) and Skinning Knife (7005) it stands beside, and the
only item in the world whose description is "For cutting down trees\!".

Taking either wood profession hands one over, and the script grants it when the
character does not already own one, so a first lesson carries the tool and a
later rank does not hand out a second. Two events are watched for, because which
one happens is decided by the row the book sells: `Trainer::TeachSpell` casts a
trainer spell that carries a learn spell and learns one that does not, and the
Apprentice rows carry one. So the axe arrives on the **skill step** the same cast
grants (`Spell::EffectLearnSkill` goes through `SetSkill`), and the career's own
entry spell is watched as well - `13977859` "Woodcutting" and `1005008`
"Apprentice Woodworking", plus the two rows themselves - so a client that ships
the pair the other way round still hands the tool over. Watching only for
`13977880`/`1005014` being *learned* was the first attempt and it never fired,
because no character ever learns those rows: they are cast.

The same axe stands on both Book of Artisans shelves, where Edna Mullby's rows
already put the other three tools. Those rows travel as their own update
(`rev_20260928_85_lumber_axe_shelf.sql`) rather than in the module's own file,
because those shelves are rebuilt from her counter every time that file runs -
a row written there is deleted by the next re-apply. An update's filename sorts
after `book_of_artisans.sql`, and it deletes the two rows before inserting them,
so a re-apply replaces them instead of colliding with the shelf's primary key.

## Files

The four world updates sit in `data/sql/updates/pending_db_world/`, where the
repository keeps new SQL; they apply at boot like every other update.

* `rev_20260928_80_woodcutting_tree_templates.sql` - the 32 recovered tree templates.
* `rev_20260928_81_woodcutting_loot_tables.sql` - one loot table per tree.
* `rev_20260928_82_woodcutting_spawns.sql` - 1305 spawns, guids 8000000+.
* `rev_20260928_83_woodworking_sawmill_gate.sql` - retires the five rows an earlier version
  of this gate bound to a spell script; the hook needs no binding.
* `src/woodworking.cpp` - the Lumber Axe grant, where a sawmill is, and the
  recipe ladder that answers skills 732 and 757.

The portable sawmill itself - the two gameobjects the shop item and the Tinker
place - lives in `modules/mod-portable-sawmill`.

`Felwood Tree` (244633) is the one whose zone held no sampled herb or ore row,
so it anchors on that zone's other gameobjects. The three `Scadeald Tree`
templates (244640-244642) sit on a map we could not identify and are
deliberately left unspawned.
