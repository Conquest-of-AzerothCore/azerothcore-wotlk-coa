-- Obsidian Sentinel (Heroic 107023, Mythic 207023) used the Normal loot list 7023. On Ascension each Heroic and
-- Mythic kill left one random Heroic or Mythic dungeon item (db.exil.es archive, dump of 2026-10-04: 893 Heroic
-- items and 887 Mythic items at about 0.11 % each). Both now roll the dungeon item pools Bazil Thredd uses and keep
-- the quest drop Obsidian Power Source.
UPDATE `creature_template` SET `lootid` = 107023 WHERE `entry` = 107023;
UPDATE `creature_template` SET `lootid` = 207023 WHERE `entry` = 207023;
DELETE FROM `creature_loot_template` WHERE `Entry` IN (107023, 207023);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(107023, 8053, 0, 100, 1, 1, 0, 1, 1, 'Obsidian Sentinel (Heroic) - Obsidian Power Source'),
(107023, 1202039, 1202039, 100, 0, 1, 0, 1, 1, 'Obsidian Sentinel (Heroic) - (ReferenceTable) Heroic dungeon item'),
(207023, 8053, 0, 100, 1, 1, 0, 1, 1, 'Obsidian Sentinel (Mythic) - Obsidian Power Source'),
(207023, 1027965, 1027965, 100, 0, 1, 0, 1, 1, 'Obsidian Sentinel (Mythic) - (ReferenceTable) Mythic dungeon item');
