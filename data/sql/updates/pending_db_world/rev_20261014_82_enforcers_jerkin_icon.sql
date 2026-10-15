-- Enforcer's Jerkin (2080006) uses display 163656, whose ItemDisplayInfo row has no inventory icon (#6993). Client
-- displays with the same eight Leather_B_02Black textures and no model mostly use INV_Chest_Leather_08 (3564, 6371
-- Blackened Defias Armor, 8604, 147056, 147673, 147690), so the row keeps the client's values with that icon.
-- The user approved this inferred icon. ItemDisplayInfo rows reach every client through the login patch stream.
DELETE FROM `itemdisplayinfo_dbc` WHERE `ID` = 163656;
INSERT INTO `itemdisplayinfo_dbc` (`ID`, `ModelName_1`, `ModelName_2`, `ModelTexture_1`, `ModelTexture_2`,
    `InventoryIcon_1`, `InventoryIcon_2`, `GeosetGroup_1`, `GeosetGroup_2`, `GeosetGroup_3`, `Flags`,
    `SpellVisualID`, `GroupSoundIndex`, `HelmetGeosetVis_1`, `HelmetGeosetVis_2`, `Texture_1`, `Texture_2`,
    `Texture_3`, `Texture_4`, `Texture_5`, `Texture_6`, `Texture_7`, `Texture_8`, `ItemVisual`, `ParticleColorID`)
VALUES (163656, '', '', '', '', 'INV_Chest_Leather_08', '', 0, 0, 0, 0, 0, 0, 0, 0, 'Leather_B_02Black_Sleeve_AU',
    'Leather_B_02Black_Sleeve_AL', '', 'Leather_B_02Black_Chest_TU', 'Leather_B_02Black_Chest_TL', '', '', '', 0, 0);
