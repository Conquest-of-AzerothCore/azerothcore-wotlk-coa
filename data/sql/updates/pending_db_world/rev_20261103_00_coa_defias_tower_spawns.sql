-- Defias Tower, Westfall (#9912, #9690): the Defias Trappers, Smugglers and Looters around and inside the tower,
-- below Lenore the Hoarder. Positions, facings, poses, emotes and the patrol are placed in game against
-- Ascension footage; the archive (Exiles DB export 2026-09-13) has no Defias spawns at the tower.
-- A wandering Fleshripper spawn sat in the tower's west-side camp; the camp is the Defias' now.
DELETE FROM `creature` WHERE `guid` = 86143 AND `id` = 1109;
DELETE FROM `creature` WHERE `guid` BETWEEN 9950700 AND 9950729;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`,
  `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`,
  `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`,
  `CreateObject`, `Comment`) VALUES
(9950700, 504, 0, 40, 40, 1, 1, 1, -10269.944, 1735.1421, 35.93109, 4.236514, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0,
  'Defias Trapper (Defias Tower, outside right)'),
(9950701, 95, 0, 40, 40, 1, 1, 1, -10277.009, 1738.783, 35.804, 4.236514, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0,
  'Defias Smuggler (Defias Tower, outside left, beside #1)'),
(9950702, 95, 0, 40, 40, 1, 1, 1, -10253.014, 1748.2959, 36.229195, 0.20741223, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0,
  'Defias Smuggler (Defias Tower, outside right, talking with #4)'),
(9950703, 504, 0, 40, 40, 1, 1, 1, -10248.638, 1749.3007, 36.026257, 3.3922038, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0,
  'Defias Trapper (Defias Tower, outside right, talking with #3)'),
(9950704, 95, 0, 40, 40, 1, 1, 1, -10235.876, 1757.601, 36.97103, 2.3075798, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0,
  'Defias Smuggler (Defias Tower, outside right, sparring)'),
(9950705, 504, 0, 40, 40, 1, 1, 1, -10278.789, 1775.6936, 37.45338, 0.18937248, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0,
  'Defias Trapper (Defias Tower, outside left, sparring)'),
(9950706, 590, 0, 40, 40, 1, 1, 1, -10261.866, 1774.9775, 39.455067, 4.914342, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0,
  'Defias Looter (Defias Tower, inside the door, left)'),
(9950707, 95, 0, 40, 40, 1, 1, 1, -10283.799, 1779.4435, 37.87306, 5.695094, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0,
  'Defias Smuggler (Defias Tower, outside left, behind #6)'),
(9950708, 590, 0, 40, 40, 1, 1, 1, -10242.071, 1764.498, 65.9114, 3.7441993, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0,
  'Defias Looter (Defias Tower, upper floor, asleep)'),
(9950709, 590, 0, 40, 40, 1, 1, 1, -10270.052, 1776.1395, 65.90816, 1.5804431, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0,
  'Defias Looter (Defias Tower, upper floor, asleep)'),
(9950710, 590, 0, 40, 40, 1, 1, 1, -10265.531, 1781.232, 52.720543, 5.762078, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0,
  'Defias Looter (Defias Tower, middle floor)'),
(9950711, 590, 0, 40, 40, 1, 1, 1, -10241.066, 1776.9951, 44.122124, 6.228834, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0,
  'Defias Looter (Defias Tower, stair landing)'),
(9950712, 590, 0, 40, 40, 1, 1, 1, -10251.7705, 1764.8564, 39.455402, 2.9066293, 300, 0, 0, 0, 0, 2, 0, 0, 0, '', 0, 0,
  'Defias Looter (Defias Tower, ground floor, walks the stairs)'),
(9950713, 590, 0, 40, 40, 1, 1, 1, -10252.673, 1794.2213, 65.905235, 0.12363738, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0,
  'Defias Looter (Defias Tower, upper floor, asleep)'),
(9950714, 590, 0, 40, 40, 1, 1, 1, -10258.332, 1769.1449, 49.77498, 1.0881834, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0,
  'Defias Looter (Defias Tower, middle floor stairs)'),
(9950715, 95, 0, 40, 40, 1, 1, 1, -10286.629, 1710.9095, 37.1944, 1.6325648, 300, 0, 0, 0, 0, 2, 0, 0, 0, '', 0, 0,
  'Defias Smuggler (Defias Tower, walks the west side)'),
(9950716, 504, 0, 40, 40, 1, 1, 1, -10247.466, 1779.0969, 39.45528, 1.9742162, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0,
  'Defias Trapper (Defias Tower, ground floor inside, talking with the Looter beside it)'),
(9950717, 590, 0, 40, 40, 1, 1, 1, -10249.897, 1782.4937, 39.45528, 5.4614134, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0,
  'Defias Looter (Defias Tower, ground floor inside, talking with the Trapper beside it)'),
(9950718, 590, 0, 40, 40, 1, 1, 1, -10246.659, 1787.5305, 46.899685, 0.63120437, 300, 0, 0, 0, 0, 2, 0, 0, 0, '', 0, 0,
  'Defias Looter (Defias Tower, walks the far stairs down to the door)'),
(9950719, 95, 0, 40, 40, 1, 1, 1, -10235.7295, 1796.5748, 36.444977, 5.6975455, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0,
  'Defias Smuggler (Defias Tower, outside north-east)'),
(9950720, 504, 0, 40, 40, 1, 1, 1, -10231.011, 1792.8549, 37.00253, 2.552053, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0,
  'Defias Trapper (Defias Tower, outside north-east)'),
(9950721, 504, 0, 40, 40, 1, 1, 1, -10224.531, 1749.269, 35.590023, 1.5821247, 300, 0, 0, 0, 0, 2, 0, 0, 0, '', 0, 0,
  'Defias Trapper (Defias Tower, patrols the east side)'),
(9950722, 504, 0, 40, 40, 1, 1, 1, -10276.332, 1707.8828, 37.8331, 1.0755961, 300, 0, 0, 0, 0, 2, 0, 0, 0, '', 0, 0,
  'Defias Trapper (Defias Tower, patrols from the south to the door)'),
(9950723, 504, 0, 40, 40, 1, 1, 1, -10229.777, 1801.138, 36.51629, 4.54082, 300, 0, 0, 0, 0, 2, 0, 0, 0, '', 0, 0,
  'Defias Trapper (Defias Tower, patrols the north side)'),
(9950724, 590, 0, 40, 40, 1, 1, 1, -10252.752, 1790.9025, 65.13362, 1.5770023, 300, 0, 0, 0, 0, 2, 0, 0, 0, '', 0, 0,
  'Defias Looter (Defias Tower, patrols the upper floor)'),
(9950725, 590, 0, 40, 40, 1, 1, 1, -10236.828, 1787.493, 73.9261, 4.918933, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0,
  'Defias Looter (Defias Tower, top floor, talking with the Looter beside it)'),
(9950726, 590, 0, 40, 40, 1, 1, 1, -10235.532, 1783.5476, 73.9261, 1.85197, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0,
  'Defias Looter (Defias Tower, top floor, talking with the Looter beside it)'),
(9950727, 590, 0, 40, 40, 1, 1, 1, -10249.35, 1757.1879, 73.92686, 1.0830843, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0,
  'Defias Looter (Defias Tower, top floor)'),
(9950728, 95, 0, 40, 40, 1, 1, 1, -10297.3125, 1795.8308, 37.405975, 5.004017, 300, 0, 0, 0, 0, 2, 0, 0, 0, '', 0, 0,
  'Defias Smuggler (Defias Tower, leads the west patrol)'),
(9950729, 504, 0, 40, 40, 1, 1, 1, -10300.185, 1797.8531, 36.84487, 4.9294147, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', 0, 0,
  'Defias Trapper (Defias Tower, follows the west patrol leader)');

-- The ground-floor crate stack: a second Hellfire Supplies 5 (97493), the stack the top floor already has.
DELETE FROM `gameobject` WHERE `guid` = 9950315;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`,
  `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`,
  `animprogress`, `state`, `ScriptName`, `VerifiedBuild`, `Comment`) VALUES
