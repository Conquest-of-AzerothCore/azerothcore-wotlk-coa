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
UPDATE `creature` SET `position_x` = 402.739, `position_y` = -4648.78, `position_z` = 17.0528, `orientation` = 5.52455 WHERE `guid` = 9012310;
UPDATE `creature` SET `position_x` = 402.813, `position_y` = -4638.06, `position_z` = 18.534, `orientation` = 2.70497 WHERE `guid` = 9012311;
UPDATE `creature` SET `position_x` = 413.27, `position_y` = -4641.71, `position_z` = 19.056, `orientation` = 4.9247 WHERE `guid` = 9012312;
UPDATE `creature` SET `position_x` = 419.152, `position_y` = -4642.54, `position_z` = 18.4448, `orientation` = 5.00964 WHERE `guid` = 9012313;
UPDATE `creature` SET `position_x` = 423.041, `position_y` = -4637.86, `position_z` = 18.2155, `orientation` = 1.10226 WHERE `guid` = 9012314;
UPDATE `creature` SET `position_x` = 430.245, `position_y` = -4643.78, `position_z` = 16.4222, `orientation` = 5.18242 WHERE `guid` = 9012315;
UPDATE `creature` SET `position_x` = 433.628, `position_y` = -4632.71, `position_z` = 17.6867, `orientation` = 2.62988 WHERE `guid` = 9012316;
UPDATE `creature` SET `position_x` = 443.868, `position_y` = -4628.45, `position_z` = 19.0962, `orientation` = 2.07617 WHERE `guid` = 9012317;
UPDATE `creature` SET `position_x` = 448.564, `position_y` = -4633.14, `position_z` = 19.5572, `orientation` = 5.40561 WHERE `guid` = 9012318;
UPDATE `creature` SET `position_x` = 446.62, `position_y` = -4621.81, `position_z` = 20.931, `orientation` = 3.0977 WHERE `guid` = 9012319;
UPDATE `creature` SET `position_x` = 458.643, `position_y` = -4627.39, `position_z` = 19.0097, `orientation` = 5.35454 WHERE `guid` = 9012320;
UPDATE `creature` SET `position_x` = 465.402, `position_y` = -4621.38, `position_z` = 18.4323, `orientation` = 6.13601 WHERE `guid` = 9012321;
UPDATE `creature` SET `position_x` = 467.39, `position_y` = -4616.07, `position_z` = 19.11, `orientation` = 0.2459 WHERE `guid` = 9012322;
UPDATE `creature` SET `position_x` = 450.76, `position_y` = -4605.91, `position_z` = 19.504, `orientation` = 0.1244 WHERE `guid` = 9012323;
UPDATE `creature` SET `position_x` = 448.288, `position_y` = -4602.73, `position_z` = 18.6955, `orientation` = 3.70913 WHERE `guid` = 9012324;
UPDATE `creature` SET `position_x` = 443.98, `position_y` = -4611.78, `position_z` = 19.577, `orientation` = 4.2827 WHERE `guid` = 9012325;

-- 3. The pool outside the Razor Hill inn had no water trigger, so Collect Water answered "You can't do this here" there.
DELETE FROM `creature` WHERE `guid` = 9012308;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(9012308, 162949, 1, 0, 0, 1, 1, 0, 334.5207, -4715.389, 13.729, 3.283, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'CoA Razor Hill: the pool outside the inn; invisible, Collect Water reaches 6 yd');

-- 4. Razor Hill Grunts (5953) placed in game.
UPDATE `creature` SET `position_x` = 421.383, `position_y` = -4725.49, `position_z` = 8.96318, `orientation` = 5.62643 WHERE `guid` = 6382;
UPDATE `creature` SET `position_x` = 255.508, `position_y` = -4624.15, `position_z` = 12.2541, `orientation` = 2.21103 WHERE `guid` = 7292;
UPDATE `creature` SET `position_x` = 418.458, `position_y` = -4731.54, `position_z` = 9.10691, `orientation` = 0.156122 WHERE `guid` = 7296;
UPDATE `creature` SET `position_x` = 233.098, `position_y` = -4744.11, `position_z` = 10.1022, `orientation` = 3.08912 WHERE `guid` = 8418;
UPDATE `creature` SET `position_x` = 361.486, `position_y` = -4664.19, `position_z` = 16.2253, `orientation` = 0.375313 WHERE `guid` = 10271;
UPDATE `creature` SET `position_x` = 231.053, `position_y` = -4734.69, `position_z` = 10.1022, `orientation` = 3.69265 WHERE `guid` = 10428;
UPDATE `creature` SET `position_x` = 247.163, `position_y` = -4631.91, `position_z` = 12.0289, `orientation` = 1.88193 WHERE `guid` = 10430;
