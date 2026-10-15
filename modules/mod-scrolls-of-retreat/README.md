# mod-scrolls-of-retreat

Restores the scrolls of the Retreat and Defense family to a realm built from this repository: the
two items that had no `item_template` row anywhere, the four teleport destinations every one of
them casts into, and Tiraxis's two rotation rows.

| item | name | teleport | the item's cooldown |
|---|---|---|---|
| 101257 | Scroll of Defense: Ashenvale | 83126 | 24 hours (`spellcooldown_2`) |
| 101258 | Scroll of Defense: Hillsbrad Foothills | 83128 | 24 hours (`spellcooldown_2`) |
| 1175626 | Scroll of Retreat: Stormwind | 84289 | 12 hours (`spellcooldown_1`) |
| 1175627 | Scroll of Retreat: Orgrimmar | 84288 | 12 hours (`spellcooldown_1`) |

All four are the same item shape: class 15 (miscellaneous), quality 6, display 295, `Flags` 64
(`ITEM_FLAG_PLAYERCAST`, so the player casts the spell the item holds), `bonding` 1 (binds when
picked up), price 0.

## How a scroll works

Both spell slots matter, and the four scrolls do not use them the same way.

* **The two Scrolls of Retreat cast their teleport directly.** `spellid_1` is the teleport on
  `spelltrigger_1` 0 - use - with `spellcharges_1` 0, so the scroll is not consumed, and
  `spellcooldown_1` is the twelve hours the client shows against the item. The teleport itself
  carries the client's own fifteen minute cooldown (Spell.dbc `recoveryTime` 900000 for 84288 and
  84289), and the cooldown that binds the *item* is read from the item's own slot - the "cooldown
  information stored in item prototype" path in `Player::AddSpellAndCategoryCooldowns`.
* **The two Scrolls of Defense teach theirs.** `spellid_1` is 55884 ("Learning") on use with
  `spellcharges_1` -1, the core's single-use charge convention, so the scroll is spent; `spellid_2`
  is the teleport in the learn slot (`spelltrigger_2` 6), which is the ordinary learn-item path
  `Player::CastItemUseSpell` runs for every teaching item in this repository. `spellcooldown_2` is
  the twenty-four hours the client shows.

Either way the ability is the client's own spell: `SPELL_EFFECT_TELEPORT_UNITS` (5) aimed at
`TARGET_DEST_DB` (17) - a destination the server reads out of `spell_target_position` - plus a
follow-up the core already implements: spell 666657 for the two Scrolls of Defense (a delayed
Ascension trigger, effect 183), a kill credit for the two Scrolls of Retreat.

The live realm sells the two Scrolls of Defense from Tiraxis beside the Battle Horn, and hands the
two Scrolls of Retreat out with the welcome warchest. Nothing about the spells is invented here:
they are the client's, and the only thing missing was where they land.

## Destinations

The rows are the server's own `.tele` hub points, the same convention
`data/sql/updates/pending_db_world/rev_20260916_00_stone_of_retreat_destinations.sql` uses for the
Stones of Retreat, and the two capitals reuse the landings that file already audited - 777000 for
Orgrimmar, and 777003 for Stormwind, whose z it lifted onto the walkable floor.

| spell | destination | map | x, y, z | whence |
|---|---|---|---|---|
| 83126 | Ashenvale | 1 | 1928.3400, -2165.9500, 93.7896 | `.tele Ashenvale` |
| 83128 | Hillsbrad Foothills | 0 | -436.6570, -581.2540, 53.5944 | `.tele HillsbradFoothills` |
| 84288 | Orgrimmar | 1 | 1629.8500, -4373.6400, 31.5573 | Stone of Retreat: Orgrimmar (777000) |
| 84289 | Stormwind | 0 | -8833.3800, 628.6280, 94.8162 | Stone of Retreat: Stormwind (777003) |

## Acquisition

The two Scrolls of Defense take two rows in `ethereal_bazaar_pool` - `(101257, 3015, 350, 0)` and
`(101258, 3015, 350, 0)`, the same 350-token tier the Battle Horn is pooled at - so Tiraxis offers
them from his rotation the way the live realm does. The two Scrolls of Retreat are not sold at all:
they arrive with the welcome warchest, which is where the live realm hands them out.

## The faction gate

Each capital scroll belongs to the side that owns the capital: **1175626 Scroll of Retreat:
Stormwind is Alliance only**, and **1175627 Scroll of Retreat: Orgrimmar is Horde only**. A
character of the other faction gets one line, sent to the middle of the screen and to the chat log
at the same time:

```
The Scroll of Retreat: Stormwind can only be used by Alliance characters.
The Scroll of Retreat: Orgrimmar can only be used by Horde characters.
```

