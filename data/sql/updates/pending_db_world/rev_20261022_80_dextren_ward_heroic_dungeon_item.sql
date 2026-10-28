-- Dextren Ward (Heroic): the corpse rolls one Heroic dungeon item (db.exil.es archive, dump of 2026-10-04 and Exiles DB export of 2026-09-13: 889 items at 0.112 %)
DELETE FROM `creature_loot_template` WHERE `Entry` = 101663 AND `Item` = 1202039;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(101663, 1202039, 1202039, 100, 0, 1, 0, 1, 1, 'Dextren Ward (Heroic) - (ReferenceTable) Heroic dungeon item');
