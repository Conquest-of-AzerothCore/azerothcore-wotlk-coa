-- The Book of Ascension teaches Heartwood Key (808075, creates 1041710), but neither the server nor the client has
-- item 1041710. It follows its sibling Grovewood Key (1041709) and opens locks through 808074, the client's Heartwood
-- Key spell (lockpicking 300 where Grovewood's 808067 opens 200). Its display 171077 is a free ItemDisplayInfo id
-- inside the client's range, so the Item and ItemDisplayInfo rows below reach the client through the patch stream.
DELETE FROM `itemdisplayinfo_dbc` WHERE `ID` = 171077;
INSERT INTO `itemdisplayinfo_dbc` (`ID`, `ModelName_1`, `ModelName_2`, `ModelTexture_1`, `ModelTexture_2`,
    `InventoryIcon_1`, `InventoryIcon_2`, `GeosetGroup_1`, `GeosetGroup_2`, `GeosetGroup_3`, `Flags`,
    `SpellVisualID`, `GroupSoundIndex`, `HelmetGeosetVis_1`, `HelmetGeosetVis_2`, `Texture_1`, `Texture_2`,
    `Texture_3`, `Texture_4`, `Texture_5`, `Texture_6`, `Texture_7`, `Texture_8`, `ItemVisual`, `ParticleColorID`)
VALUES (171077, '', '', '', '', '_KeyGoldBlood', '', 0, 0, 0, 0, 0, 0, 0, 0, '', '', '', '', '', '', '', '', 0, 0);

DELETE FROM `item_dbc` WHERE `ID` = 1041710;
INSERT INTO `item_dbc` (`ID`, `ClassID`, `SubclassID`, `Sound_Override_Subclassid`, `Material`, `DisplayInfoID`,
    `InventoryType`, `SheatheType`)
VALUES (1041710, 13, 1, -1, 1, 171077, 0, 0);

CREATE TEMPORARY TABLE `heartwood_key` ENGINE=InnoDB AS
    SELECT * FROM `item_template` WHERE `entry` = 1041709;
UPDATE `heartwood_key` SET `entry` = 1041710, `name` = 'Heartwood Key', `displayid` = 171077, `spellid_1` = 808074;
INSERT INTO `item_template` SELECT * FROM `heartwood_key`
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `displayid` = VALUES(`displayid`), `spellid_1` = VALUES(`spellid_1`);
DROP TEMPORARY TABLE `heartwood_key`;
