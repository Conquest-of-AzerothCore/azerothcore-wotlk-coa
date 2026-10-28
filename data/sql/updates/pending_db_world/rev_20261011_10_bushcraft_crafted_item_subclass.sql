-- Bushcraft's Waterskins (10521-10528) and Campsite (1041704) carry Consumable subclasses 120 and 121 in Item.dbc,
-- which ItemSubClass.dbc does not define. The trade skill window groups recipes by that subclass, so the Bushcraft
-- list breaks (#7188). These rows use subclass 0, as item_template does, and reach the client through the patch
-- stream for every character that knows the recipes.
DELETE FROM `item_dbc` WHERE `ID` IN (10521, 10522, 10523, 10524, 10525, 10526, 10527, 10528, 1041704);
INSERT INTO `item_dbc` (`ID`, `ClassID`, `SubclassID`, `Sound_Override_Subclassid`, `Material`, `DisplayInfoID`,
    `InventoryType`, `SheatheType`)
VALUES
(10521, 0, 0, -1, 4, 29856, 0, 0),
(10522, 0, 0, -1, 4, 29856, 0, 0),
(10523, 0, 0, -1, 4, 29856, 0, 0),
(10524, 0, 0, -1, 4, 29856, 0, 0),
(10525, 0, 0, -1, 4, 29856, 0, 0),
(10526, 0, 0, -1, 4, 29856, 0, 0),
(10527, 0, 0, -1, 4, 29856, 0, 0),
(10528, 0, 0, -1, 4, 29856, 0, 0),
(1041704, 0, 0, -1, 4, 139416, 0, 0);
