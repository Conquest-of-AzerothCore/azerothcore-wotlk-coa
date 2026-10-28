-- ----------------------------------------------------------------------------
-- Worldforged pickups: Tirisfal Glades restored and audited in game (final)
-- ----------------------------------------------------------------------------
-- The zone's pickups are reconciled against the realm map marker by marker and then
-- walked by hand in the map editor; this file is the zone's final verified state and
-- supersedes every earlier state of the zone, so a database converges from any of them.
--
--   * the marker pass moves four placements onto the marker of the object's own name
--     (Nightweb Spider Egg 4.2 yd, Stashed Goods 5.3 yd, Rattlecage Cauldron 7.4 yd,
--     Oathblade 7.5 yd, each keeping the height the realm's own record gives it) and
--     takes five extra placings out (a Quivering Web and a Sturdy Arrow far from any
--     marker, and three Apothecary's Lantern rows whose marker the object of that name
--     already answers);
--   * the pair the undead starting ground kept for its own starting NPCs is restored
--     as the realm recorded it: Joshua's Cherry Pie (90641) with the loot row its
--     marker is named after, the Cherry Pie prop (90635) beside it, and Maquel's
--     Fallen Water Pouch (90642, empty, as the realm kept it);
--   * the review takes twelve stands out - two duplicates whose surviving stands are
--     the Ceremonial Mace (6940229) and Quivering Web (6940921) rows, and ten the
--     review's own judgement;
--   * the in-game audit of 2026-09-26 then walked the zone and left 41 sheet pickups
--     at the spots it verified, with the full authored quaternions the editor emitted,
--     re-creating three of them (Long Fishing Spear, Interloper's Loop and Fallen
--     Hardwood Plank) on the guids its own editor allocates, 6960206-6960208; six
--     further stands the audit marked red are taken out; and four Undercity creatures
--     stand where the audit verified them;
--   * scenery the audit nudged is moved without its script or comment being touched,
--     so the module's pickup census counts only what it should.
--
-- Idempotent; apply to acore_world.
-- ----------------------------------------------------------------------------


START TRANSACTION;

-- ---- the marker pass: four placements onto the markers of their own names ------------


-- Nightweb Spider Egg (515406): was 2292.5 -925.7, 4.2 yd off the marker
UPDATE `gameobject` SET `position_x` = 2294.1000, `position_y` = -929.6000, `position_z` = 76.0680 WHERE `guid` = 6940370;
-- Stashed Goods (95671): was 1987.3 1592.2, 5.3 yd off the marker
UPDATE `gameobject` SET `position_x` = 1984.0000, `position_y` = 1596.3000, `position_z` = 82.3260 WHERE `guid` = 6940863;
-- Rattlecage Cauldron (95609): was 2052.7 1526.9, 7.4 yd off the marker
UPDATE `gameobject` SET `position_x` = 2053.3000, `position_y` = 1519.5000, `position_z` = 73.6975 WHERE `guid` = 6940567;
-- Oathblade (520055): was 1778.8 1973.6, 7.5 yd off the marker
UPDATE `gameobject` SET `position_x` = 1782.1000, `position_y` = 1980.3000, `position_z` = 125.4280 WHERE `guid` = 6940211;


-- ---- the marker pass: five extra placings out -----------------------------------------


-- Quivering Web (254166): no marker of any page plots it at 3083.8 1632.4
DELETE FROM `gameobject` WHERE `guid` = 6930039;
-- Sturdy Arrow (520051): no marker of any page plots it at 2023.6 1712.1
DELETE FROM `gameobject` WHERE `guid` = 6930060;
-- Apothecary's Lantern (1345004): no marker of any page plots it at 2631.8 1045.1
DELETE FROM `gameobject` WHERE `guid` = 6930062;
-- Apothecary's Lantern (1345005): no marker of any page plots it at 2631.8 1045.1
DELETE FROM `gameobject` WHERE `guid` = 6930063;
-- Apothecary's Lantern (1345006): no marker of any page plots it at 2631.8 1045.1
DELETE FROM `gameobject` WHERE `guid` = 6930064;


-- ---- the marker pass: the starting ground's pair, restored as the realm recorded it ---


REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`) VALUES
(90641, 3, 980926, 'Joshua''s Cherry Pie', '', 'Looting', '', 1.00, 1689, 90641, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'worldforged_pickup');

REPLACE INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(90641, 694542, 0, 100.0000, 0, 1, 0, 1, 1, 'AscensionWorldforged Joshua''s Cherry Pie: the marker is named for this item (the realm''s own chest 90641 stands here)');

REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`) VALUES
(90642, 3, 1033132, 'Maquel''s Fallen Water Pouch', '', 'Looting', '', 1.00, 1689, 90642, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 'worldforged_pickup');

