--
INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `speed_walk`, `speed_run`,
    `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`, `unit_flags2`, `type`, `type_flags`,
    `HealthModifier`, `ManaModifier`, `ArmorModifier`, `DamageModifier`, `flags_extra`)
SELECT 503001, 'Falcon Scout', `minlevel`, `maxlevel`, `faction`, `speed_walk`, `speed_run`, `BaseAttackTime`,
    `RangeAttackTime`, `unit_class`, `unit_flags`, `unit_flags2`, 1, `type_flags`, `HealthModifier`, `ManaModifier`,
    `ArmorModifier`, `DamageModifier`, `flags_extra`
FROM `creature_template` WHERE `entry` = 4277
ON DUPLICATE KEY UPDATE `entry` = 503001;

DELETE FROM `creature_template_model` WHERE `CreatureID` = 503001;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES (503001, 0, 22626, 1, 1);
