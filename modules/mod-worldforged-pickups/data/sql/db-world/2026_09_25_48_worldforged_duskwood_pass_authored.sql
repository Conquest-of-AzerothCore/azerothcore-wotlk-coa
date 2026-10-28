-- ----------------------------------------------------------------------------
-- Worldforged pickups: the placements and rotations authored in game
-- ----------------------------------------------------------------------------
-- Every row below is a placement the realm authored by hand in the map editor (Noggit,
-- changed in the client's own data): the editor writes one changeset per save, and this
-- file is those changesets read in the order they were written, the last write to a row
-- winning.  Nothing here is inferred: position_x/y/z and the rotation quaternion are
-- what the editor emitted, down to the digit.
--
-- This pass: the Duskwood walk of 2026-09-25: the zone's own pickups walked in the map editor, moved, turned and thinned, one save at a time (58 changesets from the pro2 project).
--
-- 30 rows of this module were moved and/or turned, 14 were removed, and
-- 9 placements were added.  The orientation column is written as the yaw the
-- quaternion represents, which is what the model is drawn with
-- - and the editor's own orientation column disagreed with its quaternion on
-- 3 of the rows, each noted where it occurs.
--
-- Rows the changesets touch that are not this module's are left exactly as they are, and
-- listed at the end of this header, so nothing that belongs to the world itself is swept
-- into a worldforged migration.
--
-- Idempotent: every statement is an UPDATE keyed on guid, or a REPLACE on a guid this file
-- allocates.  Apply to acore_world, then let the worldserver load the rows.
-- ----------------------------------------------------------------------------

START TRANSACTION;

-- Atonement (89640): Beggar's Haunt - Worldforged Hope for Atonement | realm map Duskwood
--   authored in game (spawns_20260925_100956.sql): moved 7.35 yd, height +0.66 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -10266.476562, `position_y` = -1625.546875, `position_z` = 97.670967,
  `orientation` = 1.471669, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.671206000, `rotation3` = 0.741271000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940635;

-- Axe of the Frostmane (95514): Raven Hill - Worldforged Frostmane Axe | realm map Duskwood
--   authored in game (spawns_20260925_111510.sql): moved 115.73 yd, height -2.54 yd, turned 0.091 rad (5.2 deg)
UPDATE `gameobject` SET
  `position_x` = -10752.691406, `position_y` = 310.695312, `position_z` = 39.288841,
  `orientation` = 0.090770, `rotation0` = 0.674649703, `rotation1` = -0.149189498,
  `rotation2` = 0.032797791, `rotation3` = 0.722159662,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940510;

-- Catacomb Grave Dirt Pile (90286): Raven Hill Cemetery - Worldforged Catacomb Grave Dirt Pile | realm map Westfall
--   authored in game (spawns_20260925_112448.sql): moved 2.27 yd, height +0.00 yd, turned 0.026 rad (1.5 deg)
--   the changeset's own orientation column said 1.7031 while its quaternion represents 2.0029; the quaternion is written, and the column follows it
UPDATE `gameobject` SET
  `position_x` = -10282.785156, `position_y` = 180.025391, `position_z` = 2.022000,
  `orientation` = 2.002854, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.842241201, `rotation3` = 0.539100880,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940224;

-- Catacomb Grave Dirt Pile (90286): Raven Hill Cemetery - Worldforged Hazard Mantle | realm map Duskwood
--   authored in game (spawns_20260925_111814.sql): moved 24.90 yd, height -2.40 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -10322.564453, `position_y` = 170.648438, `position_z` = 36.074821,
  `orientation` = 2.028930, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.849198000, `rotation3` = 0.528074000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940603;

-- Catacombs Relic Torch (90282): Forlorn Rowe - Worldforged Catacombs Torch | realm map Duskwood
--   authored in game (spawns_20260925_104854.sql): moved 78.02 yd, height -23.23 yd, turned 2.203 rad (126.2 deg)
UPDATE `gameobject` SET
  `position_x` = -10406.392578, `position_y` = 339.863281, `position_z` = 27.921539,
  `orientation` = 1.175819, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = -0.554622785, `rotation3` = -0.832101897,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940226;

-- Clawed Chest (95945): Brightwood Grove - Worldforged Brightwood Gloves | realm map Duskwood
--   authored in game (spawns_20260925_101459.sql): moved 6.03 yd, height -0.74 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -10261.595703, `position_y` = -734.658203, `position_z` = 45.755348,
  `orientation` = 3.202430, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.999537000, `rotation3` = -0.030414000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940187;

-- Darkest Night Ring (90288): Forlorn Rowe - Worldforged Darkest Night Loop | realm map Duskwood
--   authored in game (spawns_20260925_110510.sql): moved 0.19 yd, height +0.03 yd, turned 0.448 rad (25.6 deg)
UPDATE `gameobject` SET
  `position_x` = -10314.494141, `position_y` = 360.111328, `position_z` = 61.350636,
  `orientation` = 3.041335, `rotation0` = 0.728635247, `rotation1` = 0.016256570,
  `rotation2` = 0.683848871, `rotation3` = 0.034309226,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940309;

-- Darkshire Grave (90272): Tranquil Gardens Cemetery - Worldforged Dusty Priest Cloak | realm map Duskwood
--   authored in game (spawns_20260925_114655.sql): moved 33.56 yd, height -0.28 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -10969.289062, `position_y` = -1310.041016, `position_z` = 52.454178,
  `orientation` = 4.122470, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.882126000, `rotation3` = -0.471013000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940393;

-- Defias Night Blade (90274): The Yorgen Farmstead - Worldforged Defias Night Blade | realm map Duskwood
--   authored in game (spawns_20260925_112852.sql): moved 11.02 yd, height -0.22 yd, turned 3.051 rad (174.8 deg)
UPDATE `gameobject` SET
  `position_x` = -11104.431641, `position_y` = -531.734375, `position_z` = 34.372692,
  `orientation` = 2.566665, `rotation0` = -0.311372056, `rotation1` = -0.092058077,
  `rotation2` = 0.907007828, `rotation3` = 0.268159568,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940342;

-- Eliza's Pendant (90269): Raven Hill Cemetery - Worldforged Eliza's Pendant | realm map Duskwood
--   authored in game (spawns_20260925_112029.sql): moved 2.12 yd, height -0.71 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -10271.164062, `position_y` = 54.421875, `position_z` = 42.489010,
  `orientation` = 0.277530, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.138320000, `rotation3` = 0.990388000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940421;

-- Emerald Shard (90290): Duskwood - Worldforged Emerald Shard | realm map Duskwood
--   authored in game (spawns_20260925_103110.sql): moved 0.62 yd, height -0.47 yd, turned 1.025 rad (58.7 deg)
--   the changeset's own orientation column said 0.9171 while its quaternion represents 2.3663; the quaternion is written, and the column follows it
UPDATE `gameobject` SET
  `position_x` = -10866.699219, `position_y` = -427.027344, `position_z` = 50.120762,
  `orientation` = 2.366303, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = -0.925801814, `rotation3` = -0.378009260,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940431;

-- Fallen Warrior's Axe (95942): Duskwood - Worldforged Fallen Warrior's Axe | realm map Westfall
--   authored in game (spawns_20260925_103644.sql): moved 19.56 yd, height +0.34 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -11225.330078, `position_y` = -179.775391, `position_z` = 5.196305,
  `orientation` = 1.050439, `rotation0` = -0.374891930, `rotation1` = 0.217254851,
  `rotation2` = 0.451890738, `rotation3` = 0.779776334,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940459;

-- Haren's Tankard (1345067): Addle's Stead - Worldforged Discarded Junk | realm map Duskwood
--   authored in game (spawns_20260925_100335.sql): moved 16.46 yd, height +0.87 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -11009.023438, `position_y` = 194.820312, `position_z` = 28.827204,
  `orientation` = 0.413306, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.205185000, `rotation3` = 0.978723000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940361;

-- Lantern of Endless Sorrow (254366): Raven Hill Cemetery - Worldforged Sorrow's Light | realm map Westfall
--   authored in game (spawns_20260925_111601.sql): moved 50.22 yd, height -6.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -10484.710938, `position_y` = 399.167969, `position_z` = 38.105976,
  `orientation` = 0.000000, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.000000000, `rotation3` = 1.000000000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6941115;

-- Munitions Crate (90289): Duskwood - Worldforged Munitions Delivery Package | realm map Duskwood
--   authored in game (spawns_20260925_104341.sql): moved 2.53 yd, height -1.08 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -10853.218750, `position_y` = -462.281250, `position_z` = 41.878910,
  `orientation` = 4.104170, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.886399000, `rotation3` = -0.462922000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940780;

-- Murloc Crown (254394): The Darkened Bank - Worldforged Murloc Crown | realm map Westfall
--   authored in game (spawns_20260925_112448.sql): moved 0.27 yd, height +0.17 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -10037.929688, `position_y` = -163.710938, `position_z` = 21.386391,
  `orientation` = 0.000000, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.000000000, `rotation3` = 1.000000000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940785;

-- Nightshot (95826): Addle's Stead - Worldforged Nightshot | realm map Westfall
--   authored in game (spawns_20260925_100149.sql): moved 2.02 yd, height -0.02 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -11027.169922, `position_y` = 253.507812, `position_z` = 30.454782,
  `orientation` = 1.333861, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.618577000, `rotation3` = 0.785724000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940810;

-- Nightwatch Circlet (90271): Darkshire - Worldforged Nightwatch Circlet | realm map Duskwood
--   authored in game (spawns_20260925_102235.sql): moved 7.76 yd, height -0.02 yd, turned 0.301 rad (17.2 deg)
UPDATE `gameobject` SET
  `position_x` = -10657.677734, `position_y` = -1263.164062, `position_z` = 31.777443,
  `orientation` = 2.822543, `rotation0` = 0.654784541, `rotation1` = 0.073457707,
  `rotation2` = 0.742686215, `rotation3` = 0.119492078,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940811;

-- Peculiar Root (90287): The Darkened Bank - Worldforged Peculiar Root | realm map Elwynn Forest
--   authored in game (spawns_20260925_112141.sql): moved 2.16 yd, height +0.03 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -10166.000000, `position_y` = 319.160156, `position_z` = 6.294374,
  `orientation` = 1.021570, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.488862000, `rotation3` = 0.872361000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940878;

-- Sharp Bone Necklace (90285): Raven Hill Cemetery - AscensionWorldforged Sharp Bone Necklace | AtlasLoot Duskwood | Z from the realm dump's own height there
--   authored in game (spawns_20260925_112448.sql): moved 9.84 yd, height +0.00 yd, turned 0.026 rad (1.5 deg)
--   the changeset's own orientation column said 2.2626 while its quaternion represents 2.5623; the quaternion is written, and the column follows it
UPDATE `gameobject` SET
  `position_x` = -10282.634766, `position_y` = 155.220703, `position_z` = 1.809000,
  `orientation` = 2.562324, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.958348312, `rotation3` = 0.285602020,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6930015;

-- Silk Covered Spaulders (95823): Duskwood - Worldforged Silky Spaulders | realm map Duskwood
--   authored in game (spawns_20260925_104656.sql): moved 18.41 yd, height +1.01 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -10569.523438, `position_y` = -1504.900391, `position_z` = 95.118439,
  `orientation` = 5.564071, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.351860000, `rotation3` = -0.936053000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6941083;

-- Sizzling Potion (1345132): Vul'Gol Ogre Mound - Worldforged Sizzling Potion | realm map Westfall
--   authored in game (spawns_20260925_114807.sql): moved 150.67 yd, height -2.00 yd, turned 2.491 rad (142.7 deg)
UPDATE `gameobject` SET
  `position_x` = -11078.607422, `position_y` = -70.164062, `position_z` = 15.476537,
  `orientation` = 3.791896, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.947602339, `rotation3` = -0.319452356,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6941088;

-- Skeleton Hand (90279): Raven Hill Cemetery - Worldforged Raven Hill Backscratcher | realm map Duskwood
--   authored in game (spawns_20260925_111646.sql): moved 0.00 yd, height -0.19 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -10564.199219, `position_y` = 269.300781, `position_z` = 29.440699,
  `orientation` = 1.623970, `rotation0` = -0.034062099, `rotation1` = 0.035923225,
  `rotation2` = 0.724764666, `rotation3` = 0.687215741,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940931;

-- Spare Bag (95821): Darkshire - Worldforged Lohgan's Best Bag | realm map Duskwood
--   authored in game (spawns_20260925_102018.sql): moved 26.40 yd, height +2.12 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -10563.261719, `position_y` = -1173.140625, `position_z` = 28.913612,
  `orientation` = 3.819700, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.943070000, `rotation3` = -0.332595000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6940709;

-- Spare Bag (95821): Darkshire - Worldforged Spare Bag | realm map Duskwood
--   authored in game (spawns_20260925_102147.sql): moved 1.11 yd, height -0.21 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -10539.214844, `position_y` = -1224.529297, `position_z` = 34.036613,
  `orientation` = 3.819700, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.943070000, `rotation3` = -0.332595000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6941119;

-- Suspiciously Brown Discarded Pants (95824): Duskwood - Worldforged Suspiciously Brown Trousers | realm map Duskwood
--   authored in game (spawns_20260925_104512.sql): moved 23.78 yd, height -3.46 yd, turned 0.333 rad (19.1 deg)
UPDATE `gameobject` SET
  `position_x` = -10788.296875, `position_y` = -1377.597656, `position_z` = 40.474079,
  `orientation` = 2.912991, `rotation0` = -0.772002534, `rotation1` = 0.630261305,
  `rotation2` = 0.081820205, `rotation3` = 0.009393039,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6941180;

-- The Dark Soul (95822): Brightwood Grove - Worldforged The Dark Soul | realm map Duskwood
--   authored in game (spawns_20260925_101415.sql): moved 14.01 yd, height -0.49 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -10436.011719, `position_y` = -813.183594, `position_z` = 52.133617,
  `orientation` = 4.437741, `rotation0` = -0.515869801, `rotation1` = -0.681313351,
  `rotation2` = 0.414024663, `rotation3` = -0.313486915,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6941212;

-- The Jitters (90278): Raven Hill - Worldforged The Jitters | realm map Westfall
--   authored in game (spawns_20260925_111101.sql): moved 3.93 yd, height +0.18 yd, turned 0.212 rad (12.1 deg)
UPDATE `gameobject` SET
  `position_x` = -10727.677734, `position_y` = 363.605469, `position_z` = 38.004906,
  `orientation` = 4.520187, `rotation0` = 0.550510410, `rotation1` = 0.401847305,
  `rotation2` = 0.564685907, `rotation3` = -0.465388932,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6941215;

-- Tilloa's Flowers (95825): Manor Mistmantle - Worldforged Tiloa's Flowers | realm map Duskwood
--   authored in game (spawns_20260925_110846.sql): moved 1.68 yd, height -1.25 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -10363.560547, `position_y` = -1269.285156, `position_z` = 36.586693,
  `orientation` = 4.483589, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.783201000, `rotation3` = -0.621768000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6941252;

-- Vul'Gol Torch  (90275): Duskwood - Worldforged Vul'Gol Torch | realm map Westfall
--   authored in game (spawns_20260925_103521.sql): moved 0.69 yd, height +0.04 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -11216.742188, `position_y` = -150.824219, `position_z` = 10.732817,
  `orientation` = 3.622331, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.971250000, `rotation3` = -0.238061000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-25%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-25'))
WHERE `guid` = 6941310;

-- Distant Wanderer's Pack (254384) at (-11229.8, -95.7, 96.7) in Duskwood: removed in game (20260925_102645) - the editor took the object out of the client's own data
DELETE FROM `gameobject` WHERE `guid` = 6940366;

-- Emerald Shard (90290) at (-10922.0, -516.5, 50.6) in Duskwood: removed in game (20260925_103239) - the editor took the object out of the client's own data
DELETE FROM `gameobject` WHERE `guid` = 6940430;

-- Grimtotem Totem (254227) at (-9999.4, -1067.5, 27.6) in The Darkened Bank: removed in game (20260925_112733) - the editor took the object out of the client's own data
DELETE FROM `gameobject` WHERE `guid` = 6940576;

-- Holy Atal'ai Band (254368) at (-10728.4, 256.3, 43.1) in Raven Hill: removed in game (20260925_111200) - the editor took the object out of the client's own data
DELETE FROM `gameobject` WHERE `guid` = 6940633;

-- Ice Beard's Furled Finger (95515) at (-10691.8, -205.8, 67.8) in Duskwood: removed in game (20260925_103905) - the editor took the object out of the client's own data
DELETE FROM `gameobject` WHERE `guid` = 6940516;

-- Lost Mountaineer's Bow (95507) at (-10839.9, -143.8, 32.0) in Duskwood: removed in game (20260925_103329) - the editor took the object out of the client's own data
DELETE FROM `gameobject` WHERE `guid` = 6940722;

-- Racing Goggles (515537) at (-10753.1, 426.7, 39.0) in Raven Hill: removed in game (20260925_111023) - the editor took the object out of the client's own data
DELETE FROM `gameobject` WHERE `guid` = 6941285;

-- Resonite Band (254230) at (-10045.6, -581.7, 43.4) in The Darkened Bank: removed in game (20260925_101607) - the editor took the object out of the client's own data
DELETE FROM `gameobject` WHERE `guid` = 6940952;

-- Ritual Blade (515438) at (-10332.8, -1683.0, 161.4) in Beggar's Haunt: removed in game (20260925_101039) - the editor took the object out of the client's own data
DELETE FROM `gameobject` WHERE `guid` = 6940705;

-- Sharp Bone Necklace (90285) at (-10372.9, 136.3, 33.3) in Raven Hill Cemetery: removed in game (20260925_111928) - the editor took the object out of the client's own data
DELETE FROM `gameobject` WHERE `guid` = 6940905;

-- Spear of Emerald (254369) at (-10943.7, 108.3, 38.0) in Addle's Stead: removed in game (20260925_100441) - the editor took the object out of the client's own data
DELETE FROM `gameobject` WHERE `guid` = 6941122;

-- Will in the Casket (90281) at (-11144.1, -348.9, 55.2) in Duskwood: removed in game (20260925_104211) - the editor took the object out of the client's own data
DELETE FROM `gameobject` WHERE `guid` = 6940223;

-- Wood Pile (90348) at (-11192.0, -435.5, 75.9) in The Yorgen Farmstead: removed in game (20260925_112812) - the editor took the object out of the client's own data
DELETE FROM `gameobject` WHERE `guid` = 6940862;

-- Woven Ceremonial Belt (254231) at (-10138.2, -998.1, 32.5) in Brightwood Grove: removed in game (20260925_101836) - the editor took the object out of the client's own data
DELETE FROM `gameobject` WHERE `guid` = 6941354;

-- Spear of Emerald (254369): a placement the realm authored by hand (spawns_20260925_100603.sql), guid 6960027 allocated here
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960027, 254369, 0, 0, 0, 1, 1, -10385.281250, -432.162109, 64.162811, 5.457367, 0.250509174, -0.554337352, -0.318491487, 0.726992728, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Spear of Emerald | in-game placement 2026-09-25 (spawns_20260925_100603.sql)');

-- Ritual Blade (515438): a placement the realm authored by hand (spawns_20260925_101310.sql), guid 6960028 allocated here
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960028, 515438, 0, 0, 0, 1, 1, -11224.427734, -180.052734, 4.768906, 0.000000, 0.000000000, 0.000000000, 0.000000000, 1.000000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Ritual Blade | in-game placement 2026-09-25 (spawns_20260925_101310.sql)');

-- Resonite Band (254230): a placement the realm authored by hand (spawns_20260925_101642.sql), guid 6960029 allocated here
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960029, 254230, 0, 0, 0, 1, 1, -10497.082031, -1272.429688, 43.017685, 2.527445, 0.000000000, 0.000000000, 0.953222214, 0.302270427, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Resonite Band | in-game placement 2026-09-25 (spawns_20260925_101642.sql)');

-- Woven Ceremonial Belt (254231): a placement the realm authored by hand (spawns_20260925_101914.sql), guid 6960030 allocated here
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960030, 254231, 0, 0, 0, 1, 1, -10369.638672, -1251.052734, 36.454048, 0.000000, 0.000000000, 0.000000000, 0.000000000, 1.000000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Woven Ceremonial Belt | in-game placement 2026-09-25 (spawns_20260925_101914.sql)');

-- Distant Wanderer's Pack (254384): a placement the realm authored by hand (spawns_20260925_102729.sql), guid 6960031 allocated here
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960031, 254384, 0, 0, 0, 1, 1, -11650.287109, -44.652344, 11.260746, 3.102670, 0.000000000, 0.000000000, 0.999811000, 0.019460000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Distant Wanderer''s Pack | in-game placement 2026-09-25 (spawns_20260925_102729.sql)');

-- Crimson Blade (254562): a placement the realm authored by hand (spawns_20260925_103201.sql), guid 6960032 allocated here
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960032, 254562, 0, 0, 0, 1, 1, -11232.021484, -886.562500, 82.547821, 4.649928, 0.422111194, 0.396536071, -0.594165289, 0.558165651, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Crimson Blade | in-game placement 2026-09-25 (spawns_20260925_103201.sql)');

-- Lost Mountaineer's Bow (95507): a placement the realm authored by hand (spawns_20260925_103351.sql), guid 6960033 allocated here
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960033, 95507, 0, 0, 0, 1, 1, -10923.562500, -381.177734, 39.483627, 0.217579, 0.107119026, 0.648251995, 0.081849561, 0.749396767, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Lost Mountaineer''s Bow | in-game placement 2026-09-25 (spawns_20260925_103351.sql)');

-- Will in the Casket (90281): a placement the realm authored by hand (spawns_20260925_104232.sql), guid 6960034 allocated here
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960034, 90281, 0, 0, 0, 1, 1, -10514.212891, 439.751953, 37.922661, 0.000000, 0.000000000, 0.000000000, 0.000000000, 1.000000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Will in the Casket | in-game placement 2026-09-25 (spawns_20260925_104232.sql)');

-- Sharp Bone Necklace (90285): a placement the realm authored by hand (spawns_20260925_112000.sql), guid 6960035 allocated here
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960035, 90285, 0, 0, 0, 1, 1, -10516.949219, 439.281250, 38.316093, 2.588400, -0.581665848, -0.165119237, -0.766218277, -0.217508691, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Sharp Bone Necklace | in-game placement 2026-09-25 (spawns_20260925_112000.sql)');

-- Objects the changesets also touch, which are not this module's and are left untouched:
--   Bruiseweed (guid 207693, script '')
--   Mageroyal (guid 207604, script '')

COMMIT;
