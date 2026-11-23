-- Zul'Gurub: the Blood Orb (92008) floats over Jin'do's Blood Pit again, a prop with no part in the fight.
-- Name, rank, type, type_flags, movementId, HealthModifier 950 and ManaModifier 100: the live WDB row (AscensionDB
-- client captures, 2026-09-04); display 462101 (SPELLS\bloodgolem_orb.m2) from the same row. The live CoA combat log
-- of 2026-08-24 names it only during the Jin'do fight, as a friendly NPC. Level 63, faction 35, the
-- not-selectable flags and the spot (the Blood Pit's centre, about 20 yards above its floor, from video) are
-- estimated: neither the cache nor the logs hold them.
REPLACE INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `rank`, `unit_class`, `type`,
    `type_flags`, `movementId`, `HealthModifier`, `ManaModifier`, `unit_flags`, `AIName`, `ScriptName`,
    `VerifiedBuild`) VALUES
(92008, 'Blood Orb', 63, 63, 35, 1, 1, 10, 269484104, 998, 950, 100, 33555200, '', '', 0);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 92008;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`,
    `VerifiedBuild`) VALUES
(92008, 0, 462101, 1, 1, 0);

DELETE FROM `creature_template_movement` WHERE `CreatureId` = 92008;
INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`, `Chase`, `Random`,
    `InteractionPauseTimer`) VALUES
(92008, 0, 0, 1, 1, 0, 0, NULL);

DELETE FROM `creature` WHERE `guid` = 9996200;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`,
    `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`,
    `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`,
    `CreateObject`, `Comment`) VALUES
(9996200, 92008, 309, 0, 0, 15, 1, 0, -11583.4, -1251.3, 97.0, 0, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0,
    'Zul''Gurub: Blood Orb over the Blood Pit');
