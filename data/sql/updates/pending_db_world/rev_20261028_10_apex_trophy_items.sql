-- Apex hunt trophies, the diploma that carries the title, and their icons.

-- Icons first: the client resolves an item's icon from ItemDisplayInfo, so each
-- item gets its own row here and the server streams these to the client.
DELETE FROM `itemdisplayinfo_dbc` WHERE `ID` IN (990002, 990003, 990004, 990005);
INSERT INTO `itemdisplayinfo_dbc` (`ID`, `InventoryIcon_1`) VALUES
(990002, 'trade_archaeology_apexisscroll'),
(990003, 'inv_misc_pelt_07'),
(990004, 'inv_misc_pelt_08'),
(990005, 'inv_misc_scales_reptileviolet03');

-- Stormfang Pelt, Scarred Owlcat Pelt and Tide-Warped Hide are the three quest
-- trophies. The Diploma is the keepsake handed over with them.
DELETE FROM `item_template` WHERE `entry` IN (1009100, 1009101, 1009102, 1009103);
INSERT INTO `item_template`
(`entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`, `BuyCount`, `BuyPrice`,
 `SellPrice`, `InventoryType`, `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`,
 `maxcount`, `stackable`, `bonding`, `description`, `Material`, `VerifiedBuild`) VALUES
(1009101, 12, 0, 'Stormfang Pelt',        990003, 5, 0, 1, 0, 0, 0, -1, -1, 60, 0, 1, 1, 4,
 'Still crackling. The fur will not lie flat.', 0, 0),
(1009102, 12, 0, 'Scarred Owlcat Pelt',   990004, 5, 0, 1, 0, 0, 0, -1, -1, 60, 0, 1, 1, 4,
 'Twenty years of ogre spears, written in scar tissue.', 0, 0),
(1009103, 12, 0, 'Tide-Warped Hide',      990005, 5, 0, 1, 0, 0, 0, -1, -1, 60, 0, 1, 1, 4,
 'It smells of deep water and old drowned prayers.', 0, 0),
(1009100, 15, 0, 'Diploma of the Apex Hunt', 990002, 5, 0, 1, 0, 0, 0, -1, -1, 60, 0, 1, 1, 1,
 'Grants the title: Apex Hunter.', 0, 0);
