-- The pair of training dummies at the Orgrimmar entrance.
-- 1. Two training dummies at the Valley of Strength entrance, where a player leaving the city
--    passes anyway: (1481.73, -4395.51, 26.68), a ground height taken from a character standing
--    there rather than guessed. The second sits three yards along the same contour.
DELETE FROM `creature` WHERE `guid` IN (5400001, 5400002);
INSERT INTO `creature`
  (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`,
   `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`,
   `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `Comment`)
VALUES
  (5400001, 31144, 1, 0, 0, 1, 1, 0, 1481.73, -4395.51, 26.68, 6.229, 300, 0, 0, 1, 0, 0, 'Orgrimmar entrance training dummy (level 80)'),
  (5400002, 31146, 1, 0, 0, 1, 1, 0, 1484.70, -4396.50, 26.60, 6.229, 300, 0, 0, 1, 0, 0, 'Orgrimmar entrance training dummy (level 83 boss)');
