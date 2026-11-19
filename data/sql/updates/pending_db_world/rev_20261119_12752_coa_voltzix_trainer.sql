-- Voltzix Sprocketpop (#12752) is the Crossroads Engineering Trainer of his WDB row but only offered quests.
UPDATE `creature_template` SET `npcflag` = 83, `gossip_menu_id` = 9010711 WHERE `entry` = 753524;

DELETE FROM `gossip_menu_option` WHERE `MenuID` = 9010711 AND `OptionID` = 0;
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`,
    `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`,
    `BoxBroadcastTextID`, `VerifiedBuild`) VALUES
(9010711, 0, 3, 'Train me.', 3266, 5, 16, 0, 0, 0, 0, '', 0, 0);

DELETE FROM `creature_default_trainer` WHERE `CreatureId` = 753524;
INSERT INTO `creature_default_trainer` (`CreatureId`, `TrainerId`) VALUES
(753524, 92);
