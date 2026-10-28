-- Exact original spawn records recovered from the feature baseline creature.sql.
-- These records are not registered in the global creature store or grid index.
CREATE TABLE IF NOT EXISTS `manastorm_private_creature` (
  `guid` INT UNSIGNED NOT NULL,
  `id` INT UNSIGNED NOT NULL,
  `map` SMALLINT UNSIGNED NOT NULL,
  `phaseMask` INT UNSIGNED NOT NULL,
  `equipment_id` TINYINT NOT NULL,
  `position_x` FLOAT NOT NULL,
  `position_y` FLOAT NOT NULL,
  `position_z` FLOAT NOT NULL,
  `orientation` FLOAT NOT NULL,
  `spawntimesecs` INT UNSIGNED NOT NULL,
  `wander_distance` FLOAT NOT NULL,
  `currentwaypoint` INT UNSIGNED NOT NULL,
  `curhealth` INT UNSIGNED NOT NULL,
  `curmana` INT UNSIGNED NOT NULL,
  `MovementType` TINYINT UNSIGNED NOT NULL,
  `npcflag` INT UNSIGNED NOT NULL,
  `unit_flags` INT UNSIGNED NOT NULL,
  `dynamicflags` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELETE FROM `manastorm_private_creature` WHERE `guid` IN (13366,31780,31953,31955,31956,31957,31958,31960,31961,31968,31969,52233,56606,56607);
INSERT INTO `manastorm_private_creature` (`guid`, `id`, `map`, `phaseMask`, `equipment_id`, `position_x`, `position_y`,
`position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`,
`MovementType`, `npcflag`, `unit_flags`, `dynamicflags`) VALUES
(13366,7333,129,1,0,2576.04,1021.49,51.3276,3.7573,86400,1,0,1279,0,1,0,0,0),
(31780,7332,129,1,1,2569.79,971.022,50.7828,3.1765,86400,1,0,3489,0,1,0,0,0),
(31953,7327,129,1,1,2562.1,968.441,50.8742,4.3838,86400,0,0,3489,0,0,0,0,0),
(31955,7335,129,1,1,2559.65,965.8,51.1945,2.56314,86400,0,0,2706,5360,0,0,0,0),
(31956,7332,129,1,1,2574.1,946.096,53.3541,5.55015,86400,1,0,3489,0,1,0,0,0),
(31957,7332,129,1,1,2590.17,961.162,51.9107,0.942478,86400,0,0,3489,0,0,0,0,0),
(31958,7333,129,1,0,2588.91,956.452,52.2107,4.28424,86400,1,0,1279,0,1,0,0,0),
(31960,7333,129,1,0,2585.71,958.797,52.1868,0.226893,86400,1,0,1279,0,1,0,0,0),
(31961,7333,129,1,0,2592.22,960.386,51.8804,1.88311,86400,1,0,1279,0,1,0,0,0),
(31968,7327,129,1,1,2573.84,937.473,54.2629,4.00769,86400,0,0,3489,0,0,0,0,0),
(31969,7335,129,1,1,2566.57,941.89,54.3936,2.52156,86400,0,0,2706,5360,0,0,0,0),
(52233,10384,329,1,0,3683.31,-3327.97,124.96,0.162112,86400,5,0,5398,0,1,0,0,0),
(56606,12119,409,1,1,1035.67,-989.742,-181.776,6.18019,7200,0,0,90650,25680,0,0,0,0),
(56607,12119,409,1,1,1038.51,-982.952,-181.258,5.8443,7200,0,0,90650,25680,0,0,0,0);
