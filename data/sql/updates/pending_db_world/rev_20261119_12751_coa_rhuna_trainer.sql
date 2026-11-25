-- Rhuna (#12751) is the Crossroads Leatherworking Trainer of her WDB row but only offered quests.
UPDATE `creature_template` SET `npcflag` = 83, `gossip_menu_id` = 9010710 WHERE `entry` = 41739;

DELETE FROM `gossip_menu_option` WHERE `MenuID` = 9010710 AND `OptionID` = 0;
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`,
    `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`,
    `BoxBroadcastTextID`, `VerifiedBuild`) VALUES
(9010710, 0, 3, 'Train me.', 3266, 5, 16, 0, 0, 0, 0, '', 0, 0);

DELETE FROM `creature_default_trainer` WHERE `CreatureId` = 41739;
INSERT INTO `creature_default_trainer` (`CreatureId`, `TrainerId`) VALUES
(41739, 61);
