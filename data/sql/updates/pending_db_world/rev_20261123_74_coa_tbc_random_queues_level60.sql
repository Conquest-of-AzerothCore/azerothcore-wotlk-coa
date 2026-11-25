-- Expose the existing TBC random Heroic and Mythic groups at the CoA level cap.
-- Keep the DBC queue IDs and group mappings so specific-dungeon access rules still apply.
DELETE FROM `lfgdungeons_dbc` WHERE `ID` IN (418, 419);
INSERT INTO `lfgdungeons_dbc`
    (`ID`, `Name_Lang_enUS`, `Name_Lang_enGB`, `Name_Lang_koKR`, `Name_Lang_frFR`, `Name_Lang_deDE`,
    `Name_Lang_enCN`, `Name_Lang_zhCN`, `Name_Lang_enTW`, `Name_Lang_zhTW`, `Name_Lang_esES`, `Name_Lang_esMX`,
    `Name_Lang_ruRU`, `Name_Lang_ptPT`, `Name_Lang_ptBR`, `Name_Lang_itIT`, `Name_Lang_Unk`, `Name_Lang_Mask`,
    `MinLevel`, `MaxLevel`, `Target_Level`, `Target_Level_Min`, `Target_Level_Max`, `MapID`, `Difficulty`, `Flags`,
    `TypeID`, `Faction`, `TextureFilename`, `ExpansionLevel`, `Order_Index`, `Group_Id`, `Description_Lang_enUS`,
    `Description_Lang_enGB`, `Description_Lang_koKR`, `Description_Lang_frFR`, `Description_Lang_deDE`,
    `Description_Lang_enCN`, `Description_Lang_zhCN`, `Description_Lang_enTW`, `Description_Lang_zhTW`,
    `Description_Lang_esES`, `Description_Lang_esMX`, `Description_Lang_ruRU`, `Description_Lang_ptPT`,
    `Description_Lang_ptBR`, `Description_Lang_itIT`, `Description_Lang_Unk`, `Description_Lang_Mask`)
VALUES
  (418, 'Random Burning Crusade Heroic', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 16712190, 60, 70, 60, 60, 60, 0, 0, 3, 6, -1, '', 1, 0, 3, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 16712188),
  (419, 'Random Burning Crusade Mythic', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 16712190, 60, 70, 60, 60, 60, 0, 0, 3, 6, -1, '', 1, 0, 10, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 16712188);
