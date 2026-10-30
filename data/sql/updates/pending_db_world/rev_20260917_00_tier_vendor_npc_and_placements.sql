-- The Reaper tier moves off Horace Hunderland and onto a vendor of its own.
--
-- Horace already carries 140 items. Adding twenty more put him at 160, and the 3.x vendor frame
-- does not survive a list that long: opening him crashed the client outright. Raising
-- MAX_VENDOR_ITEMS to what the packet allows only moved the failure from "the tail is missing" to
-- "the client dies", so the limit stays at 150 and this set gets its own quartermaster. There is
-- room for one per class family beside him as the other tiers arrive.
DELETE FROM `npc_vendor` WHERE `entry` = 35498 AND `item` BETWEEN 992001 AND 992099;

DELETE FROM `creature_template_model` WHERE `CreatureID` = 990011;
DELETE FROM `creature_template` WHERE `entry` = 990011;
INSERT INTO `creature_template`
  (`entry`, `name`, `subname`, `IconName`, `minlevel`, `maxlevel`, `faction`, `npcflag`,
   `speed_walk`, `speed_run`, `unit_class`, `unit_flags`, `type`, `AIName`, `MovementType`,
   `flags_extra`)
VALUES
  (990011, 'Keeper of the Risen Nightmare', 'Ascension Tier Sets', 'Buy', 75, 75, 2007, 4224,
   1, 1.14286, 1, 2, 7, '', 0, 2);

-- Display 29833 is Horace's own, so the new vendor reads as one more merchant on that floor.
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(990011, 0, 29833, 1, 1);

-- Placed between Horace (5918.86, 662.96, 643.58) and Griselda Hunderland (5920.33, 666.26, 643.54),
-- so the floor height comes from two confirmed spawns rather than a guess.
DELETE FROM `creature` WHERE `guid` = 5400004;
INSERT INTO `creature`
  (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`,
   `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`,
   `currentwaypoint`, `curhealth`, `curmana`, `MovementType`)
VALUES
  (5400004, 990011, 571, 0, 0, 1, 1, 0, 5921.50, 664.50, 643.56, 2.548, 300, 0, 0, 1, 0, 0);

DELETE FROM `npc_vendor` WHERE `entry` = 990011;
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`) VALUES
-- item level 251
(990011, 0, 992001, 0, 0, 2741), (990011, 0, 992002, 0, 0, 2739), (990011, 0, 992003, 0, 0, 2741),
(990011, 0, 992004, 0, 0, 2741), (990011, 0, 992005, 0, 0, 2739),
-- item level 264
(990011, 0, 992011, 0, 0, 2742), (990011, 0, 992012, 0, 0, 2740), (990011, 0, 992013, 0, 0, 2742),
(990011, 0, 992014, 0, 0, 2742), (990011, 0, 992015, 0, 0, 2740),
-- item level 277
(990011, 0, 992021, 0, 0, 2742), (990011, 0, 992022, 0, 0, 2740), (990011, 0, 992023, 0, 0, 2742),
(990011, 0, 992024, 0, 0, 2742), (990011, 0, 992025, 0, 0, 2740),
-- item level 284
(990011, 0, 992031, 0, 0, 2742), (990011, 0, 992032, 0, 0, 2740), (990011, 0, 992033, 0, 0, 2742),
(990011, 0, 992034, 0, 0, 2742), (990011, 0, 992035, 0, 0, 2740);

-- The level scaling NPC belongs in the bank, where it was. It went to the entrance by mistake.
UPDATE `creature`
SET `position_x` = 1630.00, `position_y` = -4372.50, `position_z` = 12.05, `orientation` = 3.500
WHERE `guid` = 5400003;

-- The dummies were three yards apart along X, which is the direction the character faces at that
-- spot, so they stood one behind the other. Offset them along Y instead: side by side, six yards
-- apart, which is also a target pair worth testing area damage on.
UPDATE `creature` SET `position_x` = 1481.73, `position_y` = -4392.50, `position_z` = 26.68 WHERE `guid` = 5400001;
UPDATE `creature` SET `position_x` = 1481.73, `position_y` = -4398.50, `position_z` = 26.68 WHERE `guid` = 5400002;
