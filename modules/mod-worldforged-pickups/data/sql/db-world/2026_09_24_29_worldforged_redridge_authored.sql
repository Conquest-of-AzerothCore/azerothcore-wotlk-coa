-- ----------------------------------------------------------------------------
-- Worldforged pickups: the placements and rotations authored in game
-- ----------------------------------------------------------------------------
-- Every row below is a placement the realm authored by hand in the map editor (Noggit,
-- changed in the client's own data): the editor writes one changeset per save, and this
-- file is those changesets read in the order they were written, the last write to a row
-- winning.  Nothing here is inferred: position_x/y/z and the rotation quaternion are
-- what the editor emitted, down to the digit.
--
-- 25 rows of this module were moved and/or turned, 0 were removed, and
-- 4 placements were added.  The orientation column is written as the yaw the
-- quaternion represents, which
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

-- Adventurer's Cloak (90264): Three Corners - Worldforged Three Corner Cape | realm map Redridge Mountains | in-game placement 2026-09-23
--   authored in game (spawns_20260924_123016.sql): moved 0.00 yd, height -0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9966.873047, `position_y` = -2003.992188, `position_z` = 88.073463,
  `orientation` = 6.204959, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.039103000, `rotation3` = -0.999235000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6941231;

-- Aqualon's Core (90268): Lake Everstill - Worldforged Aqualon's Bolt | realm map Redridge Mountains | in-game placement 2026-09-23
--   authored in game (spawns_20260924_120809.sql): moved 0.01 yd, height -0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9390.763672, `position_y` = -2882.826172, `position_z` = 34.545856,
  `orientation` = 1.649110, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.734246000, `rotation3` = 0.678884000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940068;

-- Blackrock Armor Supplies (90259): Render's Camp - Worldforged Blackrock Summoner's Garb | realm map Redridge Mountains | in-game placement 2026-09-23
--   authored in game (spawns_20260924_121922.sql): moved 0.00 yd, height -0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -8707.779297, `position_y` = -2369.664062, `position_z` = 157.204590,
  `orientation` = 1.923511, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.820197000, `rotation3` = 0.572081000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940128;

-- Blackrock Render (90261): Render's Valley - Worldforged Blackrock Render | realm map Redridge Mountains | in-game placement 2026-09-23
--   authored in game (spawns_20260924_122103.sql): moved 0.00 yd, height -0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9825.701172, `position_y` = -3261.689453, `position_z` = 62.110157,
  `orientation` = 3.775640, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.950167000, `rotation3` = -0.311740000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940126;

-- Blackrock Smuggled Goods (90262): Redridge Mountains - Worldforged Three Corner Coil | realm map Redridge Mountains | in-game placement 2026-09-23
--   authored in game (spawns_20260924_121759.sql): moved 0.00 yd, height +0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9598.951172, `position_y` = -3024.199219, `position_z` = 61.330246,
  `orientation` = 4.328161, `rotation0` = -0.053369233, `rotation1` = 0.035988084,
  `rotation2` = 0.827389542, `rotation3` = -0.557927530,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6941234;

-- Burning Scales of the Black Dragonflight Matriarch (90280): Redridge Mountains - Worldforged Dragon Matriarch Cloak | realm map Redridge Mountains | in-game placement 2026-09-23
--   authored in game (spawns_20260924_121600.sql): moved 0.00 yd, height +0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9021.841797, `position_y` = -2508.349609, `position_z` = 130.207291,
  `orientation` = 4.440360, `rotation0` = 0.060471887, `rotation1` = 0.079648713,
  `rotation2` = 0.792464004, `rotation3` = -0.601664388,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940377;

-- Capsized Rifle (254548): Redridge Mountains - Worldforged Rusty Redridge Rifle | realm map Redridge Mountains | in-game placement 2026-09-23
--   authored in game (spawns_20260924_121415.sql): moved 0.00 yd, height +0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9387.847656, `position_y` = -2020.666016, `position_z` = 58.695919,
  `orientation` = 0.710009, `rotation0` = 0.011450986, `rotation1` = 0.822610752,
  `rotation2` = -0.197603907, `rotation3` = -0.533041388,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940991;

-- Chocked Fish Corpse (90263): Three Corners - Worldforged Three Corner Carp | realm map Redridge Mountains | in-game placement 2026-09-23
--   authored in game (spawns_20260924_122940.sql): moved 0.00 yd, height +0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9912.460938, `position_y` = -1976.167969, `position_z` = 48.868633,
  `orientation` = 4.493140, `rotation0` = -0.122205994, `rotation1` = -0.152434493,
  `rotation2` = 0.765187560, `rotation3` = -0.613447160,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6941232;

-- Free Book (254551): Redridge Mountains - Worldforged Old War Tome | realm map Redridge Mountains | in-game placement 2026-09-23
--   authored in game (spawns_20260924_121514.sql): moved 0.00 yd, height -0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9546.628906, `position_y` = -2234.027344, `position_z` = 88.093781,
  `orientation` = 3.000790, `rotation0` = -0.045918623, `rotation1` = -0.003238074,
  `rotation2` = 0.996465425, `rotation3` = 0.070268422,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940849;

-- Gnollish Headwear (254540): Redridge Canyons - Worldforged Gnoll Cap | realm map Redridge Mountains | in-game placement 2026-09-23
--   authored in game (spawns_20260924_121237.sql): moved 0.00 yd, height +0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9035.105469, `position_y` = -2410.359375, `position_z` = 130.407394,
  `orientation` = 0.513749, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.254059000, `rotation3` = 0.967189000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940553;

-- Gnollish Shoulderpad (254539): Three Corners - Worldforged Gnoll Crafted Spaulder | realm map Redridge Mountains | in-game placement 2026-09-23
--   authored in game (spawns_20260924_122801.sql): moved 0.00 yd, height -0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9485.773438, `position_y` = -1939.099609, `position_z` = 79.891487,
  `orientation` = 5.637940, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.317055000, `rotation3` = -0.948407000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940555;

-- Gnollish Sword (254545): Lake Everstill - Worldforged Mongrel Blade | realm map Redridge Mountains | in-game placement 2026-09-23
--   authored in game (spawns_20260924_120628.sql): moved 0.00 yd, height +0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9593.769531, `position_y` = -2510.306641, `position_z` = 60.582214,
  `orientation` = 1.000310, `rotation0` = 0.255013571, `rotation1` = -0.694935597,
  `rotation2` = -0.322425305, `rotation3` = -0.589978405,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940762;

-- Ilgalar Stolen Neckpiece (90258): Lake Everstill - Worldforged Stolen Ilgalar Neckpiece | realm map Redridge Mountains | in-game placement 2026-09-23
--   authored in game (spawns_20260924_121113.sql): moved 0.00 yd, height -0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9589.347656, `position_y` = -2609.628906, `position_z` = 57.942394,
  `orientation` = 5.647306, `rotation0` = -0.127398369, `rotation1` = -0.305464616,
  `rotation2` = -0.294992201, `rotation3` = 0.896348496,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6941149;

-- Improvised Murloc Hammer (254550): Lake Everstill - Worldforged Tidecaller's Hammer | realm map Redridge Mountains | in-game placement 2026-09-23
--   authored in game (spawns_20260924_121113.sql): moved 0.01 yd, height +0.00 yd, turned 0.000 rad (0.0 deg)
--   the changeset's own orientation column said 4.7728 while its quaternion represents 3.3794; the quaternion is written, and the column follows it
UPDATE `gameobject` SET
  `position_x` = -9326.785156, `position_y` = -2829.328125, `position_z` = 69.385742,
  `orientation` = 3.379365, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = -0.992941374, `rotation3` = 0.118606192,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6941249;

-- Lexicon of Azora - Part II: Warlock Rituals (90234): Tower of Ilgalar - Worldforged Ring of the Lexicon | realm map Redridge Mountains | in-game placement 2026-09-23
--   authored in game (spawns_20260924_123141.sql): moved 0.00 yd, height +0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9295.910156, `position_y` = -3311.972656, `position_z` = 151.570190,
  `orientation` = 3.772935, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.950588173, `rotation3` = -0.310454707,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940966;

-- Red Mage Wand (518315): Three Corners - Worldforged Red Mage Wand | realm map Redridge Mountains | in-game placement 2026-09-23
--   authored in game (spawns_20260924_122857.sql): moved 0.00 yd, height -0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9673.943359, `position_y` = -1962.361328, `position_z` = 100.856743,
  `orientation` = 3.428804, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.989706432, `rotation3` = -0.143112468,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940944;

-- Redwood Buckler (254544): Redridge Mountains - Worldforged Old Redridge Buckler | realm map Redridge Mountains | in-game placement 2026-09-23
--   authored in game (spawns_20260924_121847.sql): moved 0.01 yd, height -0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9622.998047, `position_y` = -3478.214844, `position_z` = 123.518654,
  `orientation` = 1.976572, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.835084424, `rotation3` = 0.550121809,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940839;

-- Reverent Ring (254506): Lake Everstill - Worldforged Reverence of the Ancient Ones | realm map Redridge Mountains | in-game placement 2026-09-23
--   authored in game (spawns_20260924_120434.sql): moved 0.00 yd, height +0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9251.914062, `position_y` = -2456.310547, `position_z` = 53.821815,
  `orientation` = 4.648229, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.729423000, `rotation3` = -0.684063000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940955;

-- Ribchaser's Loop (1345113): Three Corners - Worldforged Ribchaser's Loop | realm map Redridge Mountains | in-game placement 2026-09-23
--   authored in game (spawns_20260924_122738.sql): moved 0.00 yd, height -0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9465.212891, `position_y` = -1902.232422, `position_z` = 83.453896,
  `orientation` = 1.771389, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = -0.774354498, `rotation3` = -0.632752015,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940958;

-- Sunken Claymore (254546): Lake Everstill - Worldforged Everstill Claymore | realm map Redridge Mountains | in-game placement 2026-09-23
--   authored in game (spawns_20260924_120525.sql): moved 0.01 yd, height +0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9356.544922, `position_y` = -2503.451172, `position_z` = 14.839638,
  `orientation` = 3.183849, `rotation0` = -0.643052700, `rotation1` = 0.110768130,
  `rotation2` = 0.757599736, `rotation3` = -0.016008979,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940447;

-- Tharil'zun's Extra Boots (254543): Stonewatch - Worldforged Tharil'zun's Trek Boots | realm map Redridge Mountains | in-game placement 2026-09-23
--   authored in game (spawns_20260924_122140.sql): moved 0.00 yd, height +0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9444.007812, `position_y` = -3080.503906, `position_z` = 136.674149,
  `orientation` = 1.352370, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.625822000, `rotation3` = 0.779966000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6941206;

-- Unclaimed Sack (95657): Render's Valley - Worldforged Unclaimed Sack | realm map Swamp of Sorrows | in-game placement 2026-09-23
--   authored in game (spawns_20260924_122026.sql): moved 0.00 yd, height -0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9730.046875, `position_y` = -3181.417969, `position_z` = 58.444897,
  `orientation` = 0.000000, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.000000000, `rotation3` = 1.000000000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6941289;

-- Unique Pole (90265): Stonewatch Falls - Worldforged Mrrrllrl Stick | realm map Redridge Mountains | in-game placement 2026-09-23
--   authored in game (spawns_20260924_122634.sql): moved 0.00 yd, height +0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9445.605469, `position_y` = -3333.310547, `position_z` = 7.982894,
  `orientation` = 2.895041, `rotation0` = -0.640527946, `rotation1` = -0.079364173,
  `rotation2` = 0.758026253, `rotation3` = 0.093922720,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940775;

-- Web-Covered Belt (254541): Alther's Mill - Worldforged Alther's Chain Wrap | realm map Redridge Mountains | in-game placement 2026-09-23
--   authored in game (spawns_20260924_120131.sql): moved 0.01 yd, height +0.00 yd, turned 0.000 rad (0.0 deg)
UPDATE `gameobject` SET
  `position_x` = -9233.937500, `position_y` = -2696.644531, `position_z` = 90.124619,
  `orientation` = 0.426370, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = 0.211574000, `rotation3` = 0.977362000,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6940036;

-- Yowler's Howl (90256): Redridge Canyons - Worldforged Yowler's Howl | realm map Redridge Mountains | in-game placement 2026-09-23
--   authored in game (spawns_20260924_121237.sql): moved 0.01 yd, height -0.00 yd, turned 0.000 rad (0.0 deg)
--   the changeset's own orientation column said 6.2522 while its quaternion represents 3.7880; the quaternion is written, and the column follows it
UPDATE `gameobject` SET
  `position_x` = -8885.673828, `position_y` = -2169.746094, `position_z` = 133.186569,
  `orientation` = 3.788020, `rotation0` = 0.000000000, `rotation1` = 0.000000000,
  `rotation2` = -0.948219561, `rotation3` = 0.317615591,
  `Comment` = IF(`Comment` LIKE '%in-game placement 2026-09-23%', `Comment`,
                      CONCAT(IFNULL(`Comment`, ''), ' | in-game placement 2026-09-23'))
WHERE `guid` = 6941362;

-- Temporary Spawned Murloc Hut 02 (186743): a placement the realm authored by hand (spawns_20260924_122634.sql), written here on the guid it already had, 6960012
--   a prop, not a pickup (its template is not a chest): it carries no script, so it does not sparkle and hands out nothing
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960012, 186743, 0, 0, 0, 1, 1, -9442.939453, -3337.685547, 1.203736, 2.853480, 0.000000000, 0.000000000, 0.989641835, 0.143558485, 0, 0, 1, '', 'AscensionWorldforged Temporary Spawned Murloc Hut 02 | in-game placement 2026-09-23 (spawns_20260924_122634.sql)');

