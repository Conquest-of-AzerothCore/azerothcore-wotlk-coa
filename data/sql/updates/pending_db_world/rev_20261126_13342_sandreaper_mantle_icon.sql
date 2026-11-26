-- Sandreaper Mantle (item 2080087, Leather Shoulders, InventoryType=3) is the only item in
-- Item.dbc using DisplayInfoID 163737, whose ItemDisplayInfo row has an empty InventoryIcon_1
-- and renders as a '?' icon (#13342). Sibling ItemDisplayInfo rows with the same texture
-- Shoulder_Leather_D_01Black (2023, 8360, 14980, 25442, 40388, 145974, 146159) and the same
-- LShoulder_Leather_B_02.mdx model with Shoulder_Leather_B_02Black (8610) use INV_Shoulder_08.
-- Keep every client field of row 163737 and set InventoryIcon_1; AscensionCompat streams
-- itemdisplayinfo_dbc at login via SMSG_PATCH_ITEM_DISPLAY_INFO.
DELETE FROM `itemdisplayinfo_dbc` WHERE `ID` = 163737;
INSERT INTO `itemdisplayinfo_dbc` (`ID`, `ModelName_1`, `ModelName_2`, `ModelTexture_1`, `ModelTexture_2`,
    `InventoryIcon_1`, `InventoryIcon_2`, `GeosetGroup_1`, `GeosetGroup_2`, `GeosetGroup_3`, `Flags`,
    `SpellVisualID`, `GroupSoundIndex`, `HelmetGeosetVis_1`, `HelmetGeosetVis_2`, `Texture_1`, `Texture_2`,
    `Texture_3`, `Texture_4`, `Texture_5`, `Texture_6`, `Texture_7`, `Texture_8`, `ItemVisual`, `ParticleColorID`)
VALUES (163737, 'LShoulder_Leather_B_02.mdx', 'RShoulder_Leather_B_02.mdx', 'Shoulder_Leather_D_01Black',
    'Shoulder_Leather_D_01Black', 'INV_Shoulder_08', '', 0, 0, 0, 0, 0, 0, 265, 265, '', '', '', '', '', '', '', '',
    0, 0);
