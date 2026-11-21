-- Snowgrave's shrine hologram carries his own club and shield, outside in Winterspring and over the shrine in his map.
DELETE FROM `creature_equip_template` WHERE `CreatureID` = 978095;
INSERT INTO `creature_equip_template` (`CreatureID`, `ID`, `ItemID1`, `ItemID2`, `ItemID3`, `VerifiedBuild`) VALUES
(978095, 1, 18085, 17663, 0, 12340);
DELETE FROM `creature` WHERE `guid` = 9780939;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`,
    `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`) VALUES
(9780939, 978095, 889, 0, 0, 1, 1, 4746.1, -4929.99, 700.78, 0.6205, 300, 0, 0);
UPDATE `creature` SET `equipment_id` = 1 WHERE `guid` IN (9780937, 9780939);