REPLACE INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `ScriptName`) VALUES
(90635, 5, 5493, 'Cherry Pie prop', '', 'Looting', '', 3.00, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '');


-- ---- the review: twelve stands taken out ----------------------------------------------


DELETE FROM `gameobject` WHERE `guid` IN (6940599, 6941082, 6940520, 6940147, 6941275, 6940877, 6941107, 6940292, 6941342, 6941025, 6940134, 6960086);


-- ---- the audit's own marks: six further stands taken out -------------------------------


DELETE FROM `gameobject` WHERE `guid` IN (6941097, 6940917, 6940331, 6940100, 6940885, 6941296);


-- ---- the audit's re-created stands: the old guids come out -----------------------------


-- the audit deleted and re-created these three pickups; the old stands come out
DELETE FROM `gameobject` WHERE `guid` IN (6940710, 6940656, 6940456);


-- ---- the audit's final rows: every pickup stands where the editor left it --------------


-- scenery (entry 192835): the audit nudged this scenery spawn; its script and comment are left as the base data wrote them

UPDATE `gameobject` SET `position_x` = 2044.38, `position_y` = -520.99, `position_z` = 46.0141, `orientation` = 3.18581, `rotation0` = 0, `rotation1` = 0, `rotation2` = -0.999756, `rotation3` = 0.0221046 WHERE `guid` = 364 AND `id` = 192835;

-- Forge (entry 52175): the audit nudged this scenery spawn; its script and comment are left as the base data wrote them

UPDATE `gameobject` SET `position_x` = 1392.38, `position_y` = 147.967, `position_z` = -62.4123, `orientation` = 1.92859, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.821647, `rotation3` = 0.569997 WHERE `guid` = 44916 AND `id` = 52175;

-- Anvil (entry 40303): the audit nudged this scenery spawn; its script and comment are left as the base data wrote them

UPDATE `gameobject` SET `position_x` = 1395.12, `position_y` = 140.068, `position_z` = -62.5432, `orientation` = 0.733036, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.358367, `rotation3` = 0.933581 WHERE `guid` = 44988 AND `id` = 40303;

-- scenery (entry 1731): the audit nudged this scenery spawn; its script and comment are left as the base data wrote them

UPDATE `gameobject` SET `position_x` = 2440.95, `position_y` = 266.553, `position_z` = 29.7319, `orientation` = 3.73501, `rotation0` = 0, `rotation1` = 0, `rotation2` = -0.956305, `rotation3` = 0.292372 WHERE `guid` = 201656 AND `id` = 1731;

-- Abandoned Hammer (6940006): stood at 1938.8 1546.6 87.3; moved 12.0 yd to the verified spot

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6940006, 254163, 0, 0, 0, 1, 1, 1939.83, 1535.35, 91.1806, 4.75247, -0.516299, 0.537419, 0.461952, -0.480849, 0, 0, 1, 'worldforged_pickup', 'Worldforged Abandoned Hammer | realm map Tirisfal Glades');

-- Murloc Plunder (6940011): stood at 3053.6 -265.1 1.4; moved 23.5 yd to the verified spot

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6940011, 95806, 0, 0, 0, 1, 1, 3056.59, -241.994, 4.15526, 2.68648, 0, 0, 0.974221, 0.225598, 0, 0, 1, 'worldforged_pickup', 'Worldforged Murloc Plunder | realm map Tirisfal Glades');

-- Agamand Dresser (6940022): stood at 2750.8 804.7 114.3; moved 5.3 yd to the verified spot

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6940022, 515370, 0, 0, 0, 1, 1, 2752.52, 802.985, 119.078, 4.36135, 0.000000053732, -0.0000000304259, 0.819716, -0.57277, 0, 0, 1, 'worldforged_pickup', 'Worldforged Agamand Dresser | realm map Tirisfal Glades');

