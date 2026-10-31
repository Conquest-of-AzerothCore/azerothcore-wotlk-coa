-- Zul'Gurub: the five Loa Avatars the High Priests and Hakkar drain (Drain Power) for their Aspects.
-- From the client creature cache (captured 2026-09-04): name, subname, model, rank 1, type 1, type_flags 72,
-- HealthModifier 10000, movementId 999. Not in any data: level (63, the priests' level) and faction
-- (35; in the CoA combat log of 2026-08-02 players buff the avatars, so they are not hostile to the raid).
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `rank`,
    `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `type`, `type_flags`, `HealthModifier`, `movementId`,
    `VerifiedBuild`) VALUES
(666988, 'Avatar of Bethekk', 'Panther Loa', 63, 63, 35, 1, 2000, 2000, 1, 1, 72, 10000, 999, 0),
(666989, 'Avatar of Shirvallah', 'Tiger Loa', 63, 63, 35, 1, 2000, 2000, 1, 1, 72, 10000, 999, 0),
(666990, 'Avatar of Shadra', 'Spider Loa', 63, 63, 35, 1, 2000, 2000, 1, 1, 72, 10000, 999, 0),
(666991, 'Avatar of Hethiss', 'Cobra Loa', 63, 63, 35, 1, 2000, 2000, 1, 1, 72, 10000, 999, 0),
(666992, 'Avatar of Hir\'eek', 'Bat Loa', 63, 63, 35, 1, 2000, 2000, 1, 1, 72, 10000, 999, 0)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `subname` = VALUES(`subname`), `minlevel` = VALUES(`minlevel`),
    `maxlevel` = VALUES(`maxlevel`), `faction` = VALUES(`faction`), `rank` = VALUES(`rank`),
    `BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`),
    `unit_class` = VALUES(`unit_class`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`),
    `HealthModifier` = VALUES(`HealthModifier`), `movementId` = VALUES(`movementId`);

DELETE FROM `creature_template_model` WHERE `CreatureID` BETWEEN 666988 AND 666992;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`,
    `VerifiedBuild`) VALUES
(666988, 0, 633, 1, 1, 0),
(666989, 0, 11031, 1, 1, 0),
(666990, 0, 963, 1, 1, 0),
(666991, 0, 14559, 1, 1, 0),
(666992, 0, 14562, 1, 1, 0);

-- The live videos of 2026-08 (youtube 6ihbw1PKc2E, c7iqfz04PmI) show the Avatars of Bethekk and Shadra standing in
-- their temples before the pull and at full health again after a wipe, so each avatar is a temple spawn the priest
-- drains (and respawns at reset). Only the temples are seen; the exact spots are estimated next to each priest's
-- altar: Bethekk between Arlokk's arrival point and her gong, the others a few yards from the priest's spawn.
DELETE FROM `creature` WHERE `guid` BETWEEN 9999801 AND 9999805;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(9999801, 666988, 309, 0, 0, 15, 1, 0, -11565.4, -1628.96, 41.34, 0, 604800, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Zul''Gurub: Avatar of Bethekk, Temple of Bethekk (estimated)'),
(9999802, 666989, 309, 0, 0, 15, 1, 0, -11700.8, -2003.0, 62.42, 1.6057, 604800, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Zul''Gurub: Avatar of Shirvallah, Temple of Shirvallah (estimated)'),
(9999803, 666990, 309, 0, 0, 15, 1, 0, -12326.5, -1581.1, 133.0, 4.81711, 604800, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Zul''Gurub: Avatar of Shadra, Temple of Shadra (estimated)'),
(9999804, 666991, 309, 0, 0, 15, 1, 0, -12025.6, -1705.2, 39.4, 3.71755, 604800, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Zul''Gurub: Avatar of Hethiss, Temple of Hethiss (estimated)'),
(9999805, 666992, 309, 0, 0, 15, 1, 0, -12293.95, -1377.4, 145.0, 2.28638, 604800, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Zul''Gurub: Avatar of Hir''eek, Temple of Hir''eek (estimated)');
