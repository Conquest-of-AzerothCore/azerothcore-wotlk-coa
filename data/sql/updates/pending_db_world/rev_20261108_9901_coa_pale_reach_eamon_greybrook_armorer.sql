-- Eamon Greybrook (164142), the Shadewell Armorer, sells and repairs like Teno Greybrook and holds a blacksmith hammer
-- (RIEMlZSgbQw at 2:03:12: page 1 of her shop matches Teno's list item for item, and the window has Repair Items).
UPDATE `creature_template` SET `npcflag` = 4225 WHERE `entry` = 164142;

DELETE FROM `gossip_menu_option` WHERE `MenuID` = 1200350 AND `OptionID` = 0;
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`, `VerifiedBuild`) VALUES
(1200350, 0, 1, 'I want to browse your goods.', 3370, 3, 128, 0, 0, 0, 0, '', 0, 0);

DELETE FROM `npc_vendor` WHERE `entry` = 164142;
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`) VALUES
(164142, 0, 2901, 0, 0, 0, 0),
(164142, 1, 5956, 0, 0, 0, 0),
(164142, 2, 7005, 0, 0, 0, 0),
(164142, 3, 2880, 0, 0, 0, 0),
(164142, 4, 3466, 0, 0, 0, 0),
(164142, 5, 3857, 0, 0, 0, 0),
(164142, 6, 2148, 0, 0, 0, 0),
(164142, 7, 2149, 0, 0, 0, 0),
(164142, 8, 2150, 0, 0, 0, 0),
(164142, 9, 2151, 0, 0, 0, 0),
(164142, 10, 2152, 0, 0, 0, 0),
(164142, 11, 2153, 0, 0, 0, 0),
(164142, 12, 2446, 0, 0, 0, 0),
(164142, 13, 17192, 0, 0, 0, 0);

DELETE FROM `creature_equip_template` WHERE `CreatureID` = 164142;
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) VALUES
(164142, 1, 5956, 0, 0, 0);
UPDATE `creature` SET `equipment_id` = 1 WHERE `guid` = 9960577 AND `id` = 164142;
