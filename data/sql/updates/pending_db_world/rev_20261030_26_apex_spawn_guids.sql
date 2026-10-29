-- The apex spawns were placed on GUIDs that rev_20261024_91_stv_venture_co_base_camp.sql
-- already owns, which turned Venture Co goblins into bosses. Restore those spawns and move
-- both the apex bosses and the huntmasters onto GUIDs nothing else uses.
DELETE FROM `creature` WHERE `guid` IN (9999265, 9999266, 9999267, 9999268, 9999269,
    9916225, 9916226, 9916227, 9916228, 9916229);

INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(9999265, 1094, 0, 0, 0, 1, 1, 1, -11510.605469, 433.78717, 54.387619, 5.5845, 300, 0, 0, 2238, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9999268, 1094, 0, 0, 0, 1, 1, 1, -11459.788086, 340.639954, 56.723316, 5.178533, 300, 0, 0, 2115, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9999269, 1094, 0, 0, 0, 1, 1, 1, -11486.636719, 332.727539, 46.865547, 6.13279, 300, 0, 0, 2238, 0, 0, 0, 0, 0, '', NULL, 0, NULL),
(9916225, 9916113, 0, 0, 0, 1, 1, 0, -9168.719, 768.735, 154.275, 0, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', NULL, 0, 'Torvald Greyfeather'),
(9916226, 9916114, 1, 0, 0, 1, 1, 0, 2003.636, -4645.846, 25.913, 0, 300, 0, 0, 0, 0, 0, 0, 0, 0, '', NULL, 0, 'Zul''khar'),
(9916227, 9916222, 0, 0, 0, 1, 1, 0, 146.714, -4587.26, 119.685, 0, 1800, 0, 0, 0, 0, 2, 0, 0, 0, '', NULL, 0, 'Stormfang'),
(9916228, 9916223, 1, 0, 0, 1, 1, 0, -3908.87, 1946.0, 81.0109, 0, 1800, 0, 0, 0, 0, 2, 0, 0, 0, '', NULL, 0, 'Vaelthara'),
(9916229, 9916224, 1, 0, 0, 1, 1, 0, 2269.03, -6608.37, 125.192, 0, 1800, 0, 0, 0, 0, 0, 0, 0, 0, '', NULL, 0, 'Nytharos');