(9950315, 97493, 0, 40, 40, 1, 1, -10259.612, 1778.4642, 39.45495, 4.5210667, 0, 0, 0.7714134, -0.6363343, 120, 100, 1,
  '', 0, 'Defias Tower ground floor crate stack');

-- Ready stance: emote state 333 (EMOTE_STATE_READY1H). Asleep: stand state 3 (UNIT_STAND_STATE_SLEEP) and
-- Cosmetic - Sleep Zzz Breakable (55701), which moving or attacking removes.
DELETE FROM `creature_addon` WHERE `guid` BETWEEN 9950700 AND 9950729;
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`,
  `auras`) VALUES
(9950700, 0, 0, 0, 1, 333, 0, ''),
(9950701, 0, 0, 0, 1, 333, 0, ''),
(9950704, 0, 0, 0, 1, 333, 0, ''),
(9950705, 0, 0, 0, 1, 333, 0, ''),
(9950708, 0, 0, 3, 1, 0, 0, '55701'),
(9950709, 0, 0, 3, 1, 0, 0, '55701'),
(9950712, 99507120, 0, 0, 1, 0, 0, ''),
(9950713, 0, 0, 3, 1, 0, 0, '55701'),
(9950715, 99507150, 0, 0, 1, 0, 0, ''),
(9950718, 99507180, 0, 0, 1, 0, 0, ''),
(9950721, 99507210, 0, 0, 1, 0, 0, ''),
(9950722, 99507220, 0, 0, 1, 0, 0, ''),
(9950723, 99507230, 0, 0, 1, 0, 0, ''),
(9950724, 99507240, 0, 0, 1, 0, 0, ''),
(9950728, 99507280, 0, 0, 1, 0, 0, '');

-- Every patrol sets smoothTransition, so it walks a curve through its points and stops only where it pauses.
-- Defias Looter 9950712 walks up the stairs and back (points 1-9, then 8-2), pausing 10 s at the bottom and the top.
DELETE FROM `waypoint_data` WHERE `id` = 99507120;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`,
  `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES
(99507120, 1, -10251.7705, 1764.8564, 39.455402, 2.9066293, 0, 10000, 1, 0, 0, 100, 0),
(99507120, 2, -10246.6455, 1766.4941, 41.64909, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507120, 3, -10241.951, 1771.564, 44.077618, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507120, 4, -10241.209, 1773.8546, 44.12184, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507120, 5, -10244.76, 1774.8524, 44.12184, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507120, 6, -10247.76, 1771.9635, 45.736355, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507120, 7, -10250.143, 1770.4824, 47.34718, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507120, 8, -10252.913, 1770.5752, 48.721657, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507120, 9, -10254.624, 1771.2336, 49.645267, 2.6906445, 0, 10000, 1, 0, 0, 100, 0),
(99507120, 10, -10252.913, 1770.5752, 48.721657, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507120, 11, -10250.143, 1770.4824, 47.34718, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507120, 12, -10247.76, 1771.9635, 45.736355, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507120, 13, -10244.76, 1774.8524, 44.12184, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507120, 14, -10241.209, 1773.8546, 44.12184, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507120, 15, -10241.951, 1771.564, 44.077618, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507120, 16, -10246.6455, 1766.4941, 41.64909, NULL, 0, 0, 1, 0, 0, 100, 0);

-- Defias Smuggler 9950715 walks the west side of the tower, from the south up to the sparring Trapper and back
-- (points 1-5, then 4-2), pausing 10 s at each end.
DELETE FROM `waypoint_data` WHERE `id` = 99507150;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`,
  `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES
(99507150, 1, -10286.629, 1710.9095, 37.1944, 1.6325648, 0, 10000, 1, 0, 0, 100, 0),
(99507150, 2, -10286.922, 1721.0743, 36.989643, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507150, 3, -10289.585, 1736.0798, 35.515152, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507150, 4, -10289.203, 1744.3533, 35.36926, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507150, 5, -10282.961, 1770.7916, 36.733063, 0.9217794, 0, 10000, 1, 0, 0, 100, 0),
(99507150, 6, -10289.203, 1744.3533, 35.36926, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507150, 7, -10289.585, 1736.0798, 35.515152, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507150, 8, -10286.922, 1721.0743, 36.989643, NULL, 0, 0, 1, 0, 0, 100, 0);

-- Defias Looter 9950718 walks from the landing down the far stairs to the door and back (points 1-9, then 8-2),
-- pausing 10 s at each end.
DELETE FROM `waypoint_data` WHERE `id` = 99507180;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`,
  `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES
(99507180, 1, -10246.659, 1787.5305, 46.899685, 0.63120437, 0, 10000, 1, 0, 0, 100, 0),
(99507180, 2, -10251.64, 1789.4631, 46.899685, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507180, 3, -10254.837, 1789.3135, 46.899685, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507180, 4, -10257.738, 1788.1884, 45.869625, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507180, 5, -10260.413, 1787.1688, 44.900803, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507180, 6, -10263.123, 1784.2574, 43.450386, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507180, 7, -10264.847, 1780.8987, 42.09762, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507180, 8, -10265.425, 1775.5096, 40.034584, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507180, 9, -10265.071, 1773.9304, 39.45622, 5.233633, 0, 10000, 1, 0, 0, 100, 0),
(99507180, 10, -10265.425, 1775.5096, 40.034584, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507180, 11, -10264.847, 1780.8987, 42.09762, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507180, 12, -10263.123, 1784.2574, 43.450386, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507180, 13, -10260.413, 1787.1688, 44.900803, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507180, 14, -10257.738, 1788.1884, 45.869625, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507180, 15, -10254.837, 1789.3135, 46.899685, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507180, 16, -10251.64, 1789.4631, 46.899685, NULL, 0, 0, 1, 0, 0, 100, 0);

-- Defias Trapper 9950721 walks a loop round the east side of the tower (points 1-9, then back to 1), pausing 5 s at
-- point 6 by the north-east pair and at point 9.
DELETE FROM `waypoint_data` WHERE `id` = 99507210;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`,
  `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES
(99507210, 1, -10224.531, 1749.269, 35.590023, 1.5821247, 0, 0, 1, 0, 0, 100, 0),
(99507210, 2, -10222.865, 1756.8578, 37.40026, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507210, 3, -10220.643, 1766.9663, 39.1926, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507210, 4, -10222.377, 1778.5791, 37.69189, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507210, 5, -10224.508, 1787.7286, 36.598946, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507210, 6, -10229.14, 1796.6556, 36.76823, 2.3007696, 0, 5000, 1, 0, 0, 100, 0),
(99507210, 7, -10220.698, 1782.1445, 36.929005, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507210, 8, -10226.801, 1769.8239, 38.64046, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507210, 9, -10232.198, 1761.0294, 37.719505, 3.938353, 0, 5000, 1, 0, 0, 100, 0);

-- Defias Trapper 9950722 walks from the south up towards the door and back (points 1-5, then 4-2), pausing 5 s at
-- each end; back at point 1 it faces away from the tower. Point 5 stops 6.4 yards from the talking Smuggler so
-- that Smuggler's 5-yard partner check never counts this Trapper.
DELETE FROM `waypoint_data` WHERE `id` = 99507220;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`,
  `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES
(99507220, 1, -10276.332, 1707.8828, 37.8331, 4.217189, 0, 5000, 1, 0, 0, 100, 0),
(99507220, 2, -10271.867, 1715.4265, 37.373215, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507220, 3, -10267.774, 1720.1506, 36.38578, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507220, 4, -10258.595, 1730.6373, 36.840637, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507220, 5, -10252.641, 1741.903, 36.917355, 1.1305745, 0, 5000, 1, 0, 0, 100, 0),
(99507220, 6, -10258.595, 1730.6373, 36.840637, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507220, 7, -10267.774, 1720.1506, 36.38578, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507220, 8, -10271.867, 1715.4265, 37.373215, NULL, 0, 0, 1, 0, 0, 100, 0);

-- Defias Trapper 9950723 walks the north side of the tower from the north-east corner to the west side and back
-- (points 1-7, then 6-2), pausing 10 s at each end. Point 1 is 7.5 yards from the north-east Smuggler, outside
-- that Smuggler's 7-yard partner check.
DELETE FROM `waypoint_data` WHERE `id` = 99507230;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`,
  `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES
(99507230, 1, -10229.777, 1801.138, 36.51629, 4.54082, 0, 10000, 1, 0, 0, 100, 0),
(99507230, 2, -10242.224, 1804.3293, 35.569427, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507230, 3, -10253.042, 1804.0276, 35.573456, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507230, 4, -10261.2705, 1802.3098, 36.131157, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507230, 5, -10268.624, 1797.5652, 36.50637, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507230, 6, -10276.51, 1789.9808, 36.881992, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507230, 7, -10279.744, 1781.8734, 37.422733, 4.318048, 0, 10000, 1, 0, 0, 100, 0),
(99507230, 8, -10276.51, 1789.9808, 36.881992, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507230, 9, -10268.624, 1797.5652, 36.50637, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507230, 10, -10261.2705, 1802.3098, 36.131157, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507230, 11, -10253.042, 1804.0276, 35.573456, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507230, 12, -10242.224, 1804.3293, 35.569427, NULL, 0, 0, 1, 0, 0, 100, 0);

-- Defias Looter 9950724 walks a loop round the upper floor past the sleepers (points 1-11, then back to 1), pausing
-- 3 s at points 1, 6 and 10.
DELETE FROM `waypoint_data` WHERE `id` = 99507240;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`,
  `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES
(99507240, 1, -10252.752, 1790.9025, 65.13362, 1.5770023, 0, 3000, 1, 0, 0, 100, 0),
(99507240, 2, -10246.397, 1788.8953, 65.12641, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507240, 3, -10241.805, 1784.4294, 65.129456, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507240, 4, -10239.747, 1779.2787, 65.12613, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507240, 5, -10240.272, 1773.5605, 65.1262, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507240, 6, -10244.286, 1767.2501, 65.12726, 5.4411817, 0, 3000, 1, 0, 0, 100, 0),
(99507240, 7, -10249.789, 1764.2922, 65.127495, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507240, 8, -10256.61, 1764.1868, 65.1339, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507240, 9, -10263.328, 1768.6844, 65.12784, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507240, 10, -10266.55, 1776.2181, 65.130455, 3.1046271, 0, 3000, 1, 0, 0, 100, 0),
(99507240, 11, -10263.073, 1789.131, 65.14363, NULL, 0, 0, 1, 0, 0, 100, 0);

-- Defias Smuggler 9950728 leads a two-man patrol down the west side and back (points 1-7, then 6-2), pausing 5 s at
-- each end. Defias Trapper 9950729 follows 3.5 yards behind and to its right (218 degrees from its facing); groupAI
-- 515 makes the Trapper follow and each defend the other.
DELETE FROM `waypoint_data` WHERE `id` = 99507280;
INSERT INTO `waypoint_data` (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `velocity`,
  `delay`, `smoothTransition`, `move_type`, `action`, `action_chance`, `wpguid`) VALUES
(99507280, 1, -10297.3125, 1795.8308, 37.405975, 5.004017, 0, 5000, 1, 0, 0, 100, 0),
(99507280, 2, -10296.021, 1788.2921, 38.278236, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507280, 3, -10297.335, 1775.87, 36.83533, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507280, 4, -10300.5205, 1766.7539, 35.61784, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507280, 5, -10305.0205, 1754.7203, 35.38859, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507280, 6, -10309.271, 1743.352, 35.381298, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507280, 7, -10301.53, 1737.3568, 35.443832, 5.6739817, 0, 5000, 1, 0, 0, 100, 0),
(99507280, 8, -10309.271, 1743.352, 35.381298, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507280, 9, -10305.0205, 1754.7203, 35.38859, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507280, 10, -10300.5205, 1766.7539, 35.61784, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507280, 11, -10297.335, 1775.87, 36.83533, NULL, 0, 0, 1, 0, 0, 100, 0),
(99507280, 12, -10296.021, 1788.2921, 38.278236, NULL, 0, 0, 1, 0, 0, 100, 0);
DELETE FROM `creature_formations` WHERE `memberGUID` IN (9950728, 9950729);
INSERT INTO `creature_formations` (`leaderGUID`, `memberGUID`, `dist`, `angle`, `groupAI`, `point_1`, `point_2`) VALUES
(9950728, 9950728, 0, 0, 515, 0, 0),
(9950728, 9950729, 3.51, 218.1, 515, 0, 0);

-- Three Defias Looter grumbles about Lenore, from Ascension footage. Group 1 is used only by the tower Looters'
-- own scripts, which say one of the three at random on 10% of pulls.
DELETE FROM `creature_text` WHERE `CreatureID` = 590 AND `GroupID` = 1;
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`,
  `Duration`, `Sound`, `BroadcastTextId`, `TextRange`, `comment`) VALUES
