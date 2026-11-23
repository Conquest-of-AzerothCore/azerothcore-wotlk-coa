-- The Possessed Crow on the Dunshire scarecrow (guid 9920417) stood at z 139.34, the underside of the arm in
-- Worgen_Scarecrow.m2, so it dropped through to the ground; the client does not stand creatures on the scarecrow at
-- all. It now perches on the scarecrow's hat (top 140.286, picked in game) just above the surface, where the server
-- counts it as airborne and sends it without gravity, and jumps back to the same spot after evading.
UPDATE `creature` SET `position_x` = -7786.923, `position_y` = 568.814, `position_z` = 140.37
    WHERE `guid` = 9920417 AND `id` = 164944;

DELETE FROM `creature_movement_override` WHERE `SpawnId` = 9920417;
INSERT INTO `creature_movement_override` (`SpawnId`, `Flight`) VALUES (9920417, 1);

DELETE FROM `smart_scripts` WHERE `entryorguid` = -9920417 AND `source_type` = 0 AND `id` IN (0, 1, 2);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
    `event_chance`, `event_flags`, `event_param1`, `event_param2`, `action_type`, `action_param1`, `action_param2`,
    `target_type`, `target_x`, `target_y`, `target_z`, `comment`)
VALUES
(-9920417, 0, 0, 0, 7, 0, 100, 0, 0, 0, 91, 1, 0, 1, 0, 0, 0,
 'Possessed Crow (scarecrow hat) - On evade - Clear sitting state before returning home'),
(-9920417, 0, 1, 0, 21, 0, 100, 0, 0, 0, 97, 8, 10, 1, -7786.923, 568.814, 140.37,
 'Possessed Crow (scarecrow hat) - On reached home - Jump onto the scarecrow hat'),
(-9920417, 0, 2, 0, 34, 0, 100, 0, 16, 0, 66, 0, 0, 1, 0, 0, 0,
 'Possessed Crow (scarecrow hat) - On jump landed - Face spawn orientation');