The sentence is the realm's notification yellow - drawn yellow by the client's own hand in the
notification, written on `|cffffff00` in the chat copy so the two read alike - and the faction is
painted in its colour: `|cff4c9aff` Alliance, `|cffff2020` Horde. The chat line carries the scroll as
the client's real item link, in the quality 6 colour `ffe6cc80`, so it can be clicked like any other
item reference; the notification opcode cannot draw link markup and names the scroll plainly.

Nothing is consumed and no cooldown is started: the core asks `ScriptMgr::OnItemUse` before the cast
of a used item, and an answered request means the cast never happens - a refused scroll is left
exactly as it was - while the item the client grayed out for that request is released with the
native `Player::SendEquipError(EQUIP_ERR_NONE, ...)` the repack's own item scripts send for the same
reason. That acknowledgement goes out for every attempt, but the two lines are held to one
announcement per three seconds per character - the interval mod-teleport-actionbar keeps its stone
refusal to - so a request the client repeats cannot stack the same sentence on the screen.

Spells 84288 and 84289 are used by these two items and by nothing else in the world database, so the
entry is the exact reach of the rule and no other item or spell of the realm is touched by it.

It is an `AllItemScript` (`src/scrolls_of_retreat.cpp`, registered by the loader) and not an
`ItemScript`, on purpose. An `ItemScript` is reached through `item_template.ScriptName`, and these
two rows belong to the core's warchest file: a `ScriptName` put on them here would be wiped the next
time that file's `REPLACE` is re-applied, and the gate would go quiet without a word. Keying the gate
on the entry in code cannot be emptied out by a data change anywhere. Spells 84288 and 84289 are
carried by these two items and by nothing else in the world database, so the two entries are the
script's whole reach.

## What is in here

`data/sql/updates/pending_db_world/rev_20260926_81_retreat_and_defense_scrolls.sql`, in the
repository's pending update directory, where the realm's other module data lives as well (the Stones
of Retreat's destinations, the warchest):

* the four `spell_target_position` rows, each a `REPLACE` on `(ID, EffectIndex)`;
* the two Scrolls of Defense item rows, field for field what a repack database carries, written as
  `REPLACE INTO item_template` so the file is idempotent without deleting from `item_template`;
* the two pool rows, `REPLACE`d on `item`.

`src/scrolls_of_retreat.cpp` and `src/scrolls_of_retreat_loader.cpp`: the faction gate above, and
the loader line that registers it.

## What is deliberately not in here

* **The two Scrolls of Retreat items (1175626, 1175627).** Their item rows ship in
  `data/sql/updates/pending_db_world/rev_20260924_10_coa_warchest_item_templates.sql`, with the rest
  of the welcome warchest's grant list. Two files writing the same row would be two places to keep
  in step.
* **The Stones of Retreat's central hub-side table.** Those stones already have one -
  mod-teleport-actionbar's generated `src/StoneFactionData.h`, keyed by the stone teleport spells
  (777xxx, 769xx, 10218x), with `TeleportActionBar.EnforceFaction` refusing a foreign stone at cast
  time with its hub-and-side line. The two scrolls' spells are not in that table and the sentence
  they are refused with is their own, so their gate stays here - and, being keyed on the two items,
  it does not depend on that generated table staying as it is.
* **The Stones of Retreat themselves.** Those are the 167-item family
  `rev_20260916_00_stone_of_retreat_destinations.sql` and mod-ethereal-bazaar already own; the
  scrolls only share their hub convention.
* **The plain scroll model or icon.** Display 295 is the client's `INV_Scroll_03`, which every
  scroll in the family draws; nothing about it is per-item data.

Checked before this file was written: the statements pass `apps/codestyle/codestyle-sql.py --files
<path>` and the structural check (8 x 4, 138 x 2 and 4 x 2 columns against values), the file has
been applied twice against a live world database, and all three kinds of row read back as intended.

## What the in-game pass checks

* each scroll lands where the table above says, and no scroll drops the player through the ground
  on arrival;
* the two Scrolls of Retreat are reusable, the two Scrolls of Defense are spent on use and leave
  the ability in the spellbook;
* **the cooldown of a taught teleport.** A learned spell's cooldown is the spell's own, and
  Spell.dbc gives 83126 and 83128 none; no `spell_dbc` row overrides them on this realm either. The
  item's twenty-four hours are what the client prints against the scroll, so if the two Scrolls of
  Defense turn out to teleport freely after one purchase, the cooldown has to be enforced server
  side - and that is work for this module, not for the database.
* **the faction gate.** Use the Stormwind scroll on a Horde character and the Orgrimmar scroll on
  an Alliance one: the line has to appear in both places at once, the scroll has to stay in the bag
  with no cooldown on it, and its own faction has to be able to use it as before. The cooldowns the
  client prints against the two Scrolls of Retreat are the item rows' twelve hours
  (`spellcooldown_1` 43200000) - the fifteen minutes in Spell.dbc belong to the spells and never
  reach the item, because `Player::AddSpellAndCategoryCooldowns` reads an item-triggered spell's
  cooldown out of the item prototype first.
