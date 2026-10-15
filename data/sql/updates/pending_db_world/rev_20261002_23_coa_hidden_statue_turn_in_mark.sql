-- A Quiet Life 200081 is turned in by clicking the Hidden Statue, but the client draws a quest giver's floating
-- question mark only over creatures, never over a gameobject. An invisible, unselectable creature (display 11686)
-- at the statue is a second ender for the quest, so its mark shows players where to turn in; every click still lands
-- on the statue (author's request; INFERRED). The mark draws about 3.7 yd above the creature (in game), so it hovers
-- 1.2 yd below the statue's base to put the mark just over the 2 yd statue's head.
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`,
    `faction`, `npcflag`, `speed_walk`, `speed_run`, `detection_range`, `rank`, `BaseAttackTime`, `RangeAttackTime`,
    `unit_class`, `unit_flags`, `unit_flags2`, `type`, `type_flags`, `lootid`, `AIName`, `MovementType`,
    `HealthModifier`, `ManaModifier`, `ArmorModifier`, `RegenHealth`, `flags_extra`, `ScriptName`) VALUES
(9300260, 'Hidden Statue', NULL, 0, 1, 1, 0, 35, 2, 1, 1.14286, 20, 0, 2000, 2000, 1, 33555202, 2048, 10, 0, 0, '', 0,
    1, 1, 1, 1, 2, '')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`),
    `gossip_menu_id` = VALUES(`gossip_menu_id`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`),
    `exp` = VALUES(`exp`), `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`),
    `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`),
    `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`),
    `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`),
    `unit_class` = VALUES(`unit_class`), `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`),
    `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `lootid` = VALUES(`lootid`),
    `AIName` = VALUES(`AIName`), `MovementType` = VALUES(`MovementType`),
    `HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`),
    `ArmorModifier` = VALUES(`ArmorModifier`), `RegenHealth` = VALUES(`RegenHealth`),
    `flags_extra` = VALUES(`flags_extra`), `ScriptName` = VALUES(`ScriptName`);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 9300260;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(9300260, 0, 11686, 1, 1);
DELETE FROM `creature_template_movement` WHERE `CreatureId` = 9300260;
INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`) VALUES
(9300260, 1, 0, 1, 1);
DELETE FROM `creature_questender` WHERE `id` = 9300260 AND `quest` = 200081;
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (9300260, 200081);
DELETE FROM `creature` WHERE `guid` = 9003730;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`,
    `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`,
    `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`,
    `CreateObject`, `Comment`) VALUES
(9003730, 9300260, 0, 0, 0, 1, 1, 0, 1722.6, 1811, 169.6, 0.1, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0,
    'CoA Deathknell: western mountains, under the Hidden Statue; its mark floats over the statue''s head');
