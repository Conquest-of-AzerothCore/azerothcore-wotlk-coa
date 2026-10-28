-- The client's Item.dbc already carries 190191, and the patch handler overwrites rows in
-- place, so the row has to agree with the new dagger template. Values mirror a real
-- one-hand dagger: class 2, subclass 15, no sound override, metal, display 41688,
-- inventory 13, sheathe 3.
DELETE FROM `item_dbc` WHERE `ID` = 190191;
INSERT INTO `item_dbc` (`ID`, `ClassID`, `SubclassID`, `Sound_Override_Subclassid`, `Material`, `DisplayInfoID`, `InventoryType`, `SheatheType`)
VALUES (190191, 2, 15, -1, 1, 41688, 13, 3);
