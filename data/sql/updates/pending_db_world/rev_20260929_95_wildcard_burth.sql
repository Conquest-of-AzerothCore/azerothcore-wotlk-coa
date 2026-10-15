-- On "Darkmoon - Season 10 Wildcard" Burth (342828, the Darkmoon Faire ogre, display 536, level 60 humanoid in that
-- realm's creature cache) always stood beside Silas Darkmoon, and the client opens the same Wildcard window for
-- both (RandomModeGossip NPCs 342827, 342828, 642827). Silas wore the Ascension "Overhead Icon - Dice" (420000).
SET @GUID := 9950003;
CREATE TEMPORARY TABLE `wildcard_burth` ENGINE=InnoDB AS
    SELECT * FROM `creature_template` WHERE `entry` = 14827;
UPDATE `wildcard_burth` SET `entry` = 342828, `gossip_menu_id` = 0, `faction` = 35, `npcflag` = 1;
INSERT INTO `creature_template` SELECT * FROM `wildcard_burth`
ON DUPLICATE KEY UPDATE
    `name` = VALUES(`name`), `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`),
    `maxlevel` = VALUES(`maxlevel`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`),
    `unit_flags` = VALUES(`unit_flags`), `type` = VALUES(`type`);
DROP TEMPORARY TABLE `wildcard_burth`;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 342828;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(342828, 0, 536, 1, 1);
DELETE FROM `creature` WHERE `id` = 342828 AND `guid` BETWEEN @GUID AND @GUID+1;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`) VALUES
(@GUID+0, 342828, 0, 0, 0, 1, -8826.3, 624.4, 94.05, 0.64, 300),
(@GUID+1, 342828, 1, 0, 0, 1, 1583.7, -4425.0, 8.1, 3.2, 300);
DELETE FROM `creature_template_addon` WHERE `entry` = 642827;
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(642827, 0, 0, 0, 0, 0, 0, '420000');
