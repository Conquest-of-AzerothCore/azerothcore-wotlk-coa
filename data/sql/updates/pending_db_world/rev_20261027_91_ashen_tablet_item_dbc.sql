-- Ashen Tablet (9302130, a Sunstrider Isle class-letter item, rev_20260923_13) has no client Item.dbc row, so the
-- client drew a question mark instead of its display's stone-tablet icon (#6749). Its item_template already sets
-- class 12, subclass 0, displayid 3108 (INV_Misc_StoneTablet_04, shared with its siblings Bone-Bound Codex 9302123
-- and Runed Tablet 9302132) and Material 0; the same class/subclass/Material combination for a CoA custom quest
-- item was already added for 9707001-9707008 (rev_20261023_50). The row below reaches the client through the
-- item patch stream.
DELETE FROM `item_dbc` WHERE `ID` = 9302130;
INSERT INTO `item_dbc` (`ID`, `ClassID`, `SubclassID`, `Sound_Override_Subclassid`, `Material`, `DisplayInfoID`,
    `InventoryType`, `SheatheType`)
VALUES (9302130, 12, 0, -1, 0, 3108, 0, 0);
