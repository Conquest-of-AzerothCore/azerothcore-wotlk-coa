-- CoA #8507 'Durotar's Dire Drought' (1660064):
-- 1. Filling the pitcher (spell 267033) must swap Empty Dirgran's Pitcher (558973) for the full one (558974).
--    The empty item had no charges, so it was never consumed. It is now used up on the cast, so the empty pitcher is
--    no longer required at turn-in (undoes rev_20261019_26).
UPDATE `item_template` SET `spellcharges_1` = -1 WHERE `entry` = 558973;
UPDATE `quest_template` SET `RequiredItemId2` = 0, `RequiredItemCount2` = 0 WHERE `ID` = 1660064;

-- 2. Thirsty Peons (162836) swing a mining pick at the rock wall and vary between orc men and women.
DELETE FROM `creature_template_model` WHERE `CreatureID` = 162836;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(162836, 0, 23037, 1, 1),
(162836, 1, 19181, 1, 1),
(162836, 2, 11857, 1, 1),
(162836, 3, 11859, 1, 1);

DELETE FROM `creature_template_addon` WHERE `entry` = 162836;
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`)
VALUES
(162836, 0, 0, 0, 0, 233, 0, NULL);

DELETE FROM `creature_equip_template` WHERE `CreatureID` = 162836;
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`)
VALUES
(162836, 1, 2901, 0, 0, 0);

UPDATE `creature` SET `equipment_id` = 1 WHERE `id` = 162836;
UPDATE `creature` SET `position_x` = 403.25, `position_y` = -4649.37, `position_z` = 17.41, `orientation` = 5.6054 WHERE `guid` = 9012310;
UPDATE `creature` SET `position_x` = 401.69, `position_y` = -4637.55, `position_z` = 18.68, `orientation` = 2.6126 WHERE `guid` = 9012311;
UPDATE `creature` SET `position_x` = 413.27, `position_y` = -4641.71, `position_z` = 19.056, `orientation` = 4.9247 WHERE `guid` = 9012312;
UPDATE `creature` SET `position_x` = 419.41, `position_y` = -4643.75, `position_z` = 18.744, `orientation` = 4.5403 WHERE `guid` = 9012313;
UPDATE `creature` SET `position_x` = 423.32, `position_y` = -4637.14, `position_z` = 18.389, `orientation` = 1.1742 WHERE `guid` = 9012314;
UPDATE `creature` SET `position_x` = 430.94, `position_y` = -4643.87, `position_z` = 16.811, `orientation` = 5.4786 WHERE `guid` = 9012315;
UPDATE `creature` SET `position_x` = 432.93, `position_y` = -4632.12, `position_z` = 18.563, `orientation` = 2.7161 WHERE `guid` = 9012316;
UPDATE `creature` SET `position_x` = 443.48, `position_y` = -4627.73, `position_z` = 19.292, `orientation` = 1.7975 WHERE `guid` = 9012317;
UPDATE `creature` SET `position_x` = 448.78, `position_y` = -4633.86, `position_z` = 19.966, `orientation` = 5.3442 WHERE `guid` = 9012318;
UPDATE `creature` SET `position_x` = 446.62, `position_y` = -4621.81, `position_z` = 20.931, `orientation` = 3.0977 WHERE `guid` = 9012319;
UPDATE `creature` SET `position_x` = 459.19, `position_y` = -4628.24, `position_z` = 20.13, `orientation` = 5.3952 WHERE `guid` = 9012320;
UPDATE `creature` SET `position_x` = 466.25, `position_y` = -4621.95, `position_z` = 18.706, `orientation` = 6.1851 WHERE `guid` = 9012321;
UPDATE `creature` SET `position_x` = 467.39, `position_y` = -4616.07, `position_z` = 19.11, `orientation` = 0.2459 WHERE `guid` = 9012322;
UPDATE `creature` SET `position_x` = 450.76, `position_y` = -4605.91, `position_z` = 19.504, `orientation` = 0.1244 WHERE `guid` = 9012323;
UPDATE `creature` SET `position_x` = 447.19, `position_y` = -4603.16, `position_z` = 18.92, `orientation` = 5.5834 WHERE `guid` = 9012324;
UPDATE `creature` SET `position_x` = 443.98, `position_y` = -4611.78, `position_z` = 19.577, `orientation` = 4.2827 WHERE `guid` = 9012325;
