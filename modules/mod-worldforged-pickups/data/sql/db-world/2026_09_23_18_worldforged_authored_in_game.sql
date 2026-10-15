-- ----------------------------------------------------------------------------
-- Worldforged pickups: the placements and rotations authored in game
-- ----------------------------------------------------------------------------
-- Every row below is a placement the realm authored by hand in the map editor (Noggit,
-- changed in the client's own data): the editor writes one changeset per save, and this
-- file is those changesets read in the order they were written, the last write to a row
-- winning.  Nothing here is inferred: position_x/y/z and the rotation quaternion are
-- what the editor emitted, down to the digit.
--
-- 39 rows of this module were moved and/or turned, and 5 placements were
-- added.  The orientation column is written as the yaw the quaternion represents, which
-- is what the model is drawn with; the editor's own orientation column disagreed with its
-- quaternion on two of the rows, and both are noted where they occur.
--
-- Rows the changesets touch that are not this module's are left exactly as they are, and
-- listed at the end of this header, so nothing that belongs to the world itself is swept
-- into a worldforged migration.
--
-- Idempotent: every statement is an UPDATE keyed on guid, or a REPLACE on a guid this file
-- allocates.  Apply to acore_world, then let the worldserver load the rows.
-- ----------------------------------------------------------------------------

START TRANSACTION;

-- Alliance Gem of Fortitude (90217): Echo Ridge Mine - Worldforged Alliance Gem of Fortitude | realm map Elwynn Forest | in-game placement 2026-09-23
--   authored in game (spawns_20260923_222254.sql): moved 0.00 yd, height +0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -8679.244141, `position_y` = -186.195312, `position_z` = 92.889923,
  `orientation` = 1.551240, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.700159000, `rotation3` = 0.713987000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940032;

-- Apprentice Staff (95670): Northshire Valley - Worldforged Apprentice Staff | realm map Elwynn Forest | in-game placement 2026-09-23
--   authored in game (spawns_20260923_215413.sql): moved 0.00 yd, height -0.00 yd, turned 0.000 rad (0.0 deg)
--   the changeset's own orientation column said 0.2967 while its quaternion represents 0.4078; the quaternion is written, and the column follows it
UPDATE `gameobject` SET
  `position_x` = -9123.886719, `position_y` = -224.306641, `position_z` = 75.113167,
  `orientation` = 0.407834, `rotation0` = 0.367570579, `rotation1` = -0.527556544,
  `rotation2` = 0.155096523, `rotation3` = 0.750014020,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940063;

-- Appropriated Goods (95662): Stone Cairn Lake - Worldforged Breastplate of the Current | realm map Elwynn Forest | in-game placement 2026-09-23
--   authored in game (spawns_20260923_230104.sql): moved 99.55 yd, height +145.69 yd, turned 0.063 rad (3.6 deg)
UPDATE `gameobject` SET
  `position_x` = -8908.425781, `position_y` = -708.525391, `position_z` = 70.826408,
  `orientation` = 0.308228, `rotation0` = -0.021738895, `rotation1` = 0.049866488,
  `rotation2` = 0.153277257, `rotation3` = 0.986684770,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940184;

-- Ball of Yarn (254258): Stone Cairn Lake - Worldforged Ball of Yarn | realm map Elwynn Forest | in-game placement 2026-09-23
--   authored in game (spawns_20260923_231041.sql): moved 0.01 yd, height +0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -8795.792969, `position_y` = -1057.894531, `position_z` = 73.968636,
  `orientation` = 5.687091, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.293654000, `rotation3` = -0.955912000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940103;

-- Billy Bag (1345009): The Maclure Vineyards - Worldforged Billy Bag | realm map Elwynn Forest | in-game placement 2026-09-23
--   authored in game (spawns_20260923_230834.sql): moved 0.00 yd, height -0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9908.824219, `position_y` = 25.525391, `position_z` = 31.802565,
  `orientation` = 1.854100, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.799853000, `rotation3` = 0.600196000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940120;

-- Cherry Pie prop (90635): Northshire Valley - Cherry Pie prop - the visible pie every other starter-zone pie stands next to  | in-game placement 2026-09-23
--   authored in game (spawns_20260923_214906.sql): moved 0.00 yd, height +0.00 yd, turned 0.000 rad (0.0 deg)
--   the changeset's own orientation column said 6.2308 while its quaternion represents 0.1087; the quaternion is written, and the column follows it
UPDATE `gameobject` SET
  `position_x` = -8912.210938, `position_y` = -103.546875, `position_z` = 82.917717,
  `orientation` = 0.108748, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.054347420, `rotation3` = 0.998522087,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6960002;

-- Confiscated Crossbow (95691): Forest's Edge - Worldforged Poacher's Crossbow | realm map Elwynn Forest | in-game placement 2026-09-23
--   authored in game (spawns_20260923_231831.sql): moved 0.00 yd, height -0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9788.978516, `position_y` = 707.420898, `position_z` = 33.891888,
  `orientation` = 2.604224, `rotation0` = -0.426499547, `rotation1` = 0.245516209,
  `rotation2` = 0.839294802, `rotation3` = 0.231093410,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940903;

-- Deepmoss Fang (1345036): Jasperlode Mine - Worldforged Deepmoss Fang | realm map Elwynn Forest | in-game placement 2026-09-23
--   authored in game (spawns_20260923_231646.sql): moved 0.00 yd, height +0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9174.683594, `position_y` = -597.455078, `position_z` = 66.520905,
  `orientation` = 1.772518, `rotation0` = 0.000000047, `rotation1` = -0.000000077,
  `rotation2` = -0.774711678, `rotation3` = -0.632314649,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940333;

-- Defias Cowl (95618): Crystal Lake - Worldforged Defias Cowl | realm map Elwynn Forest | in-game placement 2026-09-23
--   authored in game (spawns_20260923_223411.sql): moved 0.00 yd, height +0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9304.263672, `position_y` = -289.003906, `position_z` = 71.594429,
  `orientation` = 0.663921, `rotation0` = -0.205280236, `rotation1` = -0.595503984,
  `rotation2` = 0.253118422, `rotation3` = 0.734279303,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940336;

-- Defias Special Bucket (90216): Northshire Vineyards - Worldforged Defias Special Bucket | realm map Elwynn Forest | in-game placement 2026-09-23
--   authored in game (spawns_20260923_215744.sql): moved 0.00 yd, height -0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9142.851562, `position_y` = -288.968750, `position_z` = 72.158798,
  `orientation` = 2.445251, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.939998000, `rotation3` = 0.341179000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940345;

-- Disturbed Dirt (520065): Northshire Valley - Worldforged Old Gardening Gloves | realm map Northshire Valley | in-game placement 2026-09-23
--   authored in game (spawns_20260923_222926.sql): moved 0.00 yd, height +0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -8820.324219, `position_y` = -325.287109, `position_z` = 70.549904,
  `orientation` = 1.097270, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.521523000, `rotation3` = 0.853237000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940832;

-- Disturbed Dirt (518303): Northshire Valley - Worldforged Disturbed Dirt | realm map Elwynn Forest | in-game placement 2026-09-23
--   authored in game (spawns_20260923_230717.sql): moved 0.00 yd, height -0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -8768.689453, `position_y` = -321.371094, `position_z` = 70.999962,
  `orientation` = 1.239145, `rotation0` = -0.049921946, `rotation1` = -0.114983427,
  `rotation2` = 0.576106739, `rotation3` = 0.807705167,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940368;

-- Dryad's Bow (97104): Elwynn Forest - Worldforged Windsong Shortbow | realm map Elwynn Forest
--   authored in game (spawns_20260923_232908.sql): moved 6.40 yd, height +1.83 yd, turned 0.398 rad (22.8 deg)
UPDATE `gameobject` SET
  `position_x` = -9651.167969, `position_y` = 500.335938, `position_z` = 40.465256,
  `orientation` = 5.885537, `rotation0` = -0.212998000, `rotation1` = 0.704788401,
  `rotation2` = -0.133656991, `rotation3` = 0.663355840,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6941344;

-- Embedded Axe (95695): Eastvale Logging Camp - Worldforged Heavy Logsplitter | realm map Elwynn Forest | in-game placement 2026-09-23
--   authored in game (spawns_20260923_225150.sql): moved 0.01 yd, height -0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9425.593750, `position_y` = -1310.435547, `position_z` = 50.339096,
  `orientation` = 5.962836, `rotation0` = -0.029991864, `rotation1` = 0.185640704,
  `rotation2` = 0.156645291, `rotation3` = -0.969587680,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940610;

-- Enchanted Kobold Lantern (95619): Jasperlode Mine - Worldforged Enchanted Kobold Lantern | realm map Elwynn Forest | in-game placement 2026-09-23
--   authored in game (spawns_20260923_224219.sql): moved 0.01 yd, height +0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9242.375000, `position_y` = -721.337891, `position_z` = 63.585106,
  `orientation` = 0.089059, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.044515000, `rotation3` = 0.999009000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940436;

-- Forgotten Sack (90636): Northshire Valley - Worldforged Adventurer's Lost Sack | realm map Northshire Valley | in-game placement 2026-09-23
--   authored in game (spawns_20260923_220245.sql): moved 0.00 yd, height +0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9039.966797, `position_y` = -46.109375, `position_z` = 89.797409,
  `orientation` = 1.549410, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.699505000, `rotation3` = 0.714627000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940013;

-- Glinting Kobold Corpse (90223): Elwynn Forest - Worldforged Glinting Kobold Corpse | realm map Elwynn Forest | in-game placement 2026-09-23
--   authored in game (spawns_20260923_223532.sql): moved 0.00 yd, height +0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9054.572266, `position_y` = -619.929688, `position_z` = 53.798939,
  `orientation` = 2.048441, `rotation0` = 0.044817502, `rotation1` = 0.027267147,
  `rotation2` = 0.853132819, `rotation3` = 0.519049407,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940549;

-- Half-Buried Crate (254365): Forest's Edge - Worldforged Kreil's Gauntlets | realm map Westfall | in-game placement 2026-09-23
--   authored in game (spawns_20260923_232251.sql): moved 0.00 yd, height -0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9847.945312, `position_y` = 735.925781, `position_z` = 27.586975,
  `orientation` = 0.000000, `rotation0` = -0.101196011, `rotation1` = 0.000000000,
  `rotation2` = 0.000000000, `rotation3` = 0.994866507,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940685;

-- Heavy Iron Pan (95687): Goldshire - Worldforged Heavy Iron Pan | realm map Elwynn Forest | in-game placement 2026-09-23
--   authored in game (spawns_20260923_221742.sql): moved 0.00 yd, height +0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9487.296875, `position_y` = -35.515625, `position_z` = 58.409111,
  `orientation` = 6.267008, `rotation0` = -0.005684411, `rotation1` = 0.702738158,
  `rotation2` = -0.005754498, `rotation3` = 0.711402596,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940609;

-- Murder Machete (95697): Crystal Lake - Worldforged Murder Machete | realm map Elwynn Forest | in-game placement 2026-09-23
--   authored in game (spawns_20260923_224726.sql): moved 0.00 yd, height +0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9396.060547, `position_y` = -115.701172, `position_z` = 58.647606,
  `orientation` = 5.226943, `rotation0` = -0.212574618, `rotation1` = -0.206789013,
  `rotation2` = 0.481242217, `rotation3` = -0.824897729,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940781;

-- Murloc Ritual Stick (95693): Crystal Lake - Worldforged Murloc Ritual Staff | realm map Elwynn Forest | in-game placement 2026-09-23
--   authored in game (spawns_20260923_224514.sql): moved 0.01 yd, height -0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9494.375000, `position_y` = -396.589844, `position_z` = 59.906490,
  `orientation` = 1.325840, `rotation0` = 0.551992906, `rotation1` = -0.434928006,
  `rotation2` = 0.437832667, `rotation3` = 0.560753079,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940786;

-- Murloc Tool (520066): Elwynn Forest - Worldforged Murloc Tool | realm map Elwynn Forest | in-game placement 2026-09-23
--   authored in game (spawns_20260923_222736.sql): moved 0.00 yd, height +0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -8545.029297, `position_y` = -515.380859, `position_z` = 146.306320,
  `orientation` = 1.194107, `rotation0` = 0.198719141, `rotation1` = -0.343172821,
  `rotation2` = -0.516112915, `rotation3` = -0.759190738,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940787;

-- Old Buckler (517356): Ridgepoint Tower - Worldforged Eastvale Buckler | realm map Elwynn Forest | in-game placement 2026-09-23
--   authored in game (spawns_20260923_225713.sql): moved 211.60 yd, height +3.00 yd, turned 0.507 rad (29.1 deg)
UPDATE `gameobject` SET
  `position_x` = -9558.300781, `position_y` = -1416.900391, `position_z` = 101.104141,
  `orientation` = 0.370911, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.184394000, `rotation3` = 0.982852000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940412;

-- Old Grave  (90215): Northshire Valley - Worldforged Deadman Walkers | realm map Northshire Valley | in-game placement 2026-09-23
--   authored in game (spawns_20260923_215849.sql): moved 0.00 yd, height +0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -8687.837891, `position_y` = -298.035156, `position_z` = 84.999100,
  `orientation` = 4.160401, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.873035000, `rotation3` = -0.487657000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940319;

-- Old Northshire Bolter (520064): Northshire Valley - Worldforged Old Northshire Bolter | realm map Elwynn Forest | in-game placement 2026-09-23
--   authored in game (spawns_20260923_220815.sql): moved 0.00 yd, height -0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -8801.505859, `position_y` = -399.378906, `position_z` = 75.956978,
  `orientation` = 0.326804, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.162676000, `rotation3` = 0.986680000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940835;

-- Riding Cloak (95696): Eastvale Logging Camp - Worldforged Riding Cloak | realm map Elwynn Forest | in-game placement 2026-09-23
--   authored in game (spawns_20260923_225108.sql): moved 0.01 yd, height +0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9484.265625, `position_y` = -1348.666016, `position_z` = 46.825241,
  `orientation` = 4.135550, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.879026947, `rotation3` = -0.476772090,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940961;

-- Riverpaw Pack Chieftain's Lunch (90224): Forest's Edge - Worldforged Bones to Gnaw | realm map Elwynn Forest
--   authored in game (spawns_20260923_231411.sql): moved 18.02 yd, height +0.12 yd, turned 1.062 rad (60.8 deg)
UPDATE `gameobject` SET
  `position_x` = -10111.466797, `position_y` = 685.147461, `position_z` = 32.120358,
  `orientation` = 2.614614, `rotation0` = -0.316721303, `rotation1` = -0.085439206,
  `rotation2` = 0.912059641, `rotation3` = 0.246038553,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940165;

-- Riverpaw Pack Second in Command's Lunch (90225): Stone Cairn Lake - Worldforged Bones to Munch | realm map Elwynn Forest | in-game placement 2026-09-23
--   authored in game (spawns_20260923_223732.sql): moved 0.00 yd, height +0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -8982.009766, `position_y` = -830.041016, `position_z` = 70.939018,
  `orientation` = 4.901860, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.637048000, `rotation3` = -0.770824000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940166;

-- Scarecrow Arm (90229): Brackwell Pumpkin Patch - Worldforged Enchanted Straw Appendage | realm map Elwynn Forest | in-game placement 2026-09-23
--   authored in game (spawns_20260923_232445.sql): moved 0.00 yd, height -0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9775.623047, `position_y` = -869.882812, `position_z` = 42.453659,
  `orientation` = 1.551576, `rotation0` = -0.207135828, `rotation1` = 0.254163378,
  `rotation2` = 0.661567399, `rotation3` = 0.674406631,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940439;

-- Scorched Tome (520063): Northshire Valley - Worldforged Forsaken Tome | realm map Northshire Valley | in-game placement 2026-09-23
--   authored in game (spawns_20260923_222622.sql): moved 0.00 yd, height -0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -8717.236328, `position_y` = -312.591797, `position_z` = 83.157379,
  `orientation` = 4.755889, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.691561000, `rotation3` = -0.722318000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940503;

-- Slain Traveler (254232): Northshire Valley - Worldforged Vengeful Heart | realm map Elwynn Forest | in-game placement 2026-09-23
--   authored in game (spawns_20260923_222215.sql): moved 0.00 yd, height +0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -8697.207031, `position_y` = -474.267578, `position_z` = 153.514267,
  `orientation` = 5.784561, `rotation0` = -0.021831621, `rotation1` = 0.254621649,
  `rotation2` = -0.238544474, `rotation3` = 0.936903266,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6941293;

-- Spare Equipment (95686): Elwynn Forest - Worldforged Gardening Gloves | realm map Elwynn Forest | in-game placement 2026-09-23
--   authored in game (spawns_20260923_223104.sql): moved 0.00 yd, height +0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9060.480469, `position_y` = 157.134766, `position_z` = 114.987076,
  `orientation` = 1.600139, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.717404429, `rotation3` = 0.696656935,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940523;

-- Stormwind Memento Offering (90226): Heroes' Vigil - Worldforged Stormwind Memento | realm map Elwynn Forest | in-game placement 2026-09-23
--   authored in game (spawns_20260923_224041.sql): moved 0.00 yd, height +0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9139.632812, `position_y` = -1049.046875, `position_z` = 73.996201,
  `orientation` = 3.070993, `rotation0` = 0.080843053, `rotation1` = -0.000366903,
  `rotation2` = 0.996105839, `rotation3` = 0.035177032,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6941165;

-- Sword in a Board (95603): Northshire Vineyards - Worldforged Patrolman's Sword | realm map Northshire Valley | in-game placement 2026-09-23
--   authored in game (spawns_20260923_215715.sql): moved 0.00 yd, height +0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9055.574219, `position_y` = -462.070312, `position_z` = 75.099808,
  `orientation` = 4.583937, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.751032223, `rotation3` = -0.660265553,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940869;

-- Talon Idol (97103): Stone Cairn Lake - Worldforged Talon Idol | realm map Elwynn Forest | in-game placement 2026-09-23
--   authored in game (spawns_20260923_230950.sql): moved 0.01 yd, height -0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -8965.753906, `position_y` = -1195.146484, `position_z` = 71.415382,
  `orientation` = 3.978694, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.913678900, `rotation3` = -0.406436794,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6941195;

-- Thunder Falls Enchanted Branches (90236): Elwynn Forest - Worldforged Thunderfall Wand | realm map Elwynn Forest | in-game placement 2026-09-23
--   authored in game (spawns_20260923_232643.sql): moved 0.00 yd, height -0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9573.281250, `position_y` = 913.026367, `position_z` = 22.089094,
  `orientation` = 3.401760, `rotation0` = -0.040172829, `rotation1` = -0.307079326,
  `rotation2` = 0.942802092, `rotation3` = -0.123339555,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6941245;

-- Waterlogged Chest (95613): Northshire Valley - Worldforged Water Wraps | realm map Northshire Valley | in-game placement 2026-09-23
--   authored in game (spawns_20260923_221422.sql): moved 0.00 yd, height +0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -8753.859375, `position_y` = -395.783203, `position_z` = 68.262718,
  `orientation` = 3.073792, `rotation0` = -0.159594143, `rotation1` = 0.077255446,
  `rotation2` = 0.983589673, `rotation3` = 0.033356583,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6941326;

-- Wax Stained Bag (90214): Northshire Valley - Worldforged Wax Stained Bag | realm map Elwynn Forest | in-game placement 2026-09-23
--   authored in game (spawns_20260923_215455.sql): moved 0.00 yd, height -0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -8769.048828, `position_y` = -174.089844, `position_z` = 83.936996,
  `orientation` = 1.431941, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.656350000, `rotation3` = 0.754457000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6941333;

-- Worn Shovel (95602): Echo Ridge Mine - Worldforged Worn Shovel | realm map Elwynn Forest | in-game placement 2026-09-23
--   authored in game (spawns_20260923_222001.sql): moved 0.00 yd, height +0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -8627.250000, `position_y` = -107.925781, `position_z` = 89.902443,
  `orientation` = 3.073726, `rotation0` = -0.597746656, `rotation1` = -0.118914410,
  `rotation2` = 0.792360273, `rotation3` = 0.026897899,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6941353;

-- Morale Boosters (95692): a placement the realm authored by hand (spawns_20260923_214256.sql), written here on the guid it already had, 6960005
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960005, 95692, 0, 0, 0, 1, 1, -9630.685547, 693.706055, 38.630177, 5.944614, 0.000000000, 0.000000000, -0.168478439, 0.985705339, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Morale Boosters | in-game placement 2026-09-23 (spawns_20260923_214256.sql)');

-- Scorched Tome (520063): a placement the realm authored by hand (spawns_20260923_222622.sql), written here on the guid it already had, 6960006
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960006, 520063, 0, 0, 0, 1, 1, -8669.251953, -179.753906, 90.777596, 0.000000, 0.000000000, 0.000000000, 0.000000000, 1.000000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Scorched Tome | in-game placement 2026-09-23 (spawns_20260923_222622.sql)');

-- Scorched Tome (520063): a placement the realm authored by hand (spawns_20260923_222622.sql), written here on the guid it already had, 6960007
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960007, 520063, 0, 0, 0, 1, 1, -8577.859375, -254.048828, 53.785217, 0.000000, 0.703245745, 0.000000000, 0.000000000, 0.710946849, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Scorched Tome | in-game placement 2026-09-23 (spawns_20260923_222622.sql)');

-- Rock Smasher (95655): a placement the realm authored by hand (spawns_20260923_223228.sql), written here on the guid it already had, 6960008
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960008, 95655, 0, 0, 0, 1, 1, -9067.083984, 156.576172, 114.810547, 0.000000, 0.000000000, -0.847925571, 0.000000000, -0.530115295, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Rock Smasher | in-game placement 2026-09-23 (spawns_20260923_223228.sql)');

-- Glinting Kobold Corpse (90223): a placement the realm authored by hand (spawns_20260923_223532.sql), written here on the guid it already had, 6960009
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960009, 90223, 0, 0, 0, 1, 1, -8949.962891, -767.009766, 69.457451, 0.000000, 0.000000000, 0.000000000, 0.000000000, 1.000000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Glinting Kobold Corpse | in-game placement 2026-09-23 (spawns_20260923_223532.sql)');

-- Objects the changesets also touch, which are not this module's and are left untouched:
--   James' Journal (guid 27022, script '')
--   Campfire (guid 26867, script '')

-- The editor wrote the same placement twice in one changeset; one row is placed:
--   Scorched Tome (520063) in spawns_20260923_222622.sql

COMMIT;
