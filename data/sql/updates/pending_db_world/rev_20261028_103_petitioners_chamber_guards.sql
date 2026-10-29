-- Petitioner's Chamber Stormwind Royal Guards, placed in game with CoA World Edit.
DELETE FROM `creature` WHERE `guid` IN (9999280, 9999281, 9999282, 9999283, 9999284, 9999285, 9999286, 9999287);
INSERT INTO `creature` (
    `guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`,
    `position_x`, `position_y`, `position_z`, `orientation`,
    `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`
) VALUES
(9999280, 1756, 0, 1519, 0, 1, 1, 1, -8311.413, 301.899, 126.933, 3.8361, 300, 0, 0, 'Petitioner''s Chamber guard'),
(9999281, 1756, 0, 1519, 0, 1, 1, 1, -8305.276, 294.273, 126.933, 3.8008, 300, 0, 0, 'Petitioner''s Chamber guard'),
(9999282, 1756, 0, 1519, 0, 1, 1, 1, -8308.567, 273.679, 126.932, 2.2457, 300, 0, 0, 'Petitioner''s Chamber guard'),
(9999283, 1756, 0, 1519, 0, 1, 1, 1, -8332.251, 303.022, 126.932, 5.3833, 300, 0, 0, 'Petitioner''s Chamber guard'),
(9999284, 1756, 0, 1519, 0, 1, 1, 1, -8335.592, 282.306, 126.932, 0.6505, 300, 0, 0, 'Petitioner''s Chamber guard'),
(9999285, 1756, 0, 1519, 0, 1, 1, 1, -8329.322, 274.950, 126.932, 0.6505, 300, 0, 0, 'Petitioner''s Chamber guard'),
(9999286, 1756, 0, 1519, 0, 1, 1, 1, -8299.769, 299.390, 126.932, 0.6835, 300, 0, 0, 'Petitioner''s Chamber guard'),
(9999287, 1756, 0, 1519, 0, 1, 1, 1, -8304.790, 305.940, 126.932, 0.6835, 300, 0, 0, 'Petitioner''s Chamber guard');
