-- Malor the Zealous (Heroic/Mythic): own loot lists instead of the Normal one (db.exil.es archive, dump of 2026-10-04)
UPDATE `creature_template` SET `lootid` = `entry` WHERE `entry` IN (111032, 211032);
DELETE FROM `creature_loot_template` WHERE `Entry` IN (111032, 211032);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(111032, 59950, 0, 1, 0, 1, 0, 1, 1, 'Malor the Zealous (Heroic) - Sigil of Malor the Zealous'),
(111032, 97730, 0, 6, 0, 1, 0, 1, 1, 'Malor the Zealous (Heroic) - Worldforged Key Fragment'),
(111032, 1202039, 1202039, 25, 0, 1, 0, 1, 1, 'Malor the Zealous (Heroic) - (ReferenceTable) Heroic dungeon item'),
(211032, 59950, 0, 1, 0, 1, 0, 1, 1, 'Malor the Zealous (Mythic) - Sigil of Malor the Zealous'),
(211032, 97730, 0, 6, 0, 1, 0, 1, 1, 'Malor the Zealous (Mythic) - Worldforged Key Fragment'),
(211032, 1027965, 1027965, 25, 0, 1, 0, 1, 1, 'Malor the Zealous (Mythic) - (ReferenceTable) Mythic dungeon item');
