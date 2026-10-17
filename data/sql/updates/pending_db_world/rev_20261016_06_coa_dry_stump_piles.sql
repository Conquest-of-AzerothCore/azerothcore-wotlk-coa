-- The three Dry Stump log piles in the Snowsong Valley watchtower ("Light's Warmth"), where the user stood (.gps).
DELETE FROM `gameobject` WHERE `guid` BETWEEN 9963440 AND 9963442;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `Comment`) VALUES
(9963440, 2300802, 0, 0, 0, 1, 1, -7006.4443, 495.93423, 350.39313, 3.7468169, 0, 0, 0.954561, -0.298015, 30, 100, 1, 'Dry Stump, Snowsong Valley watchtower (Light''s Warmth)'),
(9963441, 2300802, 0, 0, 0, 1, 1, -7007.649, 514.6018, 350.3951, 2.3637295, 0, 0, 0.925315, 0.3792, 30, 100, 1, 'Dry Stump, Snowsong Valley watchtower (Light''s Warmth)'),
(9963442, 2300802, 0, 0, 0, 1, 1, -6995.346, 507.1138, 350.39856, 5.3411703, 0, 0, 0.453784, -0.891112, 30, 100, 1, 'Dry Stump, Snowsong Valley watchtower (Light''s Warmth)');
