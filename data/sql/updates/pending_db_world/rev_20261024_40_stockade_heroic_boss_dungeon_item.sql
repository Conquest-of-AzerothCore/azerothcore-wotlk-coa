-- Hamhock, Targorr the Dread and Bazil Thredd (Heroic): each corpse rolls one Heroic dungeon item, like Dextren
-- Ward (rev_20261022_80; db.exil.es archive, dump of 2026-10-04: every Stockade Heroic boss drops about 889-1013
-- Heroic items at about 0.11 % each).
DELETE FROM `creature_loot_template` WHERE `Entry` IN (101717, 101696, 101716) AND `Item` = 1202039;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(101717, 1202039, 1202039, 100, 0, 1, 0, 1, 1, 'Hamhock (Heroic) - (ReferenceTable) Heroic dungeon item'),
(101696, 1202039, 1202039, 100, 0, 1, 0, 1, 1, 'Targorr the Dread (Heroic) - (ReferenceTable) Heroic dungeon item'),
(101716, 1202039, 1202039, 100, 0, 1, 0, 1, 1, 'Bazil Thredd (Heroic) - (ReferenceTable) Heroic dungeon item');
