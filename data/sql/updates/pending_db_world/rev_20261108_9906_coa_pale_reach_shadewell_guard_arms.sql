-- Shadewell Guards (164136) carry the same sword and round shield as the Dunshire, Cresthairn and Graysky Guards
-- (Iron-Grip Shortsword 36517 and Sentry Buckler 3743, rev_20261013_10 #15); they had no equipment.
DELETE FROM `creature_equip_template` WHERE `CreatureID` = 164136 AND `ID` = 1;
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) VALUES
(164136, 1, 36517, 3743, 0, 0);
UPDATE `creature` SET `equipment_id` = 1 WHERE `id` = 164136;
