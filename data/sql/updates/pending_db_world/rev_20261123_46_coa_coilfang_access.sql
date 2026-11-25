-- Exact Mythic access rows enforce level 60 for direct entry and Dungeon Finder.
DELETE FROM `dungeon_access_template` WHERE `map_id` IN (545, 546, 547) AND `difficulty` = 2;
INSERT INTO `dungeon_access_template` (`id`, `map_id`, `difficulty`, `min_level`, `max_level`, `min_avg_item_level`, `comment`)
VALUES
(240, 545, 2, 60, 0, 0, 'The Steamvault (Mythic)'),
(241, 546, 2, 60, 0, 0, 'The Underbog (Mythic)'),
(242, 547, 2, 60, 0, 0, 'The Slave Pens (Mythic)');

UPDATE `dungeon_access_template`
SET `min_level` = 60
WHERE `map_id` IN (545, 546, 547) AND `difficulty` IN (0, 1, 2) AND `min_level` > 60;

DELETE FROM `lfgdungeons_dbc` WHERE `ID` IN (140, 146, 147, 184, 185, 186, 265, 266, 267);
INSERT INTO `lfgdungeons_dbc` (`ID`, `Name_Lang_enUS`, `Name_Lang_enGB`, `Name_Lang_koKR`, `Name_Lang_frFR`, `Name_Lang_deDE`, `Name_Lang_enCN`, `Name_Lang_zhCN`, `Name_Lang_enTW`, `Name_Lang_zhTW`, `Name_Lang_esES`, `Name_Lang_esMX`, `Name_Lang_ruRU`, `Name_Lang_ptPT`, `Name_Lang_ptBR`, `Name_Lang_itIT`, `Name_Lang_Unk`, `Name_Lang_Mask`, `MinLevel`, `MaxLevel`, `Target_Level`, `Target_Level_Min`, `Target_Level_Max`, `MapID`, `Difficulty`, `Flags`, `TypeID`, `Faction`, `TextureFilename`, `ExpansionLevel`, `Order_Index`, `Group_Id`, `Description_Lang_enUS`, `Description_Lang_enGB`, `Description_Lang_koKR`, `Description_Lang_frFR`, `Description_Lang_deDE`, `Description_Lang_enCN`, `Description_Lang_zhCN`, `Description_Lang_enTW`, `Description_Lang_zhTW`, `Description_Lang_esES`, `Description_Lang_esMX`, `Description_Lang_ruRU`, `Description_Lang_ptPT`, `Description_Lang_ptBR`, `Description_Lang_itIT`, `Description_Lang_Unk`, `Description_Lang_Mask`)
VALUES
(140, 'Slave Pens', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 16712190, 58, 70, 60, 60, 60, 547, 0, 3, 1, -1, 'COILFANG', 1, 0, 2, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 16712188),
(146, 'Underbog', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 16712190, 58, 70, 60, 60, 60, 546, 0, 3, 1, -1, 'COILFANG', 1, 0, 2, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 16712188),
(147, 'The Steamvault', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 16712190, 58, 70, 60, 60, 60, 545, 0, 3, 1, -1, 'COILFANG', 1, 0, 2, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 16712188),
(184, 'Slave Pens', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 16712190, 60, 70, 60, 60, 60, 547, 1, 3, 1, -1, 'COILFANG', 1, 0, 3, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 16712188),
(185, 'The Steamvault', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 16712190, 60, 70, 60, 60, 60, 545, 1, 3, 1, -1, 'COILFANG', 1, 0, 3, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 16712188),
(186, 'Underbog', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 16712190, 60, 70, 60, 60, 60, 546, 1, 3, 1, -1, 'COILFANG', 1, 0, 3, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 16712188),
(265, 'Slave Pens', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 16712190, 60, 70, 60, 60, 60, 547, 2, 3, 1, -1, 'COILFANG', 1, 0, 10, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 16712188),
(266, 'The Steamvault', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 16712190, 60, 70, 60, 60, 60, 545, 2, 3, 1, -1, 'COILFANG', 1, 0, 10, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 16712188),
(267, 'Underbog', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 16712190, 60, 70, 60, 60, 60, 546, 2, 3, 1, -1, 'COILFANG', 1, 0, 10, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 16712188);