-- Old Crossbow (6940024): stood at 2933.1 954.7 122.9; moved 0.7 yd to the verified spot

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6940024, 517351, 0, 0, 0, 1, 1, 2932.54, 954.683, 122.428, 0.60233, 0.810888, -0.251872, 0.156689, 0.504451, 0, 0, 1, 'worldforged_pickup', 'Worldforged Old Crossbow | realm map Tirisfal Glades');

-- Agamand Walking Stick (6940025): stood at 3042.5 646.6 93.7; moved 34.1 yd to the verified spot

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6940025, 515392, 0, 0, 0, 1, 1, 3041.37, 646.57, 59.6374, 2.73894, 0.480185, -0.765055, 0.420417, 0.0858028, 0, 0, 1, 'worldforged_pickup', 'Worldforged Agamand Walking Stick | realm map Tirisfal Glades');

-- Apothecary's Lantern (6940062): stood at 2639.3 1045.1 101.0; moved 36.7 yd to the verified spot

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6940062, 1345003, 0, 0, 0, 1, 1, 2673.77, 1044.1, 113.439, 0.618034, 0, 0, 0.304122, 0.952633, 0, 0, 1, 'worldforged_pickup', 'Worldforged Apothecary''s Lantern | realm map Tirisfal Glades');

-- Burial Wraps (6940203): stood at 1965.9 1614.3 82.3; moved 7.4 yd to the verified spot

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6940203, 95610, 0, 0, 0, 1, 1, 1966.14, 1612.54, 89.413, 5.74076, 0.0507565, -0.182535, 0.263048, -0.945997, 0, 0, 1, 'worldforged_pickup', 'Worldforged Burial Wraps | realm map Tirisfal Glades');

-- Butchery Blade (6940210): stood at 2481.1 10.5 25.4; moved 12.2 yd to the verified spot

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6940210, 95805, 0, 0, 0, 1, 1, 2485.38, 21.7031, 27.6361, 1.66375, -0.541587, -0.503164, 0.497798, 0.453549, 0, 0, 1, 'worldforged_pickup', 'Worldforged Butchery Blade | realm map Tirisfal Glades');

-- Oathblade (6940211): stood at 1778.8 1973.6 139.0; moved 15.8 yd to the verified spot

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6940211, 520055, 0, 0, 0, 1, 1, 1784.53, 1980.49, 126.074, 0.2883, 0.0615716, 0.424174, 0.129787, 0.894115, 0, 0, 1, 'worldforged_pickup', 'Worldforged Oathblade | realm map Tirisfal Glades');

-- Captain's Shield (6940215): stood at 3079.8 -563.3 127.2; moved 0.3 yd to the verified spot

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6940215, 95804, 0, 0, 0, 1, 1, 3079.8, -563.58, 127.179, 3.72449, -0.0909062, -0.310791, 0.906222, -0.271859, 0, 0, 1, 'worldforged_pickup', 'Worldforged Captain''s Shield | realm map Tirisfal Glades');

-- Casket Lid (6940222): stood at 1797.2 1966.8 148.6; moved 9.6 yd to the verified spot

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6940222, 520062, 0, 0, 0, 1, 1, 1802, 1964.11, 156.526, 4.75502, 0.251692, 0.217121, -0.652534, 0.680962, 0, 0, 1, 'worldforged_pickup', 'Worldforged Casket Lid | realm map Tirisfal Glades');

-- Ceremonial Mace (6940229): stood at 2044.8 -521.2 44.6; moved 1.5 yd to the verified spot

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6940229, 515372, 0, 0, 0, 1, 1, 2043.62, -521.955, 44.1577, 0.850134, 0.473896, -0.380675, 0.32745, 0.723385, 0, 0, 1, 'worldforged_pickup', 'Worldforged Ceremonial Mace | realm map Tirisfal Glades');

-- Coastline Vest (6940259): stood at 3053.6 5.9 -1.0; moved 2.2 yd to the verified spot

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6940259, 1345025, 0, 0, 0, 1, 1, 3051.71, 7.01562, -1.02229, 1.03038, 0, 0, 0.4927, 0.870199, 0, 0, 1, 'worldforged_pickup', 'Worldforged Coastline Vest | realm map Tirisfal Glades');

