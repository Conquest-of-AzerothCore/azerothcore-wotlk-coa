DELETE FROM `spell_script_names` WHERE (`spell_id` = 276897 AND `ScriptName` = 'aura_ascension_blooming')
    OR (`spell_id` = 276927 AND `ScriptName` = 'aura_ascension_natures_power');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(276897, 'aura_ascension_blooming'),
(276927, 'aura_ascension_natures_power');

DELETE FROM `spell_proc` WHERE `SpellId` = 276927;
INSERT INTO `spell_proc` (
    `SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`,
    `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`,
    `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`
) VALUES
(276927, 0, 9, 2048, 0, 0, 82176, 3, 2, 3, 2, 3, 0, 100, 0, 0);

UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 128 WHERE `entry` = 160001;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 160001;
INSERT INTO `creature_template_model` (
    `CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`
) VALUES
(160001, 0, 11686, 1, 1, 0);
