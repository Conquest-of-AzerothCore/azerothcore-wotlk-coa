-- Dharil's barded Scadeald horse: 0MqPfOJqF8w at 00:09 and 00:39.
-- Reuse Rocinante's matching display 141913; the reference does not identify the horse's creature entry.
DELETE FROM `creature` WHERE `guid` = 9999200;
INSERT INTO `creature` (
    `guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`,
    `position_x`, `position_y`, `position_z`, `orientation`,
    `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`
) VALUES (
    9999200, 164272, 0, 12, 87, 1, 1,
    -9471, 15, 56.612, 5.08,
    300, 0, 0, 'Pale Reach intro: Dharil horse, placement reconstructed from 0MqPfOJqF8w'
);

UPDATE `gameobject` SET
    `position_x` = -9476,
    `position_y` = 13,
    `position_z` = 56.551,
    `orientation` = 1.506,
    `rotation0` = 0,
    `rotation1` = 0,
    `rotation2` = 0.683831,
    `rotation3` = 0.729641
WHERE `guid` = 26784 AND `id` = 142075;
