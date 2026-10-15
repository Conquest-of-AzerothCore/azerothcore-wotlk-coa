-- Ragnaros's own random-item pool (coa_mc_item_pool, CreatureEntry 11502, §7.3) is missing Band
-- of Sulfuras (19138), present on the Classic Ragnaros loot table (wowhead.com/classic/guide/
-- ragnaros-molten-core-strategy-wow-classic, Wayback 20250918015449) and already carrying clean
-- tier clones in this export's own item_template (219138 "@Ascended Molten Core@", 319138
-- "@Heroic Molten Core@", 1319138 "@Mythic Molten Core@" - the same 3-/13-/2- id-prefix
-- convention every other item in this pool already uses). Added at the pool's existing uniform
-- weight (1), one row per difficulty.
DELETE FROM `coa_mc_item_pool` WHERE `CreatureEntry` = 11502 AND
    (`RaidDifficulty`, `ItemEntry`) IN ((0, 19138), (1, 319138), (2, 1319138), (3, 219138));
INSERT INTO `coa_mc_item_pool` (`RaidDifficulty`, `CreatureEntry`, `ItemEntry`, `Weight`) VALUES
(0, 11502, 19138, 1),
(1, 11502, 319138, 1),
(2, 11502, 1319138, 1),
(3, 11502, 219138, 1);