-- Decayed Sharpshot (6940332): stood at 1941.8 1989.3 129.8; moved 26.8 yd to the verified spot

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6940332, 520047, 0, 0, 0, 1, 1, 1941.99, 1989.43, 156.585, 1.32699, 0.195018, -0.388011, 0.554772, 0.709679, 0, 0, 1, 'worldforged_pickup', 'Worldforged Decayed Sharpshot | realm map Tirisfal Glades');

-- Edwin's Chest (6940418): the map draws the chest's own name on the Western Plaguelands page and the item it hands out on this zone's page; the audit moved the chest to its own mark 329.9 yd into the zone

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6940418, 517347, 0, 0, 0, 1, 1, 1920.04, -162.574, 39.0175, 3.29072, 0, 0, 0.997221, -0.074495, 0, 0, 1, 'worldforged_pickup', 'Worldforged Edwin''s Chest | realm map Tirisfal Glades');

-- Empty Satchel (6940434): stood at 2245.2 743.7 34.9; moved 0.9 yd to the verified spot

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6940434, 1345048, 0, 0, 0, 1, 1, 2245.58, 744.45, 34.539, 5.66611, 0, 0, 0.303666, -0.952779, 0, 0, 1, 'worldforged_pickup', 'Worldforged Empty Satchel | realm map Tirisfal Glades');

-- Garren's Pitchfork (6940527): stood at 2834.6 409.4 22.0; moved 0.5 yd to the verified spot

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6940527, 95698, 0, 0, 0, 1, 1, 2834.3, 409.746, 21.7674, 0.624764, 0.135653, 0.420037, 0.275767, 0.853885, 0, 0, 1, 'worldforged_pickup', 'Worldforged Garren''s Pitchfork | realm map Tirisfal Glades');

-- Shallow Grave (6940534): stood at 2330.5 457.7 35.1; moved 1.2 yd to the verified spot

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6940534, 517354, 0, 0, 0, 1, 1, 2330.45, 456.619, 35.5951, 6.26328, 0, 0, -0.0099548, 0.99995, 0, 0, 1, 'worldforged_pickup', 'Worldforged Shallow Grave | realm map Tirisfal Glades');

-- Forgotten Shovel (6940570): stood at 1878.5 1045.1 29.1; moved 23.8 yd to the verified spot

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6940570, 515369, 0, 0, 0, 1, 1, 1862.09, 1062.39, 29.7695, 4.44857, -0.656195, -0.116354, 0.591956, -0.453274, 0, 0, 1, 'worldforged_pickup', 'Worldforged Forgotten Shovel | realm map Tirisfal Glades');

-- Unearthed Ring (6940600): stood at 2541.4 548.1 12.7; moved 6.9 yd to the verified spot

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6940600, 95801, 0, 0, 0, 1, 1, 2548.25, 547.9, 12.3394, 4.66981, 0, 0, 0.721999, -0.691894, 0, 0, 1, 'worldforged_pickup', 'Worldforged Unearthed Ring | realm map Tirisfal Glades');

-- Rusty Shotgun (6940734): stood at 2895.4 372.8 28.9; moved 22.5 yd to the verified spot

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6940734, 517353, 0, 0, 0, 1, 1, 2916.88, 377.865, 33.1411, 4.69091, -0.0594811, 0.072107, 0.71153, -0.69641, 0, 0, 1, 'worldforged_pickup', 'Worldforged Rusty Shotgun | realm map Tirisfal Glades');

-- Forsaken Cart Crate (6940805): stood at 2051.8 51.1 35.7; moved 16.1 yd to the verified spot

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6940805, 517352, 0, 0, 0, 1, 1, 2042.55, 64.25, 35.5593, 2.05443, 0, 0, 0.855862, 0.517204, 0, 0, 1, 'worldforged_pickup', 'Worldforged Forsaken Cart Crate | realm map Tirisfal Glades');

-- Wheel (6940848): stood at 2093.1 636.2 35.1; moved 1.1 yd to the verified spot

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6940848, 515345, 0, 0, 0, 1, 1, 2093.08, 635.131, 34.7431, 6.09192, -0.724034, -0.0694532, 0.0655287, -0.683123, 0, 0, 1, 'worldforged_pickup', 'Worldforged Wheel | realm map Tirisfal Glades');

