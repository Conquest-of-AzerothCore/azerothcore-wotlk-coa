-- Hawkrunner Bracers (521075 and its seven upgraded tiers 1379678..1393678) are the only
-- items in Item.dbc using display 7183, whose ItemDisplayInfo row carries the leather bracer
-- texture Leather_Horde_B_03Red_Bracer_AL with the glove icon INV_Gauntlets_15 (#13046).
-- Other ItemDisplayInfo rows with Leather_Horde_B_03Red_Bracer_AL (11684, 24602) use
-- INV_Bracer_08. Keep every client field of row 7183 and replace only InventoryIcon_1;
-- AscensionCompat streams itemdisplayinfo_dbc rows at login via SMSG_PATCH_ITEM_DISPLAY_INFO.
DELETE FROM `itemdisplayinfo_dbc` WHERE `ID` = 7183;
INSERT INTO `itemdisplayinfo_dbc` (`ID`, `ModelName_1`, `ModelName_2`, `ModelTexture_1`, `ModelTexture_2`,
    `InventoryIcon_1`, `InventoryIcon_2`, `GeosetGroup_1`, `GeosetGroup_2`, `GeosetGroup_3`, `Flags`,
    `SpellVisualID`, `GroupSoundIndex`, `HelmetGeosetVis_1`, `HelmetGeosetVis_2`, `Texture_1`, `Texture_2`,
    `Texture_3`, `Texture_4`, `Texture_5`, `Texture_6`, `Texture_7`, `Texture_8`, `ItemVisual`, `ParticleColorID`)
VALUES (7183, '', '', '', '', 'INV_Bracer_08', '', 0, 0, 0, 0, 0, 0, 0, 0, '',
    'Leather_Horde_B_03Red_Bracer_AL', '', '', '', '', '', '', 0, 0);
