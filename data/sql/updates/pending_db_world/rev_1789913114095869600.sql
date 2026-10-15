--
-- Rexxar's Might (#813): owner physical critical damage arms exactly one pet attack.
DELETE FROM `spell_proc` WHERE `SpellId` IN (806559, 806561);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(806559, 1, 0, 0, 0, 0, 332116, 1, 2, 2, 2, 0, 0, 100, 0, 0),
(806561, 0, 0, 0, 0, 0, 69972, 1, 2, 3, 2, 2, 0, 100, 0, 1);

DELETE FROM `spell_script_names` WHERE `spell_id` = 806559 AND `ScriptName` = 'aura_ascension_rexxar_might';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (806559, 'aura_ascension_rexxar_might');
DELETE FROM `spell_script_names` WHERE `spell_id` = 806561 AND `ScriptName` = 'aura_ascension_rexxar_ready';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (806561, 'aura_ascension_rexxar_ready');

DELETE FROM `spell_bonus_data` WHERE `entry` = 806562;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`)
VALUES (806562, 0, 0, 0, 0, 'Primalist Rexxar Might: owner AP supplied before native pet damage modifiers');