-- Barnaby's Booties (6940852): stood at 2300.4 -61.8 7.2; moved 17.6 yd to the verified spot

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6940852, 517349, 0, 0, 0, 1, 1, 2298.55, -54.0508, 22.8818, 0.22588, 0, 0, 0.1127, 0.993629, 0, 0, 1, 'worldforged_pickup', 'Worldforged Barnaby''s Booties | realm map Tirisfal Glades');

-- Leaning Greatsword (6940898): stood at 2149.7 1135.4 33.7; moved 100.2 yd to the verified spot

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6940898, 90591, 0, 0, 0, 1, 1, 2208.28, 1054.15, 30.6518, 0.523349, 0.15822, 0.720336, 0.174709, 0.652349, 0, 0, 1, 'worldforged_pickup', 'Worldforged Leaning Greatsword | realm map Tirisfal Glades');

-- Shoddy Blade (6940911): stood at 3023.5 277.0 1.4; moved 20.4 yd to the verified spot

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6940911, 515362, 0, 0, 0, 1, 1, 3005.72, 286.934, 1.75264, 1.66283, -0.346889, 0.38038, 0.633454, 0.577681, 0, 0, 1, 'worldforged_pickup', 'Worldforged Shoddy Blade | realm map Tirisfal Glades');

-- Quivering Web (6940921): stood at 2089.5 1953.2 97.3; moved 0.7 yd to the verified spot

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6940921, 254166, 0, 0, 0, 1, 1, 2089.5, 1953.2, 97.9904, 0.74328, 0, 0, 0.363144, 0.931733, 0, 0, 1, 'worldforged_pickup', 'Worldforged Quivering Web | realm map Tirisfal Glades');

-- Broken Rattlecage (6940929): stood at 2541.4 774.0 110.8; moved 14.0 yd to the verified spot

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6940929, 517368, 0, 0, 0, 1, 1, 2536.61, 787.172, 110.743, 4.07149, 0, 0, 0.893845, -0.448376, 0, 0, 1, 'worldforged_pickup', 'Worldforged Broken Rattlecage | realm map Tirisfal Glades');

-- Old Insignia (6941016): stood at 1788.2 728.8 50.1; moved 15.3 yd to the verified spot

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6941016, 515377, 0, 0, 0, 1, 1, 1803.41, 727.664, 49.4158, 0.928739, -0.173815, 0.492251, -0.381989, -0.762602, 0, 0, 1, 'worldforged_pickup', 'Worldforged Old Insignia | realm map Tirisfal Glades');

-- Old Family Broom (6941112): stood at 2330.5 1316.2 35.2; moved 1.0 yd to the verified spot

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6941112, 515089, 0, 0, 0, 1, 1, 2329.69, 1315.62, 35.181, 3.10495, -0.79072, -0.0144884, 0.611904, 0.011212, 0, 0, 1, 'worldforged_pickup', 'Worldforged Old Family Broom | realm map Tirisfal Glades');

-- Sturdy Arrow (6941173): stood at 1851.4 1758.9 136.8; moved 2.0 yd to the verified spot

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6941173, 520051, 0, 0, 0, 1, 1, 1851.23, 1760.7, 137.593, 2.77459, -0.350478, -0.0650442, 0.918624, 0.170485, 0, 0, 1, 'worldforged_pickup', 'Worldforged Sturdy Arrow | realm map Tirisfal Glades');

-- Sunchaser Blade (6941176): stood at 2571.5 1406.5 3.9; moved 28.3 yd to the verified spot

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6941176, 1345145, 0, 0, 0, 1, 1, 2543.41, 1405.39, 7.07105, 0, 0, 0.769738, 0, 0.63836, 0, 0, 1, 'worldforged_pickup', 'Worldforged Sunchaser Blade | realm map Tirisfal Glades');

-- Ulag's Other Cleaver (6941287): stood at 2390.8 322.2 40.6; moved 19.2 yd to the verified spot

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6941287, 95803, 0, 0, 0, 1, 1, 2386.62, 340.896, 39.8759, 0.187865, 0, 0, 0.0937944, 0.995592, 0, 0, 1, 'worldforged_pickup', 'Worldforged Ulag''s Other Cleaver | realm map Tirisfal Glades');

-- Offering For the Dead (6941315): stood at 1908.7 -174.8 36.0; moved 37.6 yd to the verified spot

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6941315, 517367, 0, 0, 0, 1, 1, 1922.27, -139.691, 36.4484, 1.0686, 0, 0, 0.509239, 0.860625, 0, 0, 1, 'worldforged_pickup', 'Worldforged Offering For the Dead | realm map Tirisfal Glades');

