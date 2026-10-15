-- Built from Ascension's combat logs and client data. Regenerate rather than edit by hand.
--
-- Molten Core in four difficulties. Stage one: populate all four instances.
-- Stats, loot and mechanics are deliberately left for later, so they can be
-- worked on without touching the positions again.
--
-- The mapping base + 100000 / 200000 / 300000 is attested twice over, in
-- Creature.dbc and in the live realm WDB captures. 30 of the 31 Molten Core
-- families carry all four entries. Flame of Ragnaros (13148) has no variants
-- and keeps its base template for every difficulty.
--
-- The client is ready for this and it was checked, not assumed:
--   MapDifficulty.dbc has four rows for map 409, difficulties 0 to 3, each
--   with MaxPlayers 25 - the same shape as Icecrown Citadel. Stock Molten Core
--   has one row.
--   GlobalStrings labels them Normal / Heroic / Mythic / Ascended
--   (10-25 Players). That range is the flex rule: a cap of 25 and no floor.
--   The core allows it: MAX_RAID_DIFFICULTY is 4.
--
-- Spawn positions are NOT duplicated. The core picks the template of the
-- current difficulty for a spawn that carries the base id, so setting the mask
-- of the existing 233 rows from 1 to 15 is enough. That covers Ragnaros and
-- Majordomo too, which the instance script still summons by base id.

-- All 233 Molten Core spawns are mode 0 only. 15 is every difficulty:
-- 1 | 2 | 4 | 8.
UPDATE `creature` SET `spawnMask` = 15 WHERE `map` = 409;
UPDATE `gameobject` SET `spawnMask` = 15 WHERE `map` = 409;
