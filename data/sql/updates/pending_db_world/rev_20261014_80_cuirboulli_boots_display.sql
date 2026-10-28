-- Cuirboulli Boots (2143) uses display 2355, which is the INV_Stone_09 stone icon in Ascension's ItemDisplayInfo, so
-- the boots show as a stone (#4443). Display 664 is the client's INV_Boots_07 leather boot with Leather_B_02 textures,
-- matching Wowhead's inv_boots_07 icon. Descension made the same change (descension-server fix_item_displayids.sql
-- c485e601 and rows_COA-CUSTOM-ITEMDBC.tsv a1a8ec6e, 2026-09-30, read 2026-10-14); the user approved it. The client
-- has no Item.dbc row for 2143, so the row below reaches the client through the patch stream.
UPDATE `item_template` SET `displayid` = 664 WHERE `entry` = 2143;

DELETE FROM `item_dbc` WHERE `ID` = 2143;
INSERT INTO `item_dbc` (`ID`, `ClassID`, `SubclassID`, `Sound_Override_Subclassid`, `Material`, `DisplayInfoID`,
    `InventoryType`, `SheatheType`)
VALUES (2143, 4, 2, -1, 8, 664, 8, 0);
