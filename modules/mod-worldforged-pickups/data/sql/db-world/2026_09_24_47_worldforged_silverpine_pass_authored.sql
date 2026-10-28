-- ----------------------------------------------------------------------------
-- Worldforged pickups: the placements and rotations authored in game
-- ----------------------------------------------------------------------------
-- Every row below is a placement the realm authored by hand in the map editor (Noggit,
-- changed in the client's own data): the editor writes one changeset per save, and this
-- file is those changesets read in the order they were written, the last write to a row
-- winning.  Nothing here is inferred: position_x/y/z and the rotation quaternion are
-- what the editor emitted, down to the digit.
--
-- 25 rows of this module were moved and/or turned, 13 were removed, and
-- 5 placements were added.  The orientation column is written as the yaw the
-- quaternion represents, which is what the model is drawn with
-- - and here the editor's own orientation column agreed with it on every row.
--
-- Rows the changesets touch that are not this module's are left exactly as they are, and
-- listed at the end of this header, so nothing that belongs to the world itself is swept
-- into a worldforged migration.
--
-- Idempotent: every statement is an UPDATE keyed on guid, or a REPLACE on a guid this file
-- allocates.  Apply to acore_world, then let the worldserver load the rows.
-- ----------------------------------------------------------------------------

START TRANSACTION;

-- Ancient Priest Tome (101912): Ambermill - AscensionWorldforged Ancient Priest Tome
--   authored in game (spawns_20260924_210935.sql): moved 17.35 yd, height -14.26 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -182.929688, `position_y` = 933.768555, `position_z` = 57.348728,
  `orientation` = 0.000000, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.000000000, `rotation3` = 1.000000000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6942542;

-- Boom Barrel (95526): Silverpine Forest - Worldforged Brother's Special Gift | realm map Silverpine Forest
--   authored in game (spawns_20260924_210935.sql): moved 29.39 yd, height -1.49 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -294.683594, `position_y` = 1224.553711, `position_z` = 47.132751,
  `orientation` = 0.000000, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.000000000, `rotation3` = 1.000000000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6940196;

-- Broken Barrel (517325): The Dead Field - Worldforged Darkstrand Kilt | realm map Silverpine Forest
--   authored in game (spawns_20260924_212416.sql): moved 1.50 yd, height -0.99 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = 1094.993164, `position_y` = 1577.033203, `position_z` = 28.048824,
  `orientation` = 1.355259, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.626948000, `rotation3` = 0.779061000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6940313;

-- Cold Crystal (101914): Ambermill - AscensionWorldforged Cold Crystal
--   authored in game (spawns_20260924_210935.sql): moved 17.35 yd, height -14.26 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -152.128906, `position_y` = 790.968750, `position_z` = 55.989933,
  `orientation` = 0.000000, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.000000000, `rotation3` = 1.000000000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6942544;

-- Deadman's Dagger (515385): Silverpine Forest - Worldforged Deadman's Dagger | realm map Silverpine Forest
--   authored in game (spawns_20260924_211716.sql): moved 60.36 yd, height -2.13 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = 386.214844, `position_y` = 644.095703, `position_z` = 37.864254,
  `orientation` = 0.000000, `rotation0` = 0.000000000, `rotation1` = 0.398422790,
  `rotation2` = 0.000000000, `rotation3` = 0.917201876,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6940321;

-- Dirt Covered Gown (90325): The Dead Field - Worldforged Nightlash Gown | realm map Silverpine Forest
--   authored in game (spawns_20260924_212554.sql): moved 46.72 yd, height +1.65 yd, turned 0.781 rad (44.8 deg)
UPDATE `gameobject` SET
  `position_x` = 1057.775391, `position_y` = 1564.106445, `position_z` = 30.635445,
  `orientation` = 5.299249, `rotation0` = 0.383746573, `rotation1` = 0.550870552,
  `rotation2` = 0.350083415, `rotation3` = -0.653239470,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6940807;

-- Drowned Adventurer (101911): Lordamere Lake - AscensionWorldforged Drowned Adventurer | marker worldforge-silverpine-forest-drowned-adventurer
--   authored in game (spawns_20260924_204424.sql): moved 11.70 yd, height +5.84 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = 696.004883, `position_y` = 995.050781, `position_z` = 32.849117,
  `orientation` = 0.000000, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.000000000, `rotation3` = 1.000000000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6942539;

-- Dusty Book (90316): Fenris Isle - Worldforged Alchemy Research Notes | realm map Silverpine Forest
--   authored in game (spawns_20260924_203917.sql): moved 13.02 yd, height -4.15 yd, turned 0.100 rad (5.7 deg)
UPDATE `gameobject` SET
  `position_x` = 950.581055, `position_y` = 589.667969, `position_z` = 55.528957,
  `orientation` = 5.773443, `rotation0` = -0.696123316, `rotation1` = -0.000032136,
  `rotation2` = 0.181003139, `rotation3` = -0.694730301,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6940029;

-- Fenris Ring  (90329): Silverpine Forest - Worldforged Fenris Ring | realm map Silverpine Forest
--   authored in game (spawns_20260924_211330.sql): moved 16.46 yd, height -0.36 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = 517.060547, `position_y` = 913.590820, `position_z` = 129.205048,
  `orientation` = 4.769170, `rotation0` = -0.466895045, `rotation1` = -0.441109302,
  `rotation2` = 0.526352741, `rotation3` = -0.557121524,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6940468;

-- Floating Debris (517330): Lordamere Lake - Worldforged Lordamere Cuffs | realm map Silverpine Forest
--   authored in game (spawns_20260924_204424.sql): moved 21.88 yd, height +14.55 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = 717.496094, `position_y` = 908.356445, `position_z` = 33.416107,
  `orientation` = 3.859140, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.936328000, `rotation3` = -0.351126000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6940717;

-- Gilnean Crate (90328): North Tide's Run - Worldforged Gilnean Monocle | realm map Silverpine Forest
--   authored in game (spawns_20260924_205628.sql): moved 17.01 yd, height +7.69 yd, turned 0.541 rad (31.0 deg)
UPDATE `gameobject` SET
  `position_x` = 842.845703, `position_y` = 1883.424805, `position_z` = -0.028435,
  `orientation` = 5.742229, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = -0.267192147, `rotation3` = 0.963643273,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6940546;

-- Grimson Cloak (1345063): Deep Elem Mine - Worldforged Grimson Cloak | realm map Silverpine Forest
--   authored in game (spawns_20260924_203304.sql): moved 10.83 yd, height +2.61 yd, turned 1.207 rad (69.1 deg)
UPDATE `gameobject` SET
  `position_x` = 406.218750, `position_y` = 1003.175781, `position_z` = 110.402039,
  `orientation` = 4.974443, `rotation0` = 0.372893098, `rotation1` = 0.604825911,
  `rotation2` = 0.428289508, `rotation3` = -0.558304982,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6940579;

-- Misplaced Pitchfork (515224): Silverpine Forest - Worldforged Misplaced Pitchfork | realm map Silverpine Forest
--   authored in game (spawns_20260924_210553.sql): moved 29.67 yd, height +1.58 yd, turned 0.454 rad (26.0 deg)
UPDATE `gameobject` SET
  `position_x` = 485.431641, `position_y` = 1505.251953, `position_z` = 130.930008,
  `orientation` = 0.454273, `rotation0` = 0.181350284, `rotation1` = -0.784642716,
  `rotation2` = 0.133498463, `rotation3` = 0.577603708,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6940757;

-- Old Crossbow (518318): The Shining Strand - Worldforged Gilnean Bolter | realm map Silverpine Forest
--   authored in game (spawns_20260924_213250.sql): moved 15.53 yd, height +1.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = 1192.654297, `position_y` = 1037.694336, `position_z` = 36.297688,
  `orientation` = 4.789069, `rotation0` = 0.678510140, `rotation1` = -0.732640527,
  `rotation2` = 0.036349792, `rotation3` = -0.039249717,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6940542;

-- Old Gilnean Lance (518317): Silverpine Forest - Worldforged Gilnean Lance | realm map Silverpine Forest
--   authored in game (spawns_20260924_210327.sql): moved 17.17 yd, height +13.40 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = 208.158203, `position_y` = 1623.208984, `position_z` = 150.051987,
  `orientation` = 4.494301, `rotation0` = 0.422769046, `rotation1` = 0.526717089,
  `rotation2` = 0.575109303, `rotation3` = -0.461611018,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6940544;

-- Old Slippers (517324): Valgan's Field - Worldforged Old Valgan Slippers | realm map Silverpine Forest
--   authored in game (spawns_20260924_213403.sql): moved 2.46 yd, height -1.26 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = 967.219727, `position_y` = 1226.236328, `position_z` = 48.115337,
  `orientation` = 3.671679, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.965081000, `rotation3` = -0.261951000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6940845;

-- Ravenclaw Bone Necklace (90330): Olsen's Farthing - Worldforged Ravenclaw Bone Necklace | realm map Silverpine Forest
--   authored in game (spawns_20260924_205739.sql): moved 2.28 yd, height +0.34 yd, turned 0.145 rad (8.3 deg)
UPDATE `gameobject` SET
  `position_x` = 147.150391, `position_y` = 1519.889648, `position_z` = 115.292328,
  `orientation` = 1.463670, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.668236086, `rotation3` = 0.743949281,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6940933;

-- Rot Hide Stash (90313): Fenris Isle - AscensionWorldforged Rot Hide Stash | the realm's own object, named by the map's Silverpine drop pin
--   authored in game (spawns_20260924_203516.sql): moved 14.14 yd, height -1.49 yd, turned 0.034 rad (2.0 deg)
UPDATE `gameobject` SET
  `position_x` = 1003.254883, `position_y` = 688.657227, `position_z` = 61.855438,
  `orientation` = 0.034391, `rotation0` = -0.025427852, `rotation1` = 0.674093875,
  `rotation2` = -0.012693314, `rotation3` = -0.738098742,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6942550;

-- Sack of Pine Seeds (90323): Malden's Orchard - Worldforged Sack of Pine Seeds | realm map Silverpine Forest
--   authored in game (spawns_20260924_204509.sql): moved 8.18 yd, height +0.88 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = 1394.686523, `position_y` = 1086.188477, `position_z` = 53.455822,
  `orientation` = 2.372169, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.926907000, `rotation3` = 0.375292000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6940994;

-- Siren's Wand (517323): Ambermill - Worldforged Daggerspine Rod | realm map Silverpine Forest
--   authored in game (spawns_20260924_202536.sql): moved 137.83 yd, height +7.36 yd, turned 0.908 rad (52.0 deg)
UPDATE `gameobject` SET
  `position_x` = -197.738281, `position_y` = 918.655273, `position_z` = 67.721489,
  `orientation` = 5.375646, `rotation0` = 0.353878714, `rotation1` = 0.132287834,
  `rotation2` = -0.405869417, `rotation3` = 0.832189763,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6940291;

-- Sorcerer's Cache (835958): Ambermill - AscensionWorldforged Sorcerer's Cache
--   authored in game (spawns_20260924_202702.sql): moved 152.49 yd, height -2.31 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -86.773438, `position_y` = 802.913086, `position_z` = 66.579010,
  `orientation` = 0.000000, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.000000000, `rotation3` = 1.000000000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6942546;

-- Stolen Lordaeron Jewel (90322): The Dawning Isles - Worldforged Ancient Lordaeron Jewel | realm map Silverpine Forest
--   authored in game (spawns_20260924_212114.sql): moved 5.99 yd, height -1.00 yd, turned 0.471 rad (27.0 deg)
UPDATE `gameobject` SET
  `position_x` = 1216.356445, `position_y` = 376.037109, `position_z` = 33.600979,
  `orientation` = 1.340866, `rotation0` = -0.322891892, `rotation1` = -0.202595343,
  `rotation2` = 0.574413923, `rotation3` = 0.724392572,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6940049;

-- Thule's Curse Parchment (90320): Fenris Isle - Worldforged Thule's Curse Parchment | realm map Silverpine Forest
--   authored in game (spawns_20260924_203702.sql): moved 24.93 yd, height -10.15 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = 1008.515625, `position_y` = 693.506836, `position_z` = 77.542091,
  `orientation` = 3.834380, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.940603000, `rotation3` = -0.339508000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6941239;

-- Turtle Shell (515379): Silverpine Forest - Worldforged Old Snapjaw Shell | realm map Silverpine Forest
--   authored in game (spawns_20260924_211229.sql): moved 489.27 yd, height -147.32 yd, turned 0.195 rad (11.2 deg)
UPDATE `gameobject` SET
  `position_x` = 465.716797, `position_y` = 444.322266, `position_z` = 33.170689,
  `orientation` = 6.087917, `rotation0` = 0.582958016, `rotation1` = 0.107924468,
  `rotation2` = -0.078500305, `rotation3` = 0.801467381,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6940842;

-- Victim's Empty jar (90327): Silverpine Forest - Worldforged Poison Unguent Extract | realm map Silverpine Forest
--   authored in game (spawns_20260924_210157.sql): moved 22.17 yd, height -1.44 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = 1421.494141, `position_y` = 1929.809570, `position_z` = 9.118205,
  `orientation` = 4.593011, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.748029000, `rotation3` = -0.663666000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-24%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-24'))
WHERE `guid` = 6940904;

-- A "Fishy" Staff (95947) at (-265.3, 1936.3, -19.9) in South Tide's Run: removed in game (20260924_211815) - the editor took the object out of the client's own data
DELETE FROM `gameobject` WHERE `guid` = 6940857;

-- Codex of Divine Mending (99018) at (770.3, 1350.0, 71.5) in Silverpine Forest: removed in game (20260924_210755) - the editor took the object out of the client's own data
DELETE FROM `gameobject` WHERE `guid` = 6942543;

-- Forgotten Book of Healing (99010) at (-727.1, 1534.8, 17.7) in The Greymane Wall: removed in game (20260924_212813) - the editor took the object out of the client's own data
DELETE FROM `gameobject` WHERE `guid` = 6942540;

-- Heavy Shovel (515383) at (546.4, 1938.0, -11.5) in North Tide's Run: removed in game (20260924_205321) - the editor took the object out of the client's own data
DELETE FROM `gameobject` WHERE `guid` = 6940632;

-- Hidden Ring (97100) at (490.4, 2190.0, -63.7) in North Tide's Run: removed in game (20260924_204752) - the editor took the object out of the client's own data
DELETE FROM `gameobject` WHERE `guid` = 6940316;

-- Ivar's Femur (90324) at (1276.9, 1284.1, 53.8) in The Ivar Patch: removed in game (20260924_213151) - the editor took the object out of the client's own data
DELETE FROM `gameobject` WHERE `guid` = 6940663;

-- Light and Shadow Vol: 1 (100011) at (-21.8, 1354.2, 60.9) in Silverpine Forest: removed in game (20260924_210719) - the editor took the object out of the client's own data
DELETE FROM `gameobject` WHERE `guid` = 6942541;

-- Maddening Aura (101913) at (-379.3, 1659.1, 12.2) in Pyrewood Village: removed in game (20260924_210041) - the editor took the object out of the client's own data
DELETE FROM `gameobject` WHERE `guid` = 6942548;

-- Old Shoulderpad (517314) at (994.2, 552.0, 37.0) in Fenris Isle: removed in game (20260924_204111) - the editor took the object out of the client's own data
DELETE FROM `gameobject` WHERE `guid` = 6940754;

-- Rot Hide Supplies (90317) at (994.2, 594.0, 55.2) in Fenris Isle: removed in game (20260924_204036) - the editor took the object out of the client's own data
DELETE FROM `gameobject` WHERE `guid` = 6940977;

-- Shadow Portal (111017) at (-167.3, 770.4, 65.8) in Ambermill: removed in game (20260924_203136) - the editor took the object out of the client's own data
DELETE FROM `gameobject` WHERE `guid` = 6942545;

-- The Law of Light (111004) at (-376.5, 1116.3, 84.2) in Silverpine Forest: removed in game (20260924_211035) - the editor took the object out of the client's own data
DELETE FROM `gameobject` WHERE `guid` = 6942547;

-- Well Kept Hatchet (95946) at (686.4, 2064.0, -26.3) in North Tide's Run: removed in game (20260924_205051) - the editor took the object out of the client's own data
DELETE FROM `gameobject` WHERE `guid` = 6940939;

-- Old Shoulderpad (517314): a placement the realm authored by hand (spawns_20260924_204157.sql), guid 6960022 allocated here
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960022, 517314, 0, 0, 0, 1, 1, 1018.583984, 708.822266, 62.598858, 0.000000, 0.000000000, 0.000000000, 0.000000000, 1.000000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Old Shoulderpad | in-game placement 2026-09-24 (spawns_20260924_204157.sql)');

-- Hidden Ring (97100): a placement the realm authored by hand (spawns_20260924_204829.sql), guid 6960023 allocated here
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960023, 97100, 0, 0, 0, 1, 1, 418.964844, 1843.153320, 12.565743, 0.000000, 0.000000000, 0.000000000, 0.000000000, 1.000000000, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Hidden Ring | in-game placement 2026-09-24 (spawns_20260924_204829.sql)');

-- Well Kept Hatchet (95946): a placement the realm authored by hand (spawns_20260924_205127.sql), guid 6960024 allocated here
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960024, 95946, 0, 0, 0, 1, 1, 848.246094, 1874.875000, 2.874697, 3.622380, 0.236585572, -0.599312602, 0.742764911, -0.182076793, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Well Kept Hatchet | in-game placement 2026-09-24 (spawns_20260924_205127.sql)');

-- Heavy Shovel (515383): a placement the realm authored by hand (spawns_20260924_205402.sql), guid 6960025 allocated here
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960025, 515383, 0, 0, 0, 1, 1, 1293.766602, 1963.725586, 22.910549, 0.311738, 0.105958014, -0.659069352, 0.115587617, 0.735554207, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged Heavy Shovel | in-game placement 2026-09-24 (spawns_20260924_205402.sql)');

-- A "Fishy" Staff (95947): a placement the realm authored by hand (spawns_20260924_211923.sql), guid 6960026 allocated here
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960026, 95947, 0, 0, 0, 1, 1, 1183.590820, 1043.359375, 35.010971, 0.000000, 0.000000000, 0.860950522, 0.000000000, 0.508688704, 0, 0, 1, 'worldforged_pickup', 'AscensionWorldforged A "Fishy" Staff | in-game placement 2026-09-24 (spawns_20260924_211923.sql)');

-- Objects the changesets also touch, which are not this module's and are left untouched:
--   Strange Lockbox (guid 27813, script '')
--   Cozy Fire (guid 35359, script '')
--   Wooden Chair (guid 35362, script '')
--   Cozy Fire (guid 35363, script '')
--   Wooden Chair (guid 35367, script '')
--   High Back Chair (guid 35368, script '')
--   High Back Chair (guid 35369, script '')
--   Cozy Fire (guid 35376, script '')
--   Cozy Fire (guid 35380, script '')
--   Wooden Chair (guid 35382, script '')
--   Wooden Chair (guid 35385, script '')
--   Wooden Chair (guid 35386, script '')
--   High Back Chair (guid 35391, script '')
--   Cozy Fire (guid 35392, script '')
--   Ambermill Strongbox (guid 35412, script '')
--   Bruiseweed (guid 201979, script '')
--   Bruiseweed (guid 201995, script '')
--   Mageroyal (guid 201876, script '')

COMMIT;
