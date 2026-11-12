-- Arendor (164262), the SI:7 agent at Kerebor, stood empty-handed. His quest window in RIEMlZSgbQw 3:46:00-3:47:22
-- shows a curved gold dagger in each hand, and his gossip speaks of his daggers; his outfit there already matches.
DELETE FROM `creature_equip_template` WHERE `CreatureID` = 164262 AND `ID` = 1;
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) VALUES
(164262, 1, 12260, 12260, 0, 0);
UPDATE `creature` SET `equipment_id` = 1 WHERE `guid` = 9960460 AND `id` = 164262;
