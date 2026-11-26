-- Keeper's Scroll: Aman'thul (246199) is a zone-blessing consumable (class 0, subclass 1, stackable 20, casts 84842),
-- matching the sibling Keeper's Scrolls on vendor list 900012 (246194, 97388, 696661-696665). Both item_template and
-- Item.dbc carried InventoryType 21 (INVTYPE_WEAPONMAINHAND) along with weapon damage (0.8-0.8, delay 2000), so it
-- displayed as a Main-Hand weapon in the Ethereal Bazaar (#10306). Reset to non-equippable consumable values and
-- stream the corrected Item.dbc row to clients.
UPDATE `item_template`
SET `InventoryType` = 0, `dmg_min1` = 0, `dmg_max1` = 0, `delay` = 0
WHERE `entry` = 246199;

DELETE FROM `item_dbc` WHERE `ID` = 246199;
INSERT INTO `item_dbc` (`ID`, `ClassID`, `SubclassID`, `Sound_Override_Subclassid`, `Material`, `DisplayInfoID`,
    `InventoryType`, `SheatheType`)
VALUES (246199, 0, 1, -1, 3, 67491, 0, 0);
