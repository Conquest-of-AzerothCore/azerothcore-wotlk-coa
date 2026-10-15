# Restoring an Ascension NPC's original appearance

CoA's custom NPCs keep their look **on the server**: the unit is spawned on an ordinary model and
its real appearance is handed to the client per unit, on request, as a 68-byte paper-doll —
character model, eight customization bytes and eleven equipment display ids. The client asks, the
server answers. This is the stock 3.3.5 "mirror image" exchange, reused by CoA as its general NPC
appearance channel.

This document is the restoration procedure for **any** Ascension NPC. Wherever we hold the data,
the outcome below is the finished state — it is exactly what the Destiny Weavers run today, and
what every further NPC should end up as. Capture first; every other source only confirms.

## How the look travels

1. `creature_template_model` decides what the unit is created as. The client builds that model
   *before* any appearance arrives, so it must be an id the client can resolve.
2. `UNIT_FLAG2_MIRROR_IMAGE = 0x00000010` (`UnitDefines.h`) marks the unit as one whose look comes
   over the wire; the client only asks for units that carry it, and the CoA server component sets it
   on every creature that has a preset (`AscensionCompat.cpp:6752`, re-asserted on update).
3. The client sends `CMSG_GET_MIRRORIMAGE_DATA` (`0x0401`, 8 bytes: the target GUID, no mask, no
   entry, no trailing payload) on its own whenever such a unit streams into view — a plain capture
   of the connection is enough, no client tooling needed.
4. The server answers `SMSG_MIRRORIMAGE_DATA` (`0x0402`, 68 bytes) out of `creature_display_preset`.

The reply, in order: same GUID, `u32` display id, `u8` race, gender, class, skin, face, hair style,
hair colour, facial hair, `u32` guild id, then eleven `u32` equipment display ids —
head, shoulders, shirt, chest, waist, legs, feet, wrists, hands, back, tabard. These are
`ItemDisplayInfo` ids; 0 means the slot is empty. Nothing else is in the packet: no position, no
scale, no level, no faction, no name.

## Evidence, in order of authority

| source | gives | never gives |
|---|---|---|
| **packet capture** (`0x0401`/`0x0402`) | the look, field for field — the only source that does | position, scale, level, faction, name |
| **archive** `npc` kind | entry, name, `subname`, icon, `type_flags`, `modelid1…4` per mode | the look — ids only |
| **archive** `world-creature` kind | spawn position, zone, coordinates | appearance |
| **archive** `dbc-record`, `client-asset` | which ids a submitted client carries | CoA's custom block (no `CreatureDisplayInfoExtra` rows at all) |
| **client / datamine DBCs** | whether an id resolves: `ItemDisplayInfo`, `CreatureDisplayInfo`, `CreatureDisplayInfoExtra`, models | the outfit — the shipped client has no row for any Weaver display |
| **world DB** | templates, models, spawns, gossip, vendors | preset data — `creature_display_preset` is ours, not CoA's |

A capture beats everything. Sources that only name ids can confirm an id; none of them can invent a
look, and a look assembled from them is a stand-in by definition.

## The procedure

**1. Get the reply.** Decode it straight out of the capture corpus, or with the working-tree
helper `.scratch/destiny/mirror_decode.py`, which is round-trip verified against the live table.
Mind third-party opcode listings: the archive's own JSON is off by one on this pair and calls
`0x0400` the request — the framed bytes and `Opcodes.h` agree on **`0x0401` request / `0x0402`
reply**.

**2. Find the entry.** Archive `npc` records give the entry, its `subname` and the `modelid1` the
realm spawned it with; the client's creature cache
(`coa-datamine-master/raw/cache/…/creaturecache`) carries the same row and confirms it. Several
entries can share one look — the sixteen Weavers map onto eight display ids in pairs — and a pair
is always corrected together.

**3. Write the preset.** One row per `(entry, display_id)` in `creature_display_preset`, holding
exactly the reply's fields in the reply's order:

```
entry, display_id, race, gender, class, skin, face, hair, haircolor, facialhair, guild_id,
item_head, item_shoulders, item_body(shirt), item_chest, item_waist, item_legs, item_feet,
item_wrists, item_hands, item_back(cape), item_tabard
```

