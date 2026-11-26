-- Grim Cloth Armor (item 2080866, Cloth Chest, InventoryType=5) is the only item in Item.dbc
-- using DisplayInfoID 164511, whose ItemDisplayInfo row has an empty InventoryIcon_1 and renders
-- as a '?' icon (#13282). Sibling ItemDisplayInfo rows with the same chest texture
-- Robe_C_03RedBlack_Chest_TU and no pants (6075, 8377, 16572, 147301, 149097, 149200) and
-- sibling chest row 148983 with Robe_C_02Black_Sleeve_AU/AL use INV_Shirt_07. Keep every client
-- field of row 164511 and set InventoryIcon_1; AscensionCompat streams itemdisplayinfo_dbc at
-- login via SMSG_PATCH_ITEM_DISPLAY_INFO.
DELETE FROM `itemdisplayinfo_dbc` WHERE `ID` = 164511;
INSERT INTO `itemdisplayinfo_dbc` (`ID`, `ModelName_1`, `ModelName_2`, `ModelTexture_1`, `ModelTexture_2`,
    `InventoryIcon_1`, `InventoryIcon_2`, `GeosetGroup_1`, `GeosetGroup_2`, `GeosetGroup_3`, `Flags`,
    `SpellVisualID`, `GroupSoundIndex`, `HelmetGeosetVis_1`, `HelmetGeosetVis_2`, `Texture_1`, `Texture_2`,
    `Texture_3`, `Texture_4`, `Texture_5`, `Texture_6`, `Texture_7`, `Texture_8`, `ItemVisual`, `ParticleColorID`)
VALUES (164511, '', '', '', '', 'INV_Shirt_07', '', 0, 0, 0, 0, 0, 0, 0, 0, 'Robe_C_02Black_Sleeve_AU',
    'Robe_C_02Black_Sleeve_AL', '', 'Robe_C_03RedBlack_Chest_TU', 'Robe_C_03RedBlack_Chest_TL', '', '', '', 0, 0);
