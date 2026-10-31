-- Hilda (164596), Shopkeeper Mercel (164040), Edrin Salmear (164022) and Lamar Ryback (164943) use their own gossip
-- menus, which only carry greeting text. Without a vendor or trainer option their shop and training window cannot be
-- opened. Give the menus the same "browse your goods" and "Train me!" options as the default menu 0.
DELETE FROM `gossip_menu_option` WHERE `MenuID` IN (9920063, 9920064, 9920067, 9920068);
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`, `VerifiedBuild`) VALUES
(9920063, 0, 1, 'I want to browse your goods', 3370, 3, 128, 0, 0, 0, 0, '', 0, 0),
(9920064, 0, 1, 'I want to browse your goods', 3370, 3, 128, 0, 0, 0, 0, '', 0, 0),
(9920067, 0, 3, 'Train me!', 3266, 5, 16, 0, 0, 0, 0, '', 0, 0),
(9920067, 1, 1, 'I want to browse your goods', 3370, 3, 128, 0, 0, 0, 0, '', 0, 0),
(9920068, 0, 3, 'Train me!', 3266, 5, 16, 0, 0, 0, 0, '', 0, 0),
(9920068, 1, 1, 'I want to browse your goods', 3370, 3, 128, 0, 0, 0, 0, '', 0, 0);

-- Hilda sold herbs without a stock limit, unlike every other herb seller. Use the most common stock and restock time
-- those vendors use for each herb.
UPDATE `npc_vendor` SET `maxcount` = 3, `incrtime` = 9000 WHERE `entry` = 164596 AND `item` = 765;
UPDATE `npc_vendor` SET `maxcount` = 2, `incrtime` = 9000 WHERE `entry` = 164596 AND `item` = 2447;
UPDATE `npc_vendor` SET `maxcount` = 2, `incrtime` = 7200 WHERE `entry` = 164596 AND `item` IN (785, 2453);
UPDATE `npc_vendor` SET `maxcount` = 3, `incrtime` = 7200 WHERE `entry` = 164596 AND `item` = 2449;
