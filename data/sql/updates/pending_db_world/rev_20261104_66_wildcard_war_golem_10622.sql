-- Wildcard War Golem 280445 (#10622) summons creature 280450 (SummonProperties 61, guardian), which the database
-- lacked, so the cast started its cooldown and summoned nothing. The live creature cache records creature 280450
-- 'War Golem', type 4, displays 26576/26584/26585 (Zul'Drak golem) and HealthModifier 1. The golem's own spells
-- sit next to the summon in Spell.dbc: 280446 War Golem Protection Aura (APPLY_AREA_AURA_OWNER school absorb
-- 3000, "Will fade if the War Golem is destroyed", plus a 1.5 s periodic trigger of 280449 War Golem Grounding
-- Ward, a 20 yd ally SPELL_MAGNET), 280447 War Golem Scaling and 280448 Avoidance. The tooltip says the golem is
-- passive and has no offensive abilities.
INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `unit_class`, `type`,
`BaseAttackTime`, `RangeAttackTime`, `HealthModifier`, `AIName`, `flags_extra`) VALUES
(280450, 'War Golem', 1, 1, 35, 1, 4, 2000, 2000, 1, 'PassiveAI', 64)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`),
`faction` = VALUES(`faction`), `unit_class` = VALUES(`unit_class`), `type` = VALUES(`type`),
`BaseAttackTime` = VALUES(`BaseAttackTime`), `RangeAttackTime` = VALUES(`RangeAttackTime`),
`HealthModifier` = VALUES(`HealthModifier`), `AIName` = VALUES(`AIName`), `flags_extra` = VALUES(`flags_extra`);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 280450;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(280450, 0, 26576, 1, 1),
(280450, 1, 26584, 1, 1),
(280450, 2, 26585, 1, 1);

DELETE FROM `creature_template_addon` WHERE `entry` = 280450;
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`,
`visibilityDistanceType`, `auras`) VALUES
(280450, 0, 0, 0, 0, 0, 0, '280446 280447 280448');
