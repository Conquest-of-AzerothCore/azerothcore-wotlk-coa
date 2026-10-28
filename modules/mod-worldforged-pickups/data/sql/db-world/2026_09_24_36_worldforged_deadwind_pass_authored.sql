-- ----------------------------------------------------------------------------
-- Worldforged pickups: the placements and rotations authored in game
-- ----------------------------------------------------------------------------
-- Every row below is a placement the realm authored by hand in the map editor (Noggit,
-- changed in the client's own data): the editor writes one changeset per save, and this
-- file is those changesets read in the order they were written, the last write to a row
-- winning.  Nothing here is inferred: position_x/y/z and the rotation quaternion are
-- what the editor emitted, down to the digit.
--
-- 22 rows of this module were moved and/or turned, 8 were removed, and
-- 6 placements were added.  The orientation column is written as the yaw the
-- quaternion represents, which is what the model is drawn with
-- - and here the editor's own orientation column agreed with it on every row.
--
-- Six of the eight removals are the editor's own, in the changesets below.  The other two are the
-- rows left behind once the zone was walked in game, each a second row of an object another row
-- already answers for: the Timberling Ritual Blade the editor placed at -11156.9 -2479.2 had its
-- old row still standing on the realm map's listing of it, and the two pages' listings of the
-- Shining Wand are both gone, so that item is handed out by no pickup of this module.  Both are
-- at the end of the removals, and both are named where they stand.
--
-- Rows the changesets touch that are not this module's are left exactly as they are, and
-- listed at the end of this header, so nothing that belongs to the world itself is swept
-- into a worldforged migration.
--
-- Idempotent: every statement is an UPDATE keyed on guid, or a REPLACE on a guid this file
-- allocates.  Apply to acore_world, then let the worldserver load the rows.
-- ----------------------------------------------------------------------------

START TRANSACTION;

-- Arlithrien Moon Orb (515430): Karazhan - Worldforged Arlithrien Moon Orb | realm map Deadwind Pass
--   authored in game (spawns_20260924_163818.sql): moved 70.71 yd, height -29.25 yd, turned 0.007 rad (0.4 deg)
UPDATE `gameobject` SET
  `position_x` = -10975.601562, `position_y` = -1965.636719, `position_z` = 39.134598,
  `orientation` = 0.006778, `rotation0` = 0.033139171, `rotation1` = 0.039763993,
  `rotation2` = 0.003384560, `rotation3` = 0.998653676,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6940080;

-- Blade of the Faithful (254518): Deadwind Pass - Worldforged Kire, Exaltation of the Ancient Ones | realm map Deadwind Pass
--   authored in game (spawns_20260924_155200.sql): moved 2.18 yd, height -0.20 yd, turned 2.565 rad (146.9 deg)
UPDATE `gameobject` SET
  `position_x` = -10953.761719, `position_y` = -1656.238281, `position_z` = 184.904602,
  `orientation` = 3.669575, `rotation0` = -0.666376987, `rotation1` = -0.215684335,
  `rotation2` = 0.689011495, `rotation3` = -0.186239466,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6940682;

-- Celestial Edge of Starfall (515434): Deadwind Pass - Worldforged Starfall Edge | realm map Deadwind Pass
--   authored in game (spawns_20260924_155821.sql): moved 89.43 yd, height -43.31 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -10861.330078, `position_y` = -1690.039062, `position_z` = 148.674927,
  `orientation` = 0.000000, `rotation0` = 0.000000000, `rotation1` = 0.666563828,
  `rotation2` = 0.000000000, `rotation3` = 0.745447961,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6941143;

-- Cellar Rubble (254498): The Vice - Worldforged Vintner's Wristguards | realm map Deadwind Pass
--   authored in game (spawns_20260924_161847.sql): moved 168.37 yd, height -149.52 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -11166.712891, `position_y` = -2073.904297, `position_z` = 35.072983,
  `orientation` = 1.740720, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.764561000, `rotation3` = 0.644551000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6941305;

-- Chainmail Gauntlets (90508): Deadwind Pass - Worldforged Ghoulbane Gauntlets | realm map Deadwind Pass
--   authored in game (spawns_20260924_161203.sql): moved 67.62 yd, height -16.63 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -10415.515625, `position_y` = -2020.570312, `position_z` = 93.119003,
  `orientation` = 3.814890, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.943867000, `rotation3` = -0.330326000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6940537;

-- Coalescence of Agony (254503): Deadwind Pass - Worldforged Aion of Desolation | realm map Deadwind Pass
--   authored in game (spawns_20260924_160930.sql): moved 1.93 yd, height +0.10 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -10355.478516, `position_y` = -1912.458984, `position_z` = 46.567997,
  `orientation` = 2.447869, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.940444000, `rotation3` = 0.339948000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6940026;

-- Cursed Branch (254491): Deadwind Pass - Worldforged Branch of Mourning | realm map Deadwind Pass
--   authored in game (spawns_20260924_161416.sql): moved 3.82 yd, height -3.67 yd, turned 2.946 rad (168.8 deg)
UPDATE `gameobject` SET
  `position_x` = -10287.494141, `position_y` = -2041.488281, `position_z` = 55.903893,
  `orientation` = 1.562895, `rotation0` = -0.178279015, `rotation1` = 0.231122876,
  `rotation2` = -0.673635838, `rotation3` = -0.678979798,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6940179;

-- Dark Scythe (254494): Deadman's Crossing - Worldforged Betrayal's Edge | realm map Deadwind Pass
--   authored in game (spawns_20260924_155057.sql): moved 1.46 yd, height +0.08 yd, turned 1.725 rad (98.8 deg)
UPDATE `gameobject` SET
  `position_x` = -10451.964844, `position_y` = -1721.740234, `position_z` = 85.864082,
  `orientation` = 0.102150, `rotation0` = -0.133553466, `rotation1` = -0.631378426,
  `rotation2` = -0.038998475, `rotation3` = -0.762891784,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6940115;

-- Fallen Hero's Shield (254505): Morgan's Plot - Worldforged Bastion of the Fallen | realm map Deadwind Pass
--   authored in game (spawns_20260924_162828.sql): moved 1.47 yd, height +0.04 yd, turned 0.954 rad (54.6 deg)
UPDATE `gameobject` SET
  `position_x` = -11066.158203, `position_y` = -1830.765625, `position_z` = 60.370239,
  `orientation` = 1.992377, `rotation0` = 0.292947414, `rotation1` = 0.433875909,
  `rotation2` = 0.715188030, `rotation3` = 0.463076224,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6940109;

-- Fallen Traveler's Pauldrons (254516): Deadwind Ravine - Worldforged Pauldrons of Shadow | realm map Deadwind Pass
--   authored in game (spawns_20260924_163401.sql): moved 3.61 yd, height +0.06 yd, turned 0.292 rad (16.7 deg)
UPDATE `gameobject` SET
  `position_x` = -10624.367188, `position_y` = -1904.636719, `position_z` = 118.145508,
  `orientation` = 5.228920, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.503057430, `rotation3` = -0.864252985,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6940872;

-- Foreboding Banner (254493): Deadwind Pass - Worldforged Banner of the Dark Riders | realm map Deadwind Pass
--   authored in game (spawns_20260924_160403.sql): moved 3.06 yd, height -0.01 yd, turned 1.873 rad (107.3 deg)
UPDATE `gameobject` SET
  `position_x` = -10375.089844, `position_y` = -1779.037109, `position_z` = 95.966103,
  `orientation` = 6.266958, `rotation0` = 0.015178049, `rotation1` = 0.661151507,
  `rotation2` = 0.006085938, `rotation3` = -0.750074178,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6940105;

-- Fragment of K'aresh (1345056): Karazhan - Worldforged Fragment of K'aresh | realm map Deadwind Pass
--   authored in game (spawns_20260924_163941.sql): moved 10.00 yd, height -6.62 yd, turned 0.069 rad (4.0 deg)
UPDATE `gameobject` SET
  `position_x` = -11180.355469, `position_y` = -1925.298828, `position_z` = 60.231876,
  `orientation` = 0.688079, `rotation0` = 0.184320167, `rotation1` = -0.424702716,
  `rotation2` = 0.298966461, `rotation3` = 0.834429586,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6940506;

-- Heirloom of the Whisperwind (515436): Deadwind Pass - Worldforged Whisperwind Heirloom | realm map Deadwind Pass
--   authored in game (spawns_20260924_162221.sql): moved 284.46 yd, height -157.96 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -11162.777344, `position_y` = -2052.953125, `position_z` = 53.941833,
  `orientation` = 0.000000, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.000000000, `rotation3` = 1.000000000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6941336;

-- Intact Boots (254489): Karazhan - Worldforged Ashen Boots | realm map Deadwind Pass
--   authored in game (spawns_20260924_164124.sql): moved 7.37 yd, height -4.81 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -11173.761719, `position_y` = -2050.166016, `position_z` = 47.860096,
  `orientation` = 5.637510, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.317259000, `rotation3` = -0.948339000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6940081;

-- Long-Abandoned Circlet (254492): Ariden's Camp - Worldforged Ariden's Circlet | realm map Deadwind Pass
--   authored in game (spawns_20260924_154903.sql): moved 3.38 yd, height -0.09 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -10433.888672, `position_y` = -2136.197266, `position_z` = 91.724586,
  `orientation` = 4.538259, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.765915000, `rotation3` = -0.642942000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6940078;

-- Red Plumage (90565): Deadwind Ravine - Worldforged Harpy Feather Drape | realm map Deadwind Pass
--   authored in game (spawns_20260924_163211.sql): moved 28.29 yd, height -17.18 yd, turned 3.082 rad (176.6 deg)
UPDATE `gameobject` SET
  `position_x` = -10559.117188, `position_y` = -1742.529297, `position_z` = 92.496292,
  `orientation` = 3.201256, `rotation0` = -0.565186381, `rotation1` = 0.022253691,
  `rotation2` = -0.824296120, `rotation3` = 0.024597464,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6940593;

-- Reverent Ring (254506): Deadwind Pass - Worldforged Reverence of the Ancient Ones | realm map Deadwind Pass
--   authored in game (spawns_20260924_160018.sql): moved 3.59 yd, height +0.07 yd, turned 0.020 rad (1.1 deg)
UPDATE `gameobject` SET
  `position_x` = -10977.462891, `position_y` = -1752.439453, `position_z` = 140.695663,
  `orientation` = 4.621741, `rotation0` = 0.477313818, `rotation1` = 0.501465829,
  `rotation2` = 0.532841287, `rotation3` = -0.486604258,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6940954;

-- Scorched Tome (520063): Deadwind Pass - Worldforged Forsaken Tome | realm map Deadwind Pass
--   authored in game (spawns_20260924_160759.sql): moved 914.03 yd, height -158.48 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -11177.130859, `position_y` = -1856.992188, `position_z` = 74.134285,
  `orientation` = 0.000000, `rotation0` = 0.364033910, `rotation1` = 0.000000000,
  `rotation2` = 0.000000000, `rotation3` = 0.931385695,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6940502;

-- Shelf of Recipes (254499): Deadwind Pass - Worldforged Shelf of Recipes | realm map Stranglethorn Vale
--   authored in game (spawns_20260924_161633.sql): moved 1.58 yd, height -0.05 yd, turned 0.448 rad (25.7 deg)
UPDATE `gameobject` SET
  `position_x` = -11408.919922, `position_y` = -2156.730469, `position_z` = 34.577419,
  `orientation` = 6.159327, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = -0.061889587, `rotation3` = 0.998083002,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6941067;

-- Timberbane's Old Hatchet (515437): Deadwind Pass - Worldforged Timberbane Axe | realm map Deadwind Pass
--   authored in game (spawns_20260924_161510.sql): moved 20.10 yd, height -28.44 yd, turned 2.926 rad (167.6 deg)
UPDATE `gameobject` SET
  `position_x` = -10300.519531, `position_y` = -2020.693359, `position_z` = 51.715721,
  `orientation` = 3.357372, `rotation0` = 0.045008548, `rotation1` = 0.415552997,
  `rotation2` = 0.903172559, `rotation3` = -0.097822626,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6941254;

-- Unique Bush (90554): Deadwind Pass - Worldforged Saplingweave Handwraps | realm map Deadwind Pass
--   authored in game (spawns_20260924_160922.sql): moved 149.22 yd, height +16.23 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -10300.277344, `position_y` = -1908.000000, `position_z` = 48.416096,
  `orientation` = 0.000000, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.000000000, `rotation3` = 1.000000000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6941003;

-- Venerable Necklace (254507): Deadwind Pass - Worldforged Veneration to the Ancient Ones | realm map Deadwind Pass
--   authored in game (spawns_20260924_160055.sql): moved 3.39 yd, height +0.60 yd, turned 1.413 rad (81.0 deg)
UPDATE `gameobject` SET
  `position_x` = -11030.173828, `position_y` = -1742.117188, `position_z` = 140.602432,
  `orientation` = 4.435982, `rotation0` = 0.437449384, `rotation1` = -0.454643318,
  `rotation2` = 0.618953415, `rotation3` = -0.467797136,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6941291;

-- Forgotten Cane (90552) at (-10832.9, -2408.0, 270.5) in Deadwind Pass: removed in game (20260924_162405) - the editor took the object out of the client's own data
DELETE FROM `gameobject` WHERE `guid` = 6940765;

-- Lunar Tome (515431) at (-10849.5, -2483.0, 207.9) in Deadwind Pass: removed in game (20260924_162741) - the editor took the object out of the client's own data
DELETE FROM `gameobject` WHERE `guid` = 6940728;

-- Shining Wand (254488) at (-11113.2, -2083.0, 50.4) in Karazhan: removed in game (20260924_164349) - the editor took the object out of the client's own data
DELETE FROM `gameobject` WHERE `guid` = 6941307;

-- Small War Drum (515388) at (-10932.9, -2483.0, 176.2) in Deadwind Pass: removed in game (20260924_162550) - the editor took the object out of the client's own data
DELETE FROM `gameobject` WHERE `guid` = 6940519;

-- Stuck Scimitar (90562) at (-10716.2, -1983.0, 129.0) in Sleeping Gorge: removed in game (20260924_164810) - the editor took the object out of the client's own data
DELETE FROM `gameobject` WHERE `guid` = 6940248;

-- Wooden Maul (90553) at (-11032.9, -2183.0, 50.5) in Karazhan: removed in game (20260924_164611) - the editor took the object out of the client's own data
DELETE FROM `gameobject` WHERE `guid` = 6941253;

-- Timberling Ritual Blade (515433) at (-11116.2, -2183.0, 79.9) on the realm map's own listing of
-- it: removed here as well, after the zone was walked in game.  The editor placed the same object
-- at -11156.9 -2479.2 above (guid 6960019) and left this row standing where the object used to
-- be, so the zone holds one of this object and not two.
DELETE FROM `gameobject` WHERE `guid` = 6941255;

-- Shining Wand (254488) at (-10764.4, -3369.2, -9.5): the map's other drawing of the item whose
-- Deadwind row the editor removed above, and removed here as well on the same walk.  Neither of
-- the two pages' listings of this object stands any more.
DELETE FROM `gameobject` WHERE `guid` = 6941308;

-- Forgotten Cane (90552): a placement the realm authored by hand (spawns_20260924_162446.sql), guid 6960016 allocated here
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960016, 90552, 0, 0, 0, 1, 1, -11064.164062, -2154.941406, 27.921112, 0.589043, 0.296548752, -0.635942379, 0.206821869, 0.681807043, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Forgotten Cane | in-game placement 2026-09-24 (spawns_20260924_162446.sql)');

-- Small War Drum (515388): a placement the realm authored by hand (spawns_20260924_162606.sql), guid 6960017 allocated here
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960017, 515388, 0, 0, 0, 1, 1, -10996.710938, -2312.513672, 117.026260, 0.000000, 0.000000000, 0.000000000, 0.000000000, 1.000000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Small War Drum | in-game placement 2026-09-24 (spawns_20260924_162606.sql)');

-- Lunar Tome (515431): a placement the realm authored by hand (spawns_20260924_162930.sql), guid 6960018 allocated here
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960018, 515431, 0, 0, 0, 1, 1, -11116.197266, -2085.445312, 49.430202, 0.303511, 0.717941439, -0.109518326, 0.103922051, 0.679533689, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Lunar Tome | in-game placement 2026-09-24 (spawns_20260924_162930.sql)');

-- Timberling Ritual Blade (515433): a placement the realm authored by hand (spawns_20260924_164535.sql), guid 6960019 allocated here
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960019, 515433, 0, 0, 0, 1, 1, -11156.859375, -2479.242188, 105.280647, 4.655623, 0.000000000, 0.000000000, -0.726889185, 0.686754769, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Timberling Ritual Blade | in-game placement 2026-09-24 (spawns_20260924_164535.sql)');

-- Wooden Maul (90553): a placement the realm authored by hand (spawns_20260924_164634.sql), guid 6960020 allocated here
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960020, 90553, 0, 0, 0, 1, 1, -10855.611328, -2286.378906, 117.174507, 0.997111, 0.000000000, 0.000000000, 0.478157567, 0.878274069, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Wooden Maul | in-game placement 2026-09-24 (spawns_20260924_164634.sql)');

-- Stuck Scimitar (90562): a placement the realm authored by hand (spawns_20260924_164854.sql), guid 6960021 allocated here
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960021, 90562, 0, 0, 0, 1, 1, -10836.978516, -2089.300781, 124.530807, 5.570771, 0.000000000, 0.000000000, -0.348722013, 0.937226204, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Stuck Scimitar | in-game placement 2026-09-24 (spawns_20260924_164854.sql)');

COMMIT;
