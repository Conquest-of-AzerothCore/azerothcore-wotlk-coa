-- Echo of Aessina (item 451047, spell 901521): the spell summons creature 901521 as a guardian, but no
-- creature_template defined it, so the cast played and nothing appeared (#7128). Name, type, rank, family,
-- type_flags, display 10045 and the health/mana modifiers come from the captured AscensionDB WDB row
-- (creaturecache, 2026-09-04). The guardian takes its owner's level and faction when summoned.

INSERT INTO `creature_template`
(`entry`, `name`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`,
 `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`,
 `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`,
 `type`, `type_flags`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`,
 `RegenHealth`, `flags_extra`)
VALUES
(901521, 'Echo of Aessina', 1, 1, 0, 35, 0, 1, 1.14286,
 20, 0, 0, 1, 2000, 2000,
 1, 1, 1, 0, 0, 0, 0,
 1, 0, 0.8, 1, 1, 1,
 1, 0)
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `faction` = VALUES(`faction`), `unit_class` = VALUES(`unit_class`),
`family` = VALUES(`family`), `type` = VALUES(`type`), `type_flags` = VALUES(`type_flags`),
`HealthModifier` = VALUES(`HealthModifier`), `ManaModifier` = VALUES(`ManaModifier`);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 901521;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(901521, 0, 10045, 1, 1);
