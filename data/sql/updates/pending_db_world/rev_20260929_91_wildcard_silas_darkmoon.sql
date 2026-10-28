-- Silas Darkmoon (642827) handed out the Wildcard Scrolls of Fortune on "Darkmoon - Season 10 Wildcard".
-- The client turns his gossip into its Darkmoon reward window. He stood next to Chromie in the Stormwind
-- Trade District and the Orgrimmar Valley of Strength.
SET @GUID := 9950001;
UPDATE `creature_template` SET `npcflag` = 1 WHERE `entry` = 642827;
DELETE FROM `creature` WHERE `id` = 642827 AND `guid` BETWEEN @GUID AND @GUID+1;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`) VALUES
(@GUID+0, 642827, 0, 0, 0, 1, -8824.5, 622.0, 94.05, 0.64, 300),
(@GUID+1, 642827, 1, 0, 0, 1, 1583.5, -4422.0, 8.1, 3.2, 300);
