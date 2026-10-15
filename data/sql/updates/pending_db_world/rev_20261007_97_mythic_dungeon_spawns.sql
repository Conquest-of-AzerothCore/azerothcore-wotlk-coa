-- Mythic dungeon spawns from play-testing: rare and wing bosses in Lower Blackrock Spire and Stratholme that the
-- Mythic instances lacked (Chop'gog the Butcher, Hearthsinger Forresten, Razmorg the Decapitator, Sever, Spirestone Mystic, Spirestone Ogre Magus, Spirestone Reaver, Spirestone Warlord, The Unforgiven, Wizz'Magg the Magus, Xot'hot the Burning), and Sever in Shadowfang Keep, moved to where testers
-- met him on every difficulty.
DELETE FROM `creature` WHERE `guid` = 248653 AND `id` = 14682;
DELETE FROM `creature` WHERE `guid` BETWEEN 9970179 AND 9970190;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(9970179, 10516, 329, 0, 0, 4, 1, 0, 3720.29, -3426.38, 131.76, 3.43164, 300, 0, 0, 272419, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9970180, 10558, 329, 0, 0, 4, 1, 1, 3680.15, -3332.54, 124.904, 3.22031, 300, 0, 0, 641656, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9970181, 9219, 229, 0, 0, 4, 1, 0, -37.1626, -428.256, 31.7916, 4.70417, 300, 0, 0, 734276, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9970182, 9217, 229, 0, 0, 4, 1, 1, -37.6842, -379.083, 31.6183, 4.68916, 300, 0, 0, 421274, 15720, 0, 0, 0, 0, '', NULL, 0, NULL),
(9970183, 9216, 229, 0, 0, 4, 1, 1, -31.6589, -375.797, 31.6183, 4.67345, 300, 0, 0, 146562, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9970184, 9216, 229, 0, 0, 4, 1, 1, -43.1022, -375.351, 31.6183, 4.67345, 300, 0, 0, 146562, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9970185, 9201, 229, 0, 0, 4, 1, 1, -14.0319, -355.053, 31.6183, 3.11836, 300, 0, 0, 50818, 12430, 0, 0, 0, 0, '', NULL, 0, NULL),
(9970186, 9200, 229, 0, 0, 4, 1, 1, -19.7114, -348.077, 31.604, 3.98623, 300, 0, 0, 63512, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9970187, 9218, 229, 0, 0, 4, 1, 0, -54.5744, -325.952, 43.0746, 5.20438, 300, 0, 0, 490200, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9970188, 9198, 229, 0, 0, 4, 1, 1, -49.0848, -322.638, 43.047, 5.0473, 300, 0, 0, 50818, 12430, 0, 0, 0, 0, '', NULL, 0, NULL),
(9970189, 10263, 229, 0, 0, 4, 1, 1, -11.4631, -381.701, 49.1622, 6.27409, 300, 0, 0, 601839, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9970190, 14682, 33, 0, 0, 7, 1, 0, -229.597, 2294.04, 95.8665, 1.18295, 300, 0, 0, 2855153, 0, 0, 0, 0, 0, '', NULL, 0, NULL);
