-- The Possessed Crow on the Dunshire scarecrow's arm (guid 9920417) walked home to the ground below the arm after
-- evading, since the arm is off the navmesh. On reaching home it now jumps back onto the arm and faces its spawn way.
DELETE FROM `smart_scripts` WHERE `entryorguid` = -9920417 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
    `event_chance`, `event_flags`, `event_param1`, `event_param2`, `action_type`, `action_param1`, `action_param2`,
    `target_type`, `target_x`, `target_y`, `target_z`, `comment`)
VALUES
(-9920417, 0, 0, 0, 7, 0, 100, 0, 0, 0, 91, 1, 0, 1, 0, 0, 0,
 'Possessed Crow (scarecrow arm) - On evade - Clear sitting state before returning home'),
(-9920417, 0, 1, 0, 21, 0, 100, 0, 0, 0, 97, 8, 10, 1, -7786.21, 569.9, 139.34,
 'Possessed Crow (scarecrow arm) - On reached home - Jump onto the scarecrow arm'),
(-9920417, 0, 2, 0, 34, 0, 100, 0, 16, 0, 66, 0, 0, 1, 0, 0, 0,
 'Possessed Crow (scarecrow arm) - On jump landed - Face spawn orientation');
