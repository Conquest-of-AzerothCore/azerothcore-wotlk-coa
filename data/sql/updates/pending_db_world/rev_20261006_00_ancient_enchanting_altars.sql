-- Ancient Enchanting Altars: four existing Azeroth map markers and three Outland locations.
-- These services are primarily used by Free Pick and Bronzebeard realms.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `size`, `Data1`)
SELECT 80148, 4, 8304, 'Ancient Enchanting Altar', 2, 45004
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`),
`name` = VALUES(`name`), `size` = VALUES(`size`), `Data1` = VALUES(`Data1`);

DELETE FROM `gameobject` WHERE `guid` BETWEEN 8001329 AND 8001335 AND `id` = 80148;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`,
`orientation`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`) VALUES
(8001329, 80148, 0, 1, 1, -10938.5, -1871.22, -17.9654, 6.07857, 0.102131, -0.994771, 300, 0, 1),
(8001330, 80148, 0, 1, 1, 36.2729, 342.906, 47.8133, 4.69214, 0.714229, -0.699912, 300, 0, 1),
(8001331, 80148, 1, 1, 1, 3998.74, -4779.94, 304.779, 6.26054, 0.0113241, -0.999936, 300, 0, 1),
(8001332, 80148, 1, 1, 1, -6805.18, 1651.45, 6.36973, 3.07003, 0.99936, 0.0357725, 300, 0, 1),
(8001333, 80148, 530, 1, 1, 2232.94, 2254.14, 134.892, 1.73144, 0.761563, 0.648091, 300, 0, 1),
(8001334, 80148, 530, 1, 1, -3211.93, 5093.37, -74.7549, 3.97248, 0.914937, -0.403596, 300, 0, 1),
(8001335, 80148, 530, 1, 1, -2720.4, 8331.78, -80.7903, 1.56624, 0.705493, 0.708717, 300, 0, 1);
