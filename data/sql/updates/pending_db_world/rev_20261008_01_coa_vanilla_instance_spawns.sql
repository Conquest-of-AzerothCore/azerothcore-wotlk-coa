-- Shadowfang Keep stable: each of the three Fel Steed spots spawns a Fel Steed or a Shadow Charger.
-- Spots and the Shadow Charger rows: db.exil.es creature_spawn (SUB dump 2026-10-04, guids 87898-87900).
-- Ascension combat logs (2026-05 to 2026-08) show three Chargers, two Chargers and a Steed, or three Steeds.
-- Scarlet Monastery Graveyard: four Scarlet Scryers next to the Scarlet Torturers.
-- Positions: db.exil.es creature_spawn (SUB dump 2026-10-04, guids 87910 and 87928-87930); the logs show
-- two to four Scryers per run. Facing is copied from the adjacent Torturer.
DELETE FROM `creature` WHERE `guid` BETWEEN 9960001 AND 9960007;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(9960001, 3865, 33, 0, 0, 7, 1, 0, -234.131, 2236.26, 79.8619, 0.296706, 86400, 0, 0, 1251, 0, 0, 0, 0, 0, '', 0, 0, NULL),
(9960002, 3865, 33, 0, 0, 7, 1, 0, -223.612, 2245.72, 79.8583, 5.13127, 86400, 0, 0, 1251, 0, 0, 0, 0, 0, '', 0, 0, NULL),
(9960003, 3865, 33, 0, 0, 7, 1, 0, -217.135, 2247.13, 79.8579, 4.88692, 86400, 0, 0, 1251, 0, 0, 0, 0, 0, '', 0, 0, NULL),
(9960004, 4293, 189, 0, 0, 7, 1, 1, 1782.42, 1118.76, 7.49, 2.87979, 86400, 0, 0, 2433, 1704, 0, 0, 0, 0, '', 0, 0, NULL),
(9960005, 4293, 189, 0, 0, 7, 1, 1, 1759.67, 1146.85, 7.49036, 3.4383, 86400, 0, 0, 2433, 1704, 0, 0, 0, 0, '', 0, 0, NULL),
(9960006, 4293, 189, 0, 0, 7, 1, 1, 1788.68, 1145.46, 7.49084, 5.37561, 86400, 0, 0, 2433, 1704, 0, 0, 0, 0, '', 0, 0, NULL),
(9960007, 4293, 189, 0, 0, 7, 1, 1, 1805.18, 1167.85, 6.82, 1.51844, 86400, 0, 0, 2433, 1704, 0, 0, 0, 0, '', 0, 0, NULL);

DELETE FROM `creature_formations` WHERE `memberGUID` BETWEEN 9960001 AND 9960003;
INSERT INTO `creature_formations` (`leaderGUID`, `memberGUID`, `dist`, `angle`, `groupAI`, `point_1`, `point_2`) VALUES
(16441, 9960001, 10, 120, 514, 0, 0),
(16441, 9960002, 0, 0, 2, 0, 0),
(16441, 9960003, 10, 225, 514, 0, 0);

DELETE FROM `pool_template` WHERE `entry` BETWEEN 9960001 AND 9960003;
INSERT INTO `pool_template` (`entry`, `max_limit`, `description`) VALUES
(9960001, 1, 'Shadowfang Keep - Fel Steed or Shadow Charger (stable spot 1)'),
(9960002, 1, 'Shadowfang Keep - Fel Steed or Shadow Charger (stable spot 2)'),
(9960003, 1, 'Shadowfang Keep - Fel Steed or Shadow Charger (stable spot 3)');

DELETE FROM `pool_creature` WHERE `guid` IN (16440, 16441, 16442, 9960001, 9960002, 9960003);
INSERT INTO `pool_creature` (`guid`, `pool_entry`, `chance`, `description`) VALUES
(16440, 9960001, 0, 'Shadowfang Keep - Fel Steed'),
(9960001, 9960001, 0, 'Shadowfang Keep - Shadow Charger'),
(16441, 9960002, 0, 'Shadowfang Keep - Fel Steed'),
(9960002, 9960002, 0, 'Shadowfang Keep - Shadow Charger'),
(16442, 9960003, 0, 'Shadowfang Keep - Fel Steed'),
(9960003, 9960003, 0, 'Shadowfang Keep - Shadow Charger');
