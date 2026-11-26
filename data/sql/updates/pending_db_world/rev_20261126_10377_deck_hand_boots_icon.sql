-- Deck Hand Boots (2081389, Cloth Feet) is the sole item using display 165025, whose ItemDisplayInfo.dbc row has an
-- empty InventoryIcon_1 in both server and client DBCs (#10377). Stock Cloth_B_05SwashA_Boot_LL/FO boots with
-- GeosetGroup_1 = 2 (display 15596: Buccaneer's Boots 14174, Bloodsail Boots 22744, Mistwalker Boots 10629; display
-- 28382) use INV_Boots_05, matching the classic INV_*_NN icon family of the rest of the 2081385..2081389 pirate set.
DELETE FROM `itemdisplayinfo_dbc` WHERE `ID` = 165025;
INSERT INTO `itemdisplayinfo_dbc` (`ID`, `ModelName_1`, `ModelName_2`, `ModelTexture_1`, `ModelTexture_2`,
    `InventoryIcon_1`, `InventoryIcon_2`, `GeosetGroup_1`, `GeosetGroup_2`, `GeosetGroup_3`, `Flags`,
    `SpellVisualID`, `GroupSoundIndex`, `HelmetGeosetVis_1`, `HelmetGeosetVis_2`, `Texture_1`, `Texture_2`,
    `Texture_3`, `Texture_4`, `Texture_5`, `Texture_6`, `Texture_7`, `Texture_8`, `ItemVisual`, `ParticleColorID`)
VALUES (165025, '', '', '', '', 'INV_Boots_05', '', 2, 0, 0, 0, 0, 0, 0, 0, '', '', '', '', '', '',
    'Cloth_B_05SwashA_Boot_LL', 'Cloth_B_05SwashA_Boot_FO', 0, 0);