(590, 1, 0,
  'Ugh. I swear, Lenore counts every copper in this blasted tower. We risk our necks nicking this loot, and what do '
  'we get? A handful of silver and a scrap of leather every week.', 12, 7, 100, 0, 0, 0, 0, 0,
  'Defias Looter - Defias Tower - Aggro'),
(590, 1, 1,
  'Aye, and the way she hoards those weapons like they''re priceless relics. ''For the Brotherhood''s protection,'' '
  'she says. Protection for her, I reckon.', 12, 7, 100, 0, 0, 0, 0, 0, 'Defias Looter - Defias Tower - Aggro'),
(590, 1, 2,
  '''No touching the Sentinel Hill gear! No admiring the Stormwind steel!'' Blast it, I''d trade my left boot for a '
  'proper sharpening stone...', 12, 7, 100, 0, 0, 0, 0, 0, 'Defias Looter - Defias Tower - Aggro');

-- Per-spawn SmartAI replaces the template script, so each copies its template's events (ids 0-3) and adds its own.
DELETE FROM `smart_scripts` WHERE `entryorguid` = -9950702 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
  `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
  `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
  `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`,
  `target_y`, `target_z`, `target_o`, `comment`) VALUES
(-9950702, 0, 0, 0, 4, 0, 15, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Smuggler - On Aggro - Say Line 0'),
(-9950702, 0, 1, 0, 0, 0, 100, 0, 0, 0, 3500, 4100, 0, 0, 11, 10277, 64, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Smuggler - In Combat CMC - Cast ''Throw'''),
(-9950702, 0, 2, 0, 67, 0, 100, 0, 1300, 7300, 1300, 7300, 0, 5, 11, 53, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Smuggler - Behind Target - Cast ''Backstab'''),
(-9950702, 0, 3, 0, 2, 0, 100, 1, 0, 15, 0, 0, 0, 0, 25, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Smuggler - Between 0-15% Health - Flee For Assist (No Repeat)'),
(-9950702, 0, 4, 0, 1, 0, 100, 0, 4000, 6000, 4000, 6000, 0, 0, 10, 1, 5, 6, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Smuggler - Out of Combat - Play Random Emote (Talk, Exclamation, Question)');
DELETE FROM `smart_scripts` WHERE `entryorguid` = -9950703 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
  `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
  `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
  `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`,
  `target_y`, `target_z`, `target_o`, `comment`) VALUES
(-9950703, 0, 0, 0, 4, 0, 5, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Trapper - On Aggro - Say Line 0 (No Repeat)'),
(-9950703, 0, 1, 0, 0, 0, 100, 0, 2300, 4700, 2400, 7300, 0, 0, 11, 2589, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Trapper - In Combat - Cast ''Backstab'' (No Repeat)'),
(-9950703, 0, 2, 0, 0, 0, 100, 0, 6500, 14200, 20500, 31100, 0, 0, 11, 12024, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Trapper - In Combat - Cast ''Net'' (No Repeat)'),
(-9950703, 0, 3, 0, 2, 0, 100, 1, 0, 15, 0, 0, 0, 0, 25, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Trapper - Between 0-15% Health - Flee For Assist (No Repeat)'),
(-9950703, 0, 4, 0, 1, 0, 100, 0, 4000, 6000, 4000, 6000, 0, 0, 10, 1, 5, 6, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Trapper - Out of Combat - Play Random Emote (Talk, Exclamation, Question)');
DELETE FROM `smart_scripts` WHERE `entryorguid` = -9950704 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
  `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
  `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
  `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`,
  `target_y`, `target_z`, `target_o`, `comment`) VALUES
(-9950704, 0, 0, 0, 4, 0, 15, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Smuggler - On Aggro - Say Line 0'),
(-9950704, 0, 1, 0, 0, 0, 100, 0, 0, 0, 3500, 4100, 0, 0, 11, 10277, 64, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Smuggler - In Combat CMC - Cast ''Throw'''),
(-9950704, 0, 2, 0, 67, 0, 100, 0, 1300, 7300, 1300, 7300, 0, 5, 11, 53, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Smuggler - Behind Target - Cast ''Backstab'''),
(-9950704, 0, 3, 0, 2, 0, 100, 1, 0, 15, 0, 0, 0, 0, 25, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Smuggler - Between 0-15% Health - Flee For Assist (No Repeat)'),
(-9950704, 0, 4, 0, 1, 0, 100, 0, 4000, 6000, 4000, 6000, 0, 0, 10, 36, 440, 441, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Smuggler - Out of Combat - Play Random Emote (Attack, Dodge, Parry)');
DELETE FROM `smart_scripts` WHERE `entryorguid` = -9950705 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
  `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
  `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
  `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`,
  `target_y`, `target_z`, `target_o`, `comment`) VALUES
(-9950705, 0, 0, 0, 4, 0, 5, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Trapper - On Aggro - Say Line 0 (No Repeat)'),
(-9950705, 0, 1, 0, 0, 0, 100, 0, 2300, 4700, 2400, 7300, 0, 0, 11, 2589, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Trapper - In Combat - Cast ''Backstab'' (No Repeat)'),
(-9950705, 0, 2, 0, 0, 0, 100, 0, 6500, 14200, 20500, 31100, 0, 0, 11, 12024, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Trapper - In Combat - Cast ''Net'' (No Repeat)'),
(-9950705, 0, 3, 0, 2, 0, 100, 1, 0, 15, 0, 0, 0, 0, 25, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Trapper - Between 0-15% Health - Flee For Assist (No Repeat)'),
(-9950705, 0, 4, 0, 1, 0, 100, 0, 4000, 6000, 4000, 6000, 0, 0, 10, 36, 440, 441, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Trapper - Out of Combat - Play Random Emote (Attack, Dodge, Parry)');
DELETE FROM `smart_scripts` WHERE `entryorguid` = -9950706 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
  `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
  `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
  `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`,
  `target_y`, `target_z`, `target_o`, `comment`) VALUES
(-9950706, 0, 0, 0, 4, 0, 15, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - On Aggro - Say Line 0 (No Repeat)'),
(-9950706, 0, 1, 0, 0, 0, 100, 0, 3000, 4500, 2000, 9000, 0, 0, 11, 7159, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - In Combat - Cast ''Backstab'' (No Repeat)'),
(-9950706, 0, 2, 0, 0, 0, 80, 0, 2000, 6000, 38100, 48200, 0, 0, 11, 6713, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - In Combat - Cast ''Disarm'' (No Repeat)'),
(-9950706, 0, 3, 0, 2, 0, 100, 1, 0, 15, 0, 0, 0, 0, 25, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - Between 0-15% Health - Flee For Assist (No Repeat)'),
(-9950706, 0, 4, 0, 4, 0, 10, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - On Aggro - Say Line 1 (No Repeat)');

-- The talking pairs (Smuggler and Trapper outside, Trapper and Looter on the ground floor) talk only while the
-- other one is alive within 5 yards (7 for the north-east pair, who stand 6 yards apart).
DELETE FROM `smart_scripts` WHERE `entryorguid` = -9950716 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
  `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
  `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
  `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`,
  `target_y`, `target_z`, `target_o`, `comment`) VALUES
(-9950716, 0, 0, 0, 4, 0, 5, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Trapper - On Aggro - Say Line 0 (No Repeat)'),
(-9950716, 0, 1, 0, 0, 0, 100, 0, 2300, 4700, 2400, 7300, 0, 0, 11, 2589, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Trapper - In Combat - Cast ''Backstab'' (No Repeat)'),
(-9950716, 0, 2, 0, 0, 0, 100, 0, 6500, 14200, 20500, 31100, 0, 0, 11, 12024, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Trapper - In Combat - Cast ''Net'' (No Repeat)'),
(-9950716, 0, 3, 0, 2, 0, 100, 1, 0, 15, 0, 0, 0, 0, 25, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Trapper - Between 0-15% Health - Flee For Assist (No Repeat)'),
(-9950716, 0, 4, 0, 1, 0, 100, 0, 4000, 6000, 4000, 6000, 0, 0, 10, 1, 5, 6, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Trapper - Out of Combat - Play Random Emote (Talk, Exclamation, Question)');
DELETE FROM `smart_scripts` WHERE `entryorguid` = -9950717 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
  `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
  `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
  `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`,
  `target_y`, `target_z`, `target_o`, `comment`) VALUES
(-9950717, 0, 0, 0, 4, 0, 15, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - On Aggro - Say Line 0 (No Repeat)'),
(-9950717, 0, 1, 0, 0, 0, 100, 0, 3000, 4500, 2000, 9000, 0, 0, 11, 7159, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - In Combat - Cast ''Backstab'' (No Repeat)'),
(-9950717, 0, 2, 0, 0, 0, 80, 0, 2000, 6000, 38100, 48200, 0, 0, 11, 6713, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - In Combat - Cast ''Disarm'' (No Repeat)'),
(-9950717, 0, 3, 0, 2, 0, 100, 1, 0, 15, 0, 0, 0, 0, 25, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - Between 0-15% Health - Flee For Assist (No Repeat)'),
(-9950717, 0, 4, 0, 1, 0, 100, 0, 4000, 6000, 4000, 6000, 0, 0, 10, 1, 5, 6, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - Out of Combat - Play Random Emote (Talk, Exclamation, Question)'),
(-9950717, 0, 5, 0, 4, 0, 10, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - On Aggro - Say Line 1 (No Repeat)');
DELETE FROM `smart_scripts` WHERE `entryorguid` = -9950719 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
  `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
  `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
  `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`,
  `target_y`, `target_z`, `target_o`, `comment`) VALUES
(-9950719, 0, 0, 0, 4, 0, 15, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Smuggler - On Aggro - Say Line 0'),
(-9950719, 0, 1, 0, 0, 0, 100, 0, 0, 0, 3500, 4100, 0, 0, 11, 10277, 64, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Smuggler - In Combat CMC - Cast ''Throw'''),
(-9950719, 0, 2, 0, 67, 0, 100, 0, 1300, 7300, 1300, 7300, 0, 5, 11, 53, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Smuggler - Behind Target - Cast ''Backstab'''),
(-9950719, 0, 3, 0, 2, 0, 100, 1, 0, 15, 0, 0, 0, 0, 25, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Smuggler - Between 0-15% Health - Flee For Assist (No Repeat)'),
(-9950719, 0, 4, 0, 1, 0, 100, 0, 4000, 6000, 4000, 6000, 0, 0, 10, 1, 5, 6, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Smuggler - Out of Combat - Play Random Emote (Talk, Exclamation, Question)');
DELETE FROM `smart_scripts` WHERE `entryorguid` = -9950720 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
  `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
  `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
  `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`,
  `target_y`, `target_z`, `target_o`, `comment`) VALUES
(-9950720, 0, 0, 0, 4, 0, 5, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Trapper - On Aggro - Say Line 0 (No Repeat)'),
(-9950720, 0, 1, 0, 0, 0, 100, 0, 2300, 4700, 2400, 7300, 0, 0, 11, 2589, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Trapper - In Combat - Cast ''Backstab'' (No Repeat)'),
(-9950720, 0, 2, 0, 0, 0, 100, 0, 6500, 14200, 20500, 31100, 0, 0, 11, 12024, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Trapper - In Combat - Cast ''Net'' (No Repeat)'),
(-9950720, 0, 3, 0, 2, 0, 100, 1, 0, 15, 0, 0, 0, 0, 25, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Trapper - Between 0-15% Health - Flee For Assist (No Repeat)'),
(-9950720, 0, 4, 0, 1, 0, 100, 0, 4000, 6000, 4000, 6000, 0, 0, 10, 1, 5, 6, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Trapper - Out of Combat - Play Random Emote (Talk, Exclamation, Question)');
-- The top-floor Looters are the same creature, so a nearby-creature check would find each Looter itself. Instead
-- each one's out-of-combat timer signals its partner by spawn guid, and the partner gestures only while alive.
DELETE FROM `smart_scripts` WHERE `entryorguid` = -9950725 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
  `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
  `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
  `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`,
  `target_y`, `target_z`, `target_o`, `comment`) VALUES
(-9950725, 0, 0, 0, 4, 0, 15, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - On Aggro - Say Line 0 (No Repeat)'),
(-9950725, 0, 1, 0, 0, 0, 100, 0, 3000, 4500, 2000, 9000, 0, 0, 11, 7159, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - In Combat - Cast ''Backstab'' (No Repeat)'),
(-9950725, 0, 2, 0, 0, 0, 80, 0, 2000, 6000, 38100, 48200, 0, 0, 11, 6713, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - In Combat - Cast ''Disarm'' (No Repeat)'),
(-9950725, 0, 3, 0, 2, 0, 100, 1, 0, 15, 0, 0, 0, 0, 25, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - Between 0-15% Health - Flee For Assist (No Repeat)'),
(-9950725, 0, 4, 0, 1, 0, 100, 0, 4000, 6000, 4000, 6000, 0, 0, 45, 1, 1, 0, 0, 0, 0, 10, 9950726, 590, 0, 0, 0, 0, 0,
  0, 'Defias Looter - Out of Combat - Set Data 1 1 on the Looter beside it'),
(-9950725, 0, 5, 0, 38, 0, 100, 0, 1, 1, 0, 0, 0, 0, 10, 1, 5, 6, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - On Data Set 1 1 - Play Random Emote (Talk, Exclamation, Question)'),
(-9950725, 0, 6, 0, 4, 0, 10, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - On Aggro - Say Line 1 (No Repeat)');
DELETE FROM `smart_scripts` WHERE `entryorguid` = -9950726 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
  `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
  `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
  `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`,
  `target_y`, `target_z`, `target_o`, `comment`) VALUES
(-9950726, 0, 0, 0, 4, 0, 15, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - On Aggro - Say Line 0 (No Repeat)'),
(-9950726, 0, 1, 0, 0, 0, 100, 0, 3000, 4500, 2000, 9000, 0, 0, 11, 7159, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - In Combat - Cast ''Backstab'' (No Repeat)'),
(-9950726, 0, 2, 0, 0, 0, 80, 0, 2000, 6000, 38100, 48200, 0, 0, 11, 6713, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - In Combat - Cast ''Disarm'' (No Repeat)'),
(-9950726, 0, 3, 0, 2, 0, 100, 1, 0, 15, 0, 0, 0, 0, 25, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - Between 0-15% Health - Flee For Assist (No Repeat)'),
(-9950726, 0, 4, 0, 1, 0, 100, 0, 4000, 6000, 4000, 6000, 0, 0, 45, 1, 1, 0, 0, 0, 0, 10, 9950725, 590, 0, 0, 0, 0, 0,
  0, 'Defias Looter - Out of Combat - Set Data 1 1 on the Looter beside it'),
(-9950726, 0, 5, 0, 38, 0, 100, 0, 1, 1, 0, 0, 0, 0, 10, 1, 5, 6, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - On Data Set 1 1 - Play Random Emote (Talk, Exclamation, Question)'),
(-9950726, 0, 6, 0, 4, 0, 10, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - On Aggro - Say Line 1 (No Repeat)');
-- Every other tower Looter gets its own script only for that 10% grumble on aggro; ids 0-3 copy the template.
DELETE FROM `smart_scripts` WHERE `entryorguid` = -9950708 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
  `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
  `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
  `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`,
  `target_y`, `target_z`, `target_o`, `comment`) VALUES
(-9950708, 0, 0, 0, 4, 0, 15, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - On Aggro - Say Line 0 (No Repeat)'),
(-9950708, 0, 1, 0, 0, 0, 100, 0, 3000, 4500, 2000, 9000, 0, 0, 11, 7159, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - In Combat - Cast ''Backstab'' (No Repeat)'),
(-9950708, 0, 2, 0, 0, 0, 80, 0, 2000, 6000, 38100, 48200, 0, 0, 11, 6713, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - In Combat - Cast ''Disarm'' (No Repeat)'),
(-9950708, 0, 3, 0, 2, 0, 100, 1, 0, 15, 0, 0, 0, 0, 25, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - Between 0-15% Health - Flee For Assist (No Repeat)'),
(-9950708, 0, 4, 0, 4, 0, 10, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - On Aggro - Say Line 1 (No Repeat)');
DELETE FROM `smart_scripts` WHERE `entryorguid` = -9950709 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
  `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
  `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
  `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`,
  `target_y`, `target_z`, `target_o`, `comment`) VALUES
(-9950709, 0, 0, 0, 4, 0, 15, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - On Aggro - Say Line 0 (No Repeat)'),
(-9950709, 0, 1, 0, 0, 0, 100, 0, 3000, 4500, 2000, 9000, 0, 0, 11, 7159, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - In Combat - Cast ''Backstab'' (No Repeat)'),
(-9950709, 0, 2, 0, 0, 0, 80, 0, 2000, 6000, 38100, 48200, 0, 0, 11, 6713, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - In Combat - Cast ''Disarm'' (No Repeat)'),
(-9950709, 0, 3, 0, 2, 0, 100, 1, 0, 15, 0, 0, 0, 0, 25, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - Between 0-15% Health - Flee For Assist (No Repeat)'),
(-9950709, 0, 4, 0, 4, 0, 10, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - On Aggro - Say Line 1 (No Repeat)');
DELETE FROM `smart_scripts` WHERE `entryorguid` = -9950710 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
  `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
  `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
  `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`,
  `target_y`, `target_z`, `target_o`, `comment`) VALUES
(-9950710, 0, 0, 0, 4, 0, 15, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - On Aggro - Say Line 0 (No Repeat)'),
(-9950710, 0, 1, 0, 0, 0, 100, 0, 3000, 4500, 2000, 9000, 0, 0, 11, 7159, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - In Combat - Cast ''Backstab'' (No Repeat)'),
(-9950710, 0, 2, 0, 0, 0, 80, 0, 2000, 6000, 38100, 48200, 0, 0, 11, 6713, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - In Combat - Cast ''Disarm'' (No Repeat)'),
(-9950710, 0, 3, 0, 2, 0, 100, 1, 0, 15, 0, 0, 0, 0, 25, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - Between 0-15% Health - Flee For Assist (No Repeat)'),
(-9950710, 0, 4, 0, 4, 0, 10, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - On Aggro - Say Line 1 (No Repeat)');
DELETE FROM `smart_scripts` WHERE `entryorguid` = -9950711 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
  `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
  `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
  `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`,
  `target_y`, `target_z`, `target_o`, `comment`) VALUES
(-9950711, 0, 0, 0, 4, 0, 15, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - On Aggro - Say Line 0 (No Repeat)'),
(-9950711, 0, 1, 0, 0, 0, 100, 0, 3000, 4500, 2000, 9000, 0, 0, 11, 7159, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - In Combat - Cast ''Backstab'' (No Repeat)'),
(-9950711, 0, 2, 0, 0, 0, 80, 0, 2000, 6000, 38100, 48200, 0, 0, 11, 6713, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - In Combat - Cast ''Disarm'' (No Repeat)'),
(-9950711, 0, 3, 0, 2, 0, 100, 1, 0, 15, 0, 0, 0, 0, 25, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - Between 0-15% Health - Flee For Assist (No Repeat)'),
(-9950711, 0, 4, 0, 4, 0, 10, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - On Aggro - Say Line 1 (No Repeat)');
DELETE FROM `smart_scripts` WHERE `entryorguid` = -9950712 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
  `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
  `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
  `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`,
  `target_y`, `target_z`, `target_o`, `comment`) VALUES
(-9950712, 0, 0, 0, 4, 0, 15, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - On Aggro - Say Line 0 (No Repeat)'),
(-9950712, 0, 1, 0, 0, 0, 100, 0, 3000, 4500, 2000, 9000, 0, 0, 11, 7159, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - In Combat - Cast ''Backstab'' (No Repeat)'),
(-9950712, 0, 2, 0, 0, 0, 80, 0, 2000, 6000, 38100, 48200, 0, 0, 11, 6713, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - In Combat - Cast ''Disarm'' (No Repeat)'),
(-9950712, 0, 3, 0, 2, 0, 100, 1, 0, 15, 0, 0, 0, 0, 25, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - Between 0-15% Health - Flee For Assist (No Repeat)'),
(-9950712, 0, 4, 0, 4, 0, 10, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - On Aggro - Say Line 1 (No Repeat)');
DELETE FROM `smart_scripts` WHERE `entryorguid` = -9950713 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
  `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
  `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
  `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`,
  `target_y`, `target_z`, `target_o`, `comment`) VALUES
(-9950713, 0, 0, 0, 4, 0, 15, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - On Aggro - Say Line 0 (No Repeat)'),
(-9950713, 0, 1, 0, 0, 0, 100, 0, 3000, 4500, 2000, 9000, 0, 0, 11, 7159, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - In Combat - Cast ''Backstab'' (No Repeat)'),
(-9950713, 0, 2, 0, 0, 0, 80, 0, 2000, 6000, 38100, 48200, 0, 0, 11, 6713, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - In Combat - Cast ''Disarm'' (No Repeat)'),
(-9950713, 0, 3, 0, 2, 0, 100, 1, 0, 15, 0, 0, 0, 0, 25, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - Between 0-15% Health - Flee For Assist (No Repeat)'),
(-9950713, 0, 4, 0, 4, 0, 10, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - On Aggro - Say Line 1 (No Repeat)');
DELETE FROM `smart_scripts` WHERE `entryorguid` = -9950714 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
  `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
  `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
  `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`,
  `target_y`, `target_z`, `target_o`, `comment`) VALUES
(-9950714, 0, 0, 0, 4, 0, 15, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - On Aggro - Say Line 0 (No Repeat)'),
(-9950714, 0, 1, 0, 0, 0, 100, 0, 3000, 4500, 2000, 9000, 0, 0, 11, 7159, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - In Combat - Cast ''Backstab'' (No Repeat)'),
(-9950714, 0, 2, 0, 0, 0, 80, 0, 2000, 6000, 38100, 48200, 0, 0, 11, 6713, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - In Combat - Cast ''Disarm'' (No Repeat)'),
(-9950714, 0, 3, 0, 2, 0, 100, 1, 0, 15, 0, 0, 0, 0, 25, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - Between 0-15% Health - Flee For Assist (No Repeat)'),
(-9950714, 0, 4, 0, 4, 0, 10, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - On Aggro - Say Line 1 (No Repeat)');
DELETE FROM `smart_scripts` WHERE `entryorguid` = -9950718 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
  `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
  `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
  `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`,
  `target_y`, `target_z`, `target_o`, `comment`) VALUES
(-9950718, 0, 0, 0, 4, 0, 15, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - On Aggro - Say Line 0 (No Repeat)'),
(-9950718, 0, 1, 0, 0, 0, 100, 0, 3000, 4500, 2000, 9000, 0, 0, 11, 7159, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - In Combat - Cast ''Backstab'' (No Repeat)'),
(-9950718, 0, 2, 0, 0, 0, 80, 0, 2000, 6000, 38100, 48200, 0, 0, 11, 6713, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - In Combat - Cast ''Disarm'' (No Repeat)'),
(-9950718, 0, 3, 0, 2, 0, 100, 1, 0, 15, 0, 0, 0, 0, 25, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - Between 0-15% Health - Flee For Assist (No Repeat)'),
(-9950718, 0, 4, 0, 4, 0, 10, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - On Aggro - Say Line 1 (No Repeat)');
DELETE FROM `smart_scripts` WHERE `entryorguid` = -9950724 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
  `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
  `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
  `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`,
  `target_y`, `target_z`, `target_o`, `comment`) VALUES
(-9950724, 0, 0, 0, 4, 0, 15, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - On Aggro - Say Line 0 (No Repeat)'),
(-9950724, 0, 1, 0, 0, 0, 100, 0, 3000, 4500, 2000, 9000, 0, 0, 11, 7159, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - In Combat - Cast ''Backstab'' (No Repeat)'),
(-9950724, 0, 2, 0, 0, 0, 80, 0, 2000, 6000, 38100, 48200, 0, 0, 11, 6713, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - In Combat - Cast ''Disarm'' (No Repeat)'),
(-9950724, 0, 3, 0, 2, 0, 100, 1, 0, 15, 0, 0, 0, 0, 25, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - Between 0-15% Health - Flee For Assist (No Repeat)'),
(-9950724, 0, 4, 0, 4, 0, 10, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - On Aggro - Say Line 1 (No Repeat)');
DELETE FROM `smart_scripts` WHERE `entryorguid` = -9950727 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
  `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
  `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`,
  `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`,
  `target_y`, `target_z`, `target_o`, `comment`) VALUES
(-9950727, 0, 0, 0, 4, 0, 15, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - On Aggro - Say Line 0 (No Repeat)'),
(-9950727, 0, 1, 0, 0, 0, 100, 0, 3000, 4500, 2000, 9000, 0, 0, 11, 7159, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - In Combat - Cast ''Backstab'' (No Repeat)'),
(-9950727, 0, 2, 0, 0, 0, 80, 0, 2000, 6000, 38100, 48200, 0, 0, 11, 6713, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - In Combat - Cast ''Disarm'' (No Repeat)'),
(-9950727, 0, 3, 0, 2, 0, 100, 1, 0, 15, 0, 0, 0, 0, 25, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - Between 0-15% Health - Flee For Assist (No Repeat)'),
(-9950727, 0, 4, 0, 4, 0, 10, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
  'Defias Looter - On Aggro - Say Line 1 (No Repeat)');
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22
  AND `SourceEntry` IN (-9950702, -9950703, -9950716, -9950717, -9950719, -9950720, -9950725, -9950726)
  AND `SourceId` = 0;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
  `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
  `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(22, 5, -9950702, 0, 0, 29, 1, 504, 5, 0, 0, 0, 0, '',
  'Defias Tower Smuggler talks only while a living Defias Trapper is within 5 yards'),
(22, 5, -9950703, 0, 0, 29, 1, 95, 5, 0, 0, 0, 0, '',
  'Defias Tower Trapper talks only while a living Defias Smuggler is within 5 yards'),
(22, 5, -9950716, 0, 0, 29, 1, 590, 5, 0, 0, 0, 0, '',
  'Defias Tower Trapper talks only while a living Defias Looter is within 5 yards'),
(22, 5, -9950717, 0, 0, 29, 1, 504, 5, 0, 0, 0, 0, '',
  'Defias Tower Looter talks only while a living Defias Trapper is within 5 yards'),
(22, 5, -9950719, 0, 0, 29, 1, 504, 7, 0, 0, 0, 0, '',
  'Defias Tower Smuggler talks only while a living Defias Trapper is within 7 yards'),
(22, 5, -9950720, 0, 0, 29, 1, 95, 7, 0, 0, 0, 0, '',
  'Defias Tower Trapper talks only while a living Defias Smuggler is within 7 yards'),
(22, 6, -9950725, 0, 0, 36, 1, 0, 0, 0, 0, 0, 0, '', 'Defias Tower top-floor Looter gestures only while alive'),
(22, 6, -9950726, 0, 0, 36, 1, 0, 0, 0, 0, 0, 0, '', 'Defias Tower top-floor Looter gestures only while alive');