`AscensionCreaturePresetMgr::LoadFromDB` (`AscensionCreaturePreset.cpp`) keys on
`(entry, display_id)` and, when the unit's current display has no row, falls back to the entry's
first display id — so a second row on a different `display_id` is an *alternative* look, not a
second unit.

**4. Give the unit a base model the client can build.** Use the plain character display for the
NPC's race and gender: the `CreatureDisplayInfo` row whose model path is
`Character\<Race>\<Gender>\<Race><Gender>.mdx` and whose `ExtendedDisplayInfoID` is 0. The
Weavers' eight: 49 human M, 51 orc M, 53 dwarf M, 56 night elf F, 57 undead M, 1478 troll M,
15475 blood elf F, 16125 draenei M. Put it in `creature_template_model`, and give any display id
the core insists on a `creature_model_info` row. An id no client ships is a nameplate with nothing
under it — a checkerboard cube in the best case.

**5. Keep the flag.** `type_flags = 134217728` on the template; the module adds
`UNIT_FLAG2_MIRROR_IMAGE` itself for anything with a preset. Placement, gossip, faction and level
are separate content and are never part of this exchange — an NPC can have a perfect preset row
and still be standing in the wrong city.

**6. Verify before believing it.** Every nonzero item id must exist in the client's
`ItemDisplayInfo.dbc`, the display id must resolve, and the models behind them must ship. Then
reload without a restart and read the log:

```
localreloadpresets   # worldserver console -> "Loaded N creature display presets into cache across M unique creature entries"
```

That line is the real confirmation even though the command's own reply prints a literal `%u`
instead of the count (`AscensionCompat.cpp:5379`, cosmetic bug in the module).

**7. If the capture is missing, say so in the code.** The honest options are to borrow a sibling
NPC's captured look on the same body, or to leave the stand-in — and label it as a stand-in in the
SQL comment. Never present a clone as the original.

## The two rules that decide whether it renders

**The item block's field order.** A row copied out of `CreatureDisplayInfoExtra` starts at **field
8**, not 9, and its last two fields run **tabard then cape** while the wire carries **back then
tabard**. Read one field late, or copy those last two in table order, and every slot shifts: the
head slot then holds a shoulder model, and because the client resolves head models per race
(`helm_mail_pvphorde_c_01_trm.m2`) while a shoulder model has no such variant, the load fails and
you get the cube.

| extra field | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| item | head | shoulders | shirt | chest | waist | legs | feet | wrists | hands | tabard | cape |
| wire slot | head | shoulders | shirt | chest | waist | legs | feet | wrists | hands | back | tabard |

Confirmed twice: against this realm's own `COA/Data/dbc/CreatureDisplayInfoExtra.dbc` (field 8 holds
`Helm_*` models, 9 `LShoulder_*`, 13 a pant, 14 a boot, 15 a bracer, 16 a glove, 17 a tabard, 18 a
cape) and against 1,163 captured replies, where every nonzero value's own `ItemDisplayInfo` strings
match the slot it sits in with no contradiction.

**Item display ids are not race-bound.** They name a model plus its geoset textures, and the same
row dresses any body. In the capture corpus 130 of 588 ids are worn by more than one race/gender
and 25 by more than one race (12955 on a human *and* a blood elf, 11183 on a human *and* a dwarf,
136769 on five races). So a look captured on one body transfers to its sibling on another race by
keeping the item ids and changing only `race`, `gender` and the customization bytes.

## What no source can give you

* **Positions.** The reply has none; `frame` and stream `offset` in a corpus are capture-file
  positions, not coordinates. Placement comes from an addon sighting (archive `world-creature`) or
  from the spot the previous NPC held.
* **Customization for a body we never captured.** Only the race, gender and item ids transfer; the
  skin, face, hair, hair colour and facial hair of an uncaptured sibling are unknown, so carry them
  over from the stand-in and say so.
* **Which slots the real NPC had.** A capture shows what was on the NPC at that moment — nothing
  about slots left empty.

## Definition of done

* `creature_display_preset` matches the capture field for field, or carries a sibling's captured
  look with the carried-over fields named in the comment.
* The base display in `creature_template_model` is the stock character display for the race and
  gender, and resolves in a stock client.