-- Joshua's Cherry Pie (90641): the realm's own object, restored - one spawn, where the realm's own client saw it

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6942560, 90641, 0, 0, 0, 1, 1, 1864.98, 1570.59, 94.7107, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', 'Worldforged Joshua''s Cherry Pie | realm map Tirisfal Glades');

-- Maquel's Fallen Water Pouch (90642): the realm's own object, restored - one spawn, where the realm's own client saw it

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6942561, 90642, 0, 0, 0, 1, 1, 1845.4, 1614.3, 11.0792, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', 'Worldforged Maquel''s Fallen Water Pouch | realm map Tirisfal Glades');

-- Cherry Pie prop (90635): the realm's own object, restored - one spawn, beside the realm's own chest

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6942562, 90635, 0, 0, 0, 1, 1, 1864.8, 1570.79, 95.168, 0, 0, 0, 0, 1, 0, 0, 1, 'worldforged_pickup', 'Worldforged Cherry Pie prop | realm map Tirisfal Glades');

-- Long Fishing Spear (90340): re-created by the audit on the North Coast

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960206, 90340, 0, 0, 0, 1, 1, 3074.1, -26.0234, 2.46281, 0, 0, 0.464836, 0, 0.885397, 0, 0, 1, 'worldforged_pickup', 'Worldforged Long Fishing Spear | realm map Tirisfal Glades');

-- Interloper's Loop (90347): re-created by the audit near Deathknell

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960207, 90347, 0, 0, 0, 1, 1, 2434.72, 1599.2, 38.5402, 2.12256, 0, 0, 0.872979, 0.487757, 0, 0, 1, 'worldforged_pickup', 'Worldforged Interloper''s Loop | realm map Tirisfal Glades');

-- Fallen Hardwood Plank (90339): re-created by the audit east of Brill

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6960208, 90339, 0, 0, 0, 1, 1, 2572.41, 526.352, 15.376, 0.524667, -0.0630353, -0.356318, 0.241761, 0.900342, 0, 0, 1, 'worldforged_pickup', 'Worldforged Fallen Hardwood Plank | realm map Tirisfal Glades');

-- Eroded Sigil Stone (6940444): stood at 1685.7 1546.6 125.2; moved 14.1 yd to the verified spot

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6940444, 254162, 0, 0, 0, 1, 1, 1681.64, 1557.15, 116.718, 0.229211, 0, 0, 0.114355, 0.99344, 0, 0, 1, 'worldforged_pickup', 'Worldforged Eroded Sigil Stone | realm map Tirisfal Glades');

-- Scarlet Shield (6941021): stood at 1791.2 1334.2 90.0; moved 0.5 yd to the verified spot

REPLACE INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `Comment`) VALUES
(6941021, 254164, 0, 0, 0, 1, 1, 1791.33, 1333.75, 89.8742, 5.73666, 0, 0, -0.269872, 0.962896, 0, 0, 1, 'worldforged_pickup', 'Worldforged Scarlet Shield | realm map Tirisfal Glades');


-- ---- the audit's creatures: the Undercity repositions ----------------------------------


-- creature 31882 (entry 2799): stands where the audit left it
UPDATE `creature` SET `position_x` = 1396.475586, `position_y` = 136.580078, `position_z` = -62.273117, `orientation` = 5.864310 WHERE `guid` = 31882 AND `id` = 2799;
-- creature 31885 (entry 4583): stands where the audit left it
UPDATE `creature` SET `position_x` = 1419.584961, `position_y` = 55.677734, `position_z` = -62.189419, `orientation` = 2.181660 WHERE `guid` = 31885 AND `id` = 4583;
-- creature 32040 (entry 6566): stands where the audit left it
UPDATE `creature` SET `position_x` = 1389.615234, `position_y` = 122.732422, `position_z` = -62.363720, `orientation` = 6.248280 WHERE `guid` = 32040 AND `id` = 6566;
-- creature 38095 (entry 4582): stands where the audit left it
UPDATE `creature` SET `position_x` = 1416.424805, `position_y` = 68.669922, `position_z` = -62.189419, `orientation` = 4.642580 WHERE `guid` = 38095 AND `id` = 4582;


COMMIT;
