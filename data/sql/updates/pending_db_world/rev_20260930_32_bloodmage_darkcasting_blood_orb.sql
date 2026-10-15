-- #3042 Darkcasting: Blood Orb 315303 (Exiles/AscensionDB 2026-09-13 and WDB 2026-09-04), its spawn and pickup
-- scripts, and the ability critical strike proc of 706247. Its captured family 225 exceeds the signed tinyint
-- column and only matters for pets, so it stays 0.
INSERT INTO `creature_template` (`entry`, `name`, `minlevel`, `maxlevel`, `faction`, `unit_class`, `type`,
`type_flags`, `family`, `HealthModifier`, `ManaModifier`, `movementId`, `ScriptName`) VALUES
(315303, 'Blood Orb', 1, 1, 35, 1, 6, 1, 0, 0.2, 1, 999, 'npc_ascension_bloodmage_blood_orb')
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`),
`faction` = VALUES(`faction`), `unit_class` = VALUES(`unit_class`), `type` = VALUES(`type`),
`type_flags` = VALUES(`type_flags`), `family` = VALUES(`family`), `HealthModifier` = VALUES(`HealthModifier`),
`ManaModifier` = VALUES(`ManaModifier`), `movementId` = VALUES(`movementId`), `ScriptName` = VALUES(`ScriptName`);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 315303;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(315303, 0, 64748, 1, 1);

DELETE FROM `spell_script_names` WHERE (`spell_id` = 707434 AND `ScriptName` = 'spell_ascension_bloodmage_blood_orb_spawn')
    OR (`spell_id` = 712419 AND `ScriptName` = 'spell_ascension_bloodmage_blood_orb_pickup');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(707434, 'spell_ascension_bloodmage_blood_orb_spawn'),
(712419, 'spell_ascension_bloodmage_blood_orb_pickup');

DELETE FROM `spell_proc` WHERE `SpellId` = 706247;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(706247, 0, 0, 0, 0, 0, 69904, 1, 2, 2, 0, 0, 0, 0, 0, 0);
