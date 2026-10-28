-- Northshire vineyards: 35 of the 70 Defias Thugs removed (playtest: far too dense with the CoA Defias
-- Trainees); the kept Thugs and Trainees stand at least 18 yd apart. The Northshire Defias stay hostile
-- but only engage within 5-8 yd (detection 6 before the level adjustment and the 5 yd floor).
UPDATE `creature_template` SET `detection_range` = 6 WHERE `entry` IN (38, 103, 537, 9300100);
DELETE FROM `smart_scripts` WHERE `source_type` = 0 AND `entryorguid` IN (
-80149, -80152, -80153, -80155, -80162, -80168, -80169, -80174, -80182, -80183, -80185, -80186, -80188,
-80189, -80190, -80193, -80195, -80196, -80201, -80208, -80210, -80211, -80213, -80226, -80230, -80231,
-80237, -80246, -80251, -80253, -80254, -80255, -80256, -80257, -80259);
DELETE FROM `creature_addon` WHERE `guid` IN (
80149, 80152, 80153, 80155, 80162, 80168, 80169, 80174, 80182, 80183, 80185, 80186, 80188, 80189, 80190,
80193, 80195, 80196, 80201, 80208, 80210, 80211, 80213, 80226, 80230, 80231, 80237, 80246, 80251, 80253,
80254, 80255, 80256, 80257, 80259);
-- Thug 80184's scene made its removed partner 80185 emote; without it he runs the Defias Thug entry script
-- like every other kept Thug. The action lists and patrol paths of the removed Thugs go with them.
DELETE FROM `smart_scripts` WHERE `source_type` = 0 AND `entryorguid` = -80184;
DELETE FROM `smart_scripts` WHERE `source_type` = 9 AND `entryorguid` IN (8015200, 8018400, 8018800, 8020100);
DELETE FROM `waypoint_data` WHERE `id` IN (801490, 801550, 801900, 802080, 802510);
-- Mirror Lake Orchard: 4 of the Spada manor Defias moved there earlier removed, and one Cutpurse (gen_elwynn);
-- 12 Defias -> 7 (playtest: ~40-50% less dense).
DELETE FROM `creature` WHERE `id` IN (116, 474) AND `guid` IN (80384, 80386, 80387, 80412);
-- Defias camp east of Ridgepoint Tower: 24 Bandits -> 11, at least 18 yd apart (5 stock here, 8 in gen_elwynn).
DELETE FROM `creature` WHERE `id` = 116 AND `guid` IN (81410, 81413, 81415, 81423, 81427);
DELETE FROM `creature` WHERE `id` = 38 AND `guid` IN (
80149, 80152, 80153, 80155, 80162, 80168, 80169, 80174, 80182, 80183, 80185, 80186, 80188, 80189, 80190,
80193, 80195, 80196, 80201, 80208, 80210, 80211, 80213, 80226, 80230, 80231, 80237, 80246, 80251, 80253,
80254, 80255, 80256, 80257, 80259);
