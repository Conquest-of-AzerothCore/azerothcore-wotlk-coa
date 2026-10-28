-- Stormwind Old Town training grounds: the Training Dummies (32666) stood inside walls and out of line (playtest).
-- They stand on the spots the author took in game with .gps, which form four rows around the yard; each dummy faces
-- straight out from its row into the yard, as the author stood at it. Ten existing dummies move to their nearest
-- spot and two more are added (9013500-9013501, outside the reserved creature guid blocks).
UPDATE `creature` SET `position_x` = -8723.121, `position_y` = 364.153, `position_z` = 101.091, `orientation` = 4.29,
    `wander_distance` = 0, `MovementType` = 0 WHERE `guid` = 201235 AND `id` = 32666;
UPDATE `creature` SET `position_x` = -8748.429, `position_y` = 333.572, `position_z` = 100.815, `orientation` = 0.976,
    `wander_distance` = 0, `MovementType` = 0 WHERE `guid` = 201236 AND `id` = 32666;
UPDATE `creature` SET `position_x` = -8755.543, `position_y` = 338.387, `position_z` = 100.995, `orientation` = 0.976,
    `wander_distance` = 0, `MovementType` = 0 WHERE `guid` = 201237 AND `id` = 32666;
UPDATE `creature` SET `position_x` = -8730.715, `position_y` = 368.635, `position_z` = 100.832, `orientation` = 4.29,
    `wander_distance` = 0, `MovementType` = 0 WHERE `guid` = 201239 AND `id` = 32666;
UPDATE `creature` SET `position_x` = -8713.612, `position_y` = 339.233, `position_z` = 100.57, `orientation` = 3.305,
    `wander_distance` = 0, `MovementType` = 0 WHERE `guid` = 201241 AND `id` = 32666;
UPDATE `creature` SET `position_x` = -8748.033, `position_y` = 336.485, `position_z` = 100.897, `orientation` = 0.976,
    `wander_distance` = 0, `MovementType` = 0 WHERE `guid` = 201242 AND `id` = 32666;
UPDATE `creature` SET `position_x` = -8716.125, `position_y` = 362.25, `position_z` = 101.013, `orientation` = 4.29,
    `wander_distance` = 0, `MovementType` = 0 WHERE `guid` = 202726 AND `id` = 32666;
UPDATE `creature` SET `position_x` = -8736.289, `position_y` = 319.063, `position_z` = 99.315, `orientation` = 1.856,
    `wander_distance` = 0, `MovementType` = 0 WHERE `guid` = 202727 AND `id` = 32666;
UPDATE `creature` SET `position_x` = -8730.008, `position_y` = 321.048, `position_z` = 99.371, `orientation` = 1.856,
    `wander_distance` = 0, `MovementType` = 0 WHERE `guid` = 202730 AND `id` = 32666;
UPDATE `creature` SET `position_x` = -8724.482, `position_y` = 322.525, `position_z` = 99.676, `orientation` = 1.856,
    `wander_distance` = 0, `MovementType` = 0 WHERE `guid` = 202731 AND `id` = 32666;
DELETE FROM `creature` WHERE `guid` IN (9013500, 9013501);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`,
    `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`,
    `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`,
    `CreateObject`, `Comment`) VALUES
(9013500, 32666, 0, 0, 0, 1, 1, 0, -8752.223, 336.376, 100.95, 0.976, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0,
    'CoA Stormwind Old Town training grounds: Training Dummy, west row'),
(9013501, 32666, 0, 0, 0, 1, 1, 0, -8752.552, 339.664, 101.302, 0.976, 120, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0,
    'CoA Stormwind Old Town training grounds: Training Dummy, west row');
