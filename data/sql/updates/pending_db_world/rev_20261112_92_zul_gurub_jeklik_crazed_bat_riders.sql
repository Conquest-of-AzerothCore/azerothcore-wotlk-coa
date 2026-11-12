-- Zul'Gurub: High Priestess Jeklik's Crazed Bat Riders (14914) on Frenzied Gurubashi Bats (14965), Mythic and Ascended.
-- Name, rank, type, type_flags, family and displays 11225-11227: the rider's WDB row (SUB creature, dump 2026-10-04).
-- Faction 28, speeds and attack times follow stock's Gurubashi Bat Rider (14750). Level 60 and HealthModifier 6.5 on
-- the ZG ladder x1.44/x1.88/x2.32 (user decision 2026-11-12); no live health was logged, both take no damage before
-- the dive. The Heroic, Mythic and Ascended templates carry CoA's x2.2 raid scaling themselves.
INSERT INTO `creature_template` (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `name`,
    `minlevel`, `maxlevel`, `faction`, `speed_walk`, `speed_run`, `detection_range`, `rank`, `DamageModifier`,
    `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`, `unit_flags2`, `family`, `type`, `type_flags`,
    `HealthModifier`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(14914, 114914, 214914, 314914, 'Crazed Bat Rider', 60, 60, 28, 2, 2.14286, 20, 1, 1, 2000, 2000, 1, 0, 2048, 24, 7, 8,
    6.5, '', 'npc_crazed_bat_rider_coa', 0),
(114914, 0, 0, 0, 'Crazed Bat Rider', 60, 60, 28, 2, 2.14286, 20, 1, 1, 2000, 2000, 1, 0, 2048, 24, 7, 8,
    6.5 * 1.44 * 2.2, '', '', 0),
(214914, 0, 0, 0, 'Crazed Bat Rider', 60, 60, 28, 2, 2.14286, 20, 1, 1, 2000, 2000, 1, 0, 2048, 24, 7, 8,
    6.5 * 1.88 * 2.2, '', '', 0),
(314914, 0, 0, 0, 'Crazed Bat Rider', 60, 60, 28, 2, 2.14286, 20, 1, 1, 2000, 2000, 1, 0, 2048, 24, 7, 8,
    6.5 * 2.32 * 2.2, '', '', 0)
ON DUPLICATE KEY UPDATE `difficulty_entry_1` = VALUES(`difficulty_entry_1`),
    `difficulty_entry_2` = VALUES(`difficulty_entry_2`), `difficulty_entry_3` = VALUES(`difficulty_entry_3`),
    `name` = VALUES(`name`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`),
    `faction` = VALUES(`faction`), `speed_walk` = VALUES(`speed_walk`), `speed_run` = VALUES(`speed_run`),
    `detection_range` = VALUES(`detection_range`), `rank` = VALUES(`rank`),
    `DamageModifier` = VALUES(`DamageModifier`), `BaseAttackTime` = VALUES(`BaseAttackTime`),
    `RangeAttackTime` = VALUES(`RangeAttackTime`), `unit_class` = VALUES(`unit_class`),
    `unit_flags` = VALUES(`unit_flags`), `unit_flags2` = VALUES(`unit_flags2`), `family` = VALUES(`family`),
    `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`), `HealthModifier` = VALUES(`HealthModifier`),
    `AIName` = VALUES(`AIName`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (14914, 114914, 214914, 314914);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`,
    `VerifiedBuild`) VALUES
(14914, 0, 11225, 1, 1, 0), (14914, 1, 11226, 1, 1, 0), (14914, 2, 11227, 1, 1, 0),
(114914, 0, 11225, 1, 1, 0), (114914, 1, 11226, 1, 1, 0), (114914, 2, 11227, 1, 1, 0),
(214914, 0, 11225, 1, 1, 0), (214914, 1, 11226, 1, 1, 0), (214914, 2, 11227, 1, 1, 0),
(314914, 0, 11225, 1, 1, 0), (314914, 1, 11226, 1, 1, 0), (314914, 2, 11227, 1, 1, 0);

-- The bat carries the rider and dives; a bat without a rider fights as before.
UPDATE `creature_template` SET `ScriptName` = 'npc_frenzied_bat_coa' WHERE `entry` = 14965;