-- Temporary Spawned Murloc Hut 01 (186742): a placement the realm authored by hand (spawns_20260924_122634.sql), written here on the guid it already had, 6960013
--   a prop, not a pickup (its template is not a chest): it carries no script, so it does not sparkle and hands out nothing
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960013, 186742, 0, 0, 0, 1, 1, -9453.513672, -3347.062500, 4.559220, 3.285214, 0.000000000, 0.000000000, -0.997422709, 0.071749140, 0, 0, 1, '', 'AscensionWorldforged Temporary Spawned Murloc Hut 01 | in-game placement 2026-09-23 (spawns_20260924_122634.sql)');

-- Temporary Spawned Murloc Hut 01 (186742): a placement the realm authored by hand (spawns_20260924_122634.sql), written here on the guid it already had, 6960014
--   a prop, not a pickup (its template is not a chest): it carries no script, so it does not sparkle and hands out nothing
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960014, 186742, 0, 0, 0, 1, 1, -9465.380859, -3340.578125, 6.080458, 2.342103, 0.000000000, 0.000000000, -0.921160333, -0.389183300, 0, 0, 1, '', 'AscensionWorldforged Temporary Spawned Murloc Hut 01 | in-game placement 2026-09-23 (spawns_20260924_122634.sql)');

-- Murloc Cage (182164): a placement the realm authored by hand (spawns_20260924_122634.sql), written here on the guid it already had, 6960015
--   a prop, not a pickup (its template is not a chest): it carries no script, so it does not sparkle and hands out nothing
REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960015, 182164, 0, 0, 0, 1, 1, -9461.074219, -3340.980469, 6.097830, 5.691204, 0.000000000, 0.000000000, -0.291687625, 0.956513633, 0, 0, 1, '', 'AscensionWorldforged Murloc Cage | in-game placement 2026-09-23 (spawns_20260924_122634.sql)');

-- Objects the changesets also touch, which are not this module's and are left untouched:
--   Solid Chest (guid 18583, script '')

-- Gypsy Wagon (178666, guid 6960011): a scenery object the editor added beside the Traveler's
-- Forest Cloak, and not a chest (its template is type 5).  It was standing with this module's
-- script, which made a prop sparkle and open an empty loot window; the script is taken off it,
-- the way the props of the hidden chests carry none.
UPDATE `gameobject` SET `ScriptName` = '' WHERE `guid` = 6960011;

COMMIT;
