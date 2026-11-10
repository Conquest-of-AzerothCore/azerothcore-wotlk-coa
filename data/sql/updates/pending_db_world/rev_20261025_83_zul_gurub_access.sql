-- Zul'Gurub access on CoA: level 60 on Normal, Heroic, Mythic and Ascended (MapDifficulty 67-70).
-- rev_20260930_99_ASC_northshire_revamp.sql flattens every map-309 spawnMask to 1, which leaves the
-- three new difficulties empty, so all spawns go back on the four difficulty bits.
UPDATE `dungeon_access_template` SET `min_level` = 60, `comment` = 'Zul\'Gurub (Normal)' WHERE `id` = 20;
DELETE FROM `dungeon_access_template` WHERE `map_id` = 309 AND `difficulty` IN (1, 2, 3);
INSERT INTO `dungeon_access_template` (`map_id`, `difficulty`, `min_level`, `max_level`, `min_avg_item_level`, `comment`) VALUES
(309, 1, 60, 0, 0, 'Zul\'Gurub (Heroic)'),
(309, 2, 60, 0, 0, 'Zul\'Gurub (Mythic)'),
(309, 3, 60, 0, 0, 'Zul\'Gurub (Ascended)');

UPDATE `creature` SET `spawnMask` = 15 WHERE `map` = 309;
UPDATE `gameobject` SET `spawnMask` = 15 WHERE `map` = 309;
