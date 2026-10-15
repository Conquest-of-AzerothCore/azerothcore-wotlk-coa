# mod-battlehorn

Restores the **Battle Horn** (898070): the vanity collectible the live realm sells from Tiraxis's
rotation, and the one item of that family a realm built from this repository could not create at
all. `Item::CreateItem()` returned null for 898070, so the pool row that already stood in
mod-ethereal-bazaar's generated table was a rotation slot that always came up empty.

## The item

| | |
|---|---|
| entry | **898070 Battle Horn** |
| template | class 0 (consumable), quality 6, display 26987, `bonding` 3 (binds when used), `maxcount` 0, price 0 |
| on use | spell **55884** ("Learning"), the core's ordinary learn-item path, with `spellcharges_1` -1 |
| taught | spell **898070 Battle Horn**, in the learn slot (`spelltrigger_2` 6), `spellcooldown_2` 120000 |
| description | *Blast a blaring horn, attracting enemies within 30 yards.* |

Spell 898070 is the client's own, so nothing about it is invented here. Spell.dbc defines it as
`SPELL_EFFECT_THREAT` against every enemy within 30 yd of the caster - `TARGET_SRC_CASTER` (22) plus
`TARGET_UNIT_SRC_AREA_ENEMY` (15), radius index 10, which SpellRadius.dbc puts at 30.0 yd - and a
`SPELL_EFFECT_DUMMY` beside it, on a 45 second spell cooldown. Both effects are effects the core
already implements, so this module is data only; a spell script would only be needed if the horn
turns out to need something the two effects do not already do.

The same shape is common enough to be safe: 93 spells in the client's own Spell.dbc use exactly this
`effect 63` + `TARGET_SRC_CASTER` + `TARGET_UNIT_SRC_AREA_ENEMY` combination.

The `-1` in the on-use slot is the core's "single use" charge convention: `Spell::TakeCastItem`
counts a negative charge up to zero and then destroys the item, so using the horn spends the horn
and leaves the ability behind.

## Acquisition

`(898070, 3015, 350, 0)` - 350 Bazaar Tokens, ItemExtendedCost 3015 - is already in
mod-ethereal-bazaar's `data/sql/db-world/base/03_ethereal_bazaar_pool.sql`, taken from the live
vendor's own rotation. That file is generated and this module does not touch it; what the horn
needed was the row the pool points at.

## What is in here

`data/sql/updates/pending_db_world/rev_20260926_80_battle_horn_item.sql` - one
`REPLACE INTO item_template`, field for field the row a repack database carries for the item, all
138 columns, so the repack and the repository stop disagreeing. `REPLACE` writes the row with this
exact entry and touches no other item, which keeps the file idempotent without deleting from
`item_template`. New SQL belongs in the repository's pending update directory, which is where every
other module's data sits too (the Stones of Retreat's destinations, the warchest); this module owns
the item's documentation and the place its script would live.

Checked before this file was written: the statement passes `apps/codestyle/codestyle-sql.py
--files <path>` together with its structural check (138 columns against 138 values), the file has
been applied twice against a live world database, and the row read back afterwards is identical to
the one the repack shipped.

## What the in-game pass checks

Use the horn next to an enemy: the threat effect has to land on everything within 30 yards, and the
ability has to stay in the spellbook after the horn is spent. The threat comes from the area target,
so what to watch is whether mobs that were not yet in combat actually come for the player - if they
do not, that is not a data problem, and the fix belongs in this module as a spell script.
