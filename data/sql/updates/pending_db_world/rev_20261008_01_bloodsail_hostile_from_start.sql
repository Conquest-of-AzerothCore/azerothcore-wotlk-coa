-- Bloodsail Buccaneers (87) starts Hated and at war, but its reputation stays hidden until the first Bloodsail kill.
-- Until then the client answers "Invalid target" on the Wild Shore pirates; once the kill makes the reputation
-- visible they become attackable. The row is the client's Faction.dbc record with ReputationFlags_1 2 -> 3
-- (visible and at war), so every character starts with the state a first kill gives.
DELETE FROM `faction_dbc` WHERE `ID` = 87;
INSERT INTO `faction_dbc`
(`ID`, `ReputationIndex`, `ReputationRaceMask_1`, `ReputationRaceMask_2`, `ReputationRaceMask_3`,
`ReputationRaceMask_4`, `ReputationClassMask_1`, `ReputationClassMask_2`, `ReputationClassMask_3`,
`ReputationClassMask_4`, `ReputationBase_1`, `ReputationBase_2`, `ReputationBase_3`, `ReputationBase_4`,
`ReputationFlags_1`, `ReputationFlags_2`, `ReputationFlags_3`, `ReputationFlags_4`, `ParentFactionID`,
`ParentFactionMod_1`, `ParentFactionMod_2`, `ParentFactionCap_1`, `ParentFactionCap_2`,
`Name_Lang_enUS`, `Name_Lang_enGB`, `Name_Lang_koKR`, `Name_Lang_frFR`, `Name_Lang_deDE`, `Name_Lang_enCN`,
`Name_Lang_zhCN`, `Name_Lang_enTW`, `Name_Lang_zhTW`, `Name_Lang_esES`, `Name_Lang_esMX`, `Name_Lang_ruRU`,
`Name_Lang_ptPT`, `Name_Lang_ptBR`, `Name_Lang_itIT`, `Name_Lang_Unk`, `Name_Lang_Mask`,
`Description_Lang_enUS`, `Description_Lang_enGB`, `Description_Lang_koKR`, `Description_Lang_frFR`,
`Description_Lang_deDE`, `Description_Lang_enCN`, `Description_Lang_zhCN`, `Description_Lang_enTW`,
`Description_Lang_zhTW`, `Description_Lang_esES`, `Description_Lang_esMX`, `Description_Lang_ruRU`,
`Description_Lang_ptPT`, `Description_Lang_ptBR`, `Description_Lang_itIT`, `Description_Lang_Unk`,
`Description_Lang_Mask`) VALUES
(87, 0, 1791, 0, 0, 0, 0, 0, 0, 0, -6500, 0, 0, 0, 3, 0, 0, 0, 1118, 0, 0, 5, 5,
'Bloodsail Buccaneers', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 16712190,
'These bloodthirsty corsairs are the bane of many a merchant in the high seas.  Sworn enemies of Booty Bay.',
'', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 16712190);
