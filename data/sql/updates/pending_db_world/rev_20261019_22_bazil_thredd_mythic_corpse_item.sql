-- Bazil Thredd (Mythic): the corpse rolls one Mythic dungeon item (db.exil.es archive, dump of 2026-10-04: 883 items at 0.113 %)
DELETE FROM `creature_loot_template` WHERE `Entry` = 201716 AND `Item` = 1027965;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(201716, 1027965, 1027965, 100, 0, 1, 0, 1, 1, 'Bazil Thredd (Mythic) - (ReferenceTable) Mythic dungeon item');