* Every nonzero item id exists in the client's `ItemDisplayInfo.dbc`.
* The preset loaded in the log, and the NPC is visible, dressed and cube-free in game.

## Reference implementation — the sixteen Destiny Weavers, 2026-09-20

The capture holds **one** Weaver: 449347 Galric Olim, human male, template display 449299, three
byte-identical replies — `display 49, race 1, gender 0, class 1, skin 4, face 2, hair 6,
haircolour 8, facial hair 4, guild 0`, items `shirt 126792, chest 66195, legs 66200, feet 142624,
wrists 142619`. Those five are a plain civilian outfit: Hallowed Undershirt of Lunar Communion,
Weary Worker's Tunic, Weary Worker's Pants, Scribe's Opulent Waders, Scribe's Opulent Wristwraps.
The archive's `npc` cache supplies the other fifteen entries, all `subname = "Destiny Weaver"`,
`type_flags = 134217728`, sixteen entries over eight display ids in pairs.

Working state, applied and verified in game:

| entry | name | display | race/gender | class | skin/face/hair/colour/facial | shirt | chest | legs | feet | wrists |
|---|---|---|---|---|---|---|---|---|---|---|
| 449347 | Galric Olim | 49 | 1 / 0 | 1 | 4 / 2 / 6 / 8 / 4 | 126792 | 66195 | 66200 | 142624 | 142619 |
| 449357 | Galrin Olemar | 49 | 1 / 0 | 1 | 4 / 2 / 6 / 8 / 4 | 126792 | 66195 | 66200 | 142624 | 142619 |
| 449340 | Tav'vin | 1478 | 8 / 0 | 0 | 3 / 2 / 7 / 1 / 4 | 126792 | 66195 | 66200 | 142624 | 142619 |
| 449350 | Tav'ral | 1478 | 8 / 0 | 0 | 3 / 2 / 7 / 1 / 4 | 126792 | 66195 | 66200 | 142624 | 142619 |

Both Human rows are the capture verbatim. The two Horde rows wear the same captured clothing on a
troll — the outfit is cloth and shirt, so the same ids dress the body — while `class` and the five
customization bytes are carried over from the stand-in, because no Horde capture exists to give
them. Spawns: 9000011 Tav'vin
Durotar (1, −635.231, −4230.280, 38.135), 9000020 Galrin Olemar Stormwind (0, −8818.580, 671.774,
95.425) — the two positions any source actually records — and 9000012 Tav'ral Orgrimmar (1, 1630.5,
−4433.0, 15.76), on the spot the wrong NPC used to hold, since no capture gives his coordinates.

Revisions: `rev_20260920_00` / `_02` the captured Human look and its pair, `rev_20260920_01` every
Weaver onto its race's stock character display, `rev_20260920_03` the placements, `rev_20260920_04`
the cloned rows' slot order, `rev_20260920_05` the captured outfit for the Horde pair.

## Traps

* A dressed NPC's `CreatureDisplayInfoExtra` row is a **stand-in**, not evidence — that is where
  the Horde Weaver's mail PvP set and Darkspear tabard came from (extra 19788).
* The DBC rows for CoA's custom block are ours, cloned, and the shipped client has none of them; do
  not cite `COA/Data/dbc` as proof of what CoA authored.
* Appearance and placement are independent: a correct preset on an unbuildable display is still an
  invisible NPC.
* the CoA server component answers `0x0401` itself and returns `false`, so the core's clone-caster
  handling of the same opcode never runs for preset units.
* **A corrected `npc_text` row may not appear on a client that has already read it.** The client
  caches gossip text in `Cache/WDB/<locale>/<realm>/npccache.wdb` and answers a text query from that
  cache before asking the server, so an edited greeting keeps rendering the old text until the file
  (or the WDB folder) is deleted. The recovered string is worth reading before it is rewritten, too:
  that cache stores line breaks as runs of four spaces and keeps literal `**`, so text copied out of
  it has to have its breaks written back as `$B` and its markdown dropped before it goes into the
  database.
* Both genders of an `npc_text` row are sent and the client picks by the character's gender
  (`text0_*` / `text1_*` in `QueryHandler::HandleNpcTextQueryOpcode`). A row filled only on `text0_*`
  shows a female character an empty window.
