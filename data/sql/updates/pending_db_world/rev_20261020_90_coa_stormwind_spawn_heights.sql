-- Stormwind: spawns under the patch-WB1 street level, two Hallow's End pumpkins and a guard in a bridge pillar.
--
-- patch-WB1 raised the ground under the Stormwind streets. rev_20260923_03_coa_stormwind.sql and
-- rev_20261011_01_coa_stormwind_bank_and_guard_path.sql moved most spawns onto it, but 32 stationary creatures still
-- stood 0.1 to 0.55 yd under the ground or WMO floor (Ian Drake, Tannysa, Caretaker Folsom, Shoni the Shilent, Dashel
-- Stonefist, Chromie, the Guardian of Time, guards, holiday NPCs). Each is raised onto the extracted map/vmap height at
-- the same x and y. The Hallow's End pumpkin in the road in front of the auction house moves onto the steps beside the
-- door; the one on the Lionheart Armory crate, where mod-coa-lottery spawns Trade Prince Gallywix, moves to the
-- sidewalk past the tree planter; the Stormwind City Guard inside the canal bridge pillar moves 1.3 yd out of it.
-- Positions were checked in game. Chromie and the Guardian of Time have no fixed guid, so they match by entry and spot.
-- Each other UPDATE matches guid and entry, so a row something else has changed is left alone.
UPDATE `creature` SET `position_z` = 105.088 WHERE `guid` = 10506 AND `id` = 1756;
UPDATE `creature` SET `position_z` = 98.68 WHERE `guid` = 26834 AND `id` = 297;
UPDATE `creature` SET `position_z` = 95.068 WHERE `guid` = 41677 AND `id` = 6579;
UPDATE `creature` SET `position_z` = 92.975 WHERE `guid` = 79674 AND `id` = 68;
UPDATE `creature` SET `position_z` = 96.74 WHERE `guid` = 79702 AND `id` = 1366;
UPDATE `creature` SET `position_z` = 99.362 WHERE `guid` = 79741 AND `id` = 4961;
UPDATE `creature` SET `position_z` = 96.73 WHERE `guid` = 79815 AND `id` = 1368;
UPDATE `creature` SET `position_z` = 96.73 WHERE `guid` = 79816 AND `id` = 1371;
UPDATE `creature` SET `position_z` = 96.73 WHERE `guid` = 79817 AND `id` = 1370;
UPDATE `creature` SET `position_z` = 96.249 WHERE `guid` = 79825 AND `id` = 5566;
UPDATE `creature` SET `position_z` = 94.581 WHERE `guid` = 86166 AND `id` = 13435;
UPDATE `creature` SET `position_z` = 94.546 WHERE `guid` = 86167 AND `id` = 13436;
UPDATE `creature` SET `position_z` = 117.641 WHERE `guid` = 86560 AND `id` = 1412;
UPDATE `creature` SET `position_z` = 105.751 WHERE `guid` = 86596 AND `id` = 1413;
UPDATE `creature` SET `position_z` = 105.83 WHERE `guid` = 86597 AND `id` = 1414;
UPDATE `creature` SET `position_z` = 105.879 WHERE `guid` = 89294 AND `id` = 1415;
UPDATE `creature` SET `position_z` = 100.868 WHERE `guid` = 90439 AND `id` = 2330;
UPDATE `creature` SET `position_z` = 92.68 WHERE `guid` = 90466 AND `id` = 5505;
UPDATE `creature` SET `position_z` = 96.278 WHERE `guid` = 91629 AND `id` = 15892;
UPDATE `creature` SET `position_z` = 94.595 WHERE `guid` = 120692 AND `id` = 68;
UPDATE `creature` SET `position_z` = 94.523 WHERE `guid` = 120784 AND `id` = 29093;
UPDATE `creature` SET `position_z` = 95.5 WHERE `guid` = 153322 AND `id` = 16395;
UPDATE `creature` SET `position_z` = 95.5 WHERE `guid` = 153329 AND `id` = 16433;
UPDATE `creature` SET `position_z` = 95.5 WHERE `guid` = 153336 AND `id` = 16434;
UPDATE `creature` SET `position_z` = 97.679 WHERE `guid` = 207105 AND `id` = 23507;
UPDATE `creature` SET `position_z` = 95.209 WHERE `guid` = 244502 AND `id` = 16005;
UPDATE `creature` SET `position_z` = 96.003 WHERE `guid` = 244503 AND `id` = 16105;
UPDATE `creature` SET `position_z` = 94.578 WHERE `guid` = 420001 AND `id` = 15694;
UPDATE `creature` SET `position_z` = 94.577 WHERE `guid` = 420002 AND `id` = 15694;
UPDATE `creature` SET `position_z` = 94.737 WHERE `guid` = 420003 AND `id` = 15694;
UPDATE `creature` SET `position_z` = 94.355
    WHERE `id` = 9780012 AND `map` = 0
    AND `position_x` BETWEEN -8822.64 AND -8820.64 AND `position_y` BETWEEN 625.98 AND 627.98;
UPDATE `creature` SET `position_z` = 94.344
    WHERE `id` = 178081 AND `map` = 0
    AND `position_x` BETWEEN -8821.67 AND -8819.67 AND `position_y` BETWEEN 624.782 AND 626.782;
UPDATE `gameobject` SET `position_x` = -8804.2, `position_y` = 652.32, `position_z` = 96.193, `orientation` = 0.1571,
    `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.078459, `rotation3` = 0.996917
    WHERE `guid` = 36620 AND `id` = 180406;
UPDATE `gameobject` SET `position_x` = -8794.69, `position_y` = 628.205, `position_z` = 94.894, `orientation` = 4.1811,
    `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.867944, `rotation3` = -0.496662
    WHERE `guid` = 37043 AND `id` = 180407;
UPDATE `creature` SET `position_x` = -8529.9, `position_y` = 689, `position_z` = 97.665
    WHERE `guid` = 189 AND `id` = 68;
