-- Fey Dust (175025) and X4q-gj8abxs at 01:33: shake enchanted flowers to summon the sprites.
DELETE FROM `creature` WHERE `id` = 164223;

DELETE FROM `gameobject` WHERE `guid` IN (9999203, 9999204, 9999205, 9999206, 9999207, 9999208);
INSERT INTO `gameobject` (
    `guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`,
    `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `state`, `Comment`
) VALUES
(9999203, 2300638, 0, 1, 1, -7929.87, 448.285, 161.875, 0, 0, 0, 0, 1, 120, 1, 'Fey Dust enchanted flowers'),
(9999204, 2300639, 0, 1, 1, -7917.44, 462.496, 152.305, 0, 0, 0, 0, 1, 120, 1, 'Fey Dust enchanted flowers'),
(9999205, 2300638, 0, 1, 1, -7941.73, 369.845, 184.312, 0, 0, 0, 0, 1, 120, 1, 'Fey Dust enchanted flowers'),
(9999206, 2300639, 0, 1, 1, -7915.21, 304.243, 236.109, 0, 0, 0, 0, 1, 120, 1, 'Fey Dust enchanted flowers'),
(9999207, 2300638, 0, 1, 1, -7919.55, 341.389, 218.175, 0, 0, 0, 0, 1, 120, 1, 'Fey Dust enchanted flowers'),
(9999208, 2300639, 0, 1, 1, -7966.87, 364.148, 183.887, 0, 0, 0, 0, 1, 120, 1, 'Fey Dust enchanted flowers');

UPDATE `gameobject_template` SET `AIName` = 'SmartGameObjectAI', `Data3` = 30000
WHERE `entry` IN (2300638, 2300639);

DELETE FROM `smart_scripts` WHERE `entryorguid` IN (2300638, 2300639) AND `source_type` = 1;
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`,
    `target_type`, `comment`
) VALUES
(2300638, 1, 0, 0, 70, 0, 100, 0, 2, 12, 164223, 4, 60000, 2, 1,
    'Dunshire Enchanted Flowers - On Activation - Summon Petal Prowler attacking the user'),
(2300639, 1, 0, 0, 70, 0, 100, 0, 2, 12, 164223, 4, 60000, 2, 1,
    'Dunshire Enchanted Flowers - On Activation - Summon Petal Prowler attacking the user');
