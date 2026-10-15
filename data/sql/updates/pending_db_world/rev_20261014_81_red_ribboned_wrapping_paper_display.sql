-- Red Ribboned Wrapping Paper (5042) uses display 6405, which is the INV_Misc_Book_09 book icon in Ascension's
-- ItemDisplayInfo (#6540). Display 3864 is the client's INV_Misc_GiftWrap_02 gift wrap, matching Wowhead's
-- inv_misc_giftwrap_02 icon. Descension made the same change (descension-server fix_item_displayids.sql c485e601 and
-- rows_COA-CUSTOM-ITEMDBC.tsv a1a8ec6e, 2026-09-30, read 2026-10-14); the user approved it. The client has no
-- Item.dbc row for 5042, so the row below reaches the client through the patch stream.
UPDATE `item_template` SET `displayid` = 3864 WHERE `entry` = 5042;

DELETE FROM `item_dbc` WHERE `ID` = 5042;
INSERT INTO `item_dbc` (`ID`, `ClassID`, `SubclassID`, `Sound_Override_Subclassid`, `Material`, `DisplayInfoID`,
    `InventoryType`, `SheatheType`)
VALUES (5042, 0, 8, -1, -1, 3864, 0, 0);
