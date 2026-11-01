START TRANSACTION;
DELETE FROM `spell_proc` WHERE `SpellId` IN (48545, 280210, 283318, 284041, 284042);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(48545, 0, 0, 0, 0, 0, 279552, 2, 2, 3, 2, 6, 0, 100, 0, 0),
(280210, 0, 0, 0, 0, 0, 69972, 1, 2, 3, 0, 6, 0, 20, 0, 0),
(283318, 0, 0, 0, 0, 0, 139944, 1, 2, 3, 2, 5, 0, 100, 0, 0),
(284041, 0, 0, 0, 0, 0, 69972, 1, 2, 3, 2, 6, 0, 100, 0, 0),
(284042, 0, 0, 0, 0, 0, 559104, 2, 2, 3, 2, 6, 0, 100, 0, 0);
DELETE FROM `spell_script_names` WHERE `spell_id` = 48545 AND `ScriptName` = 'aura_wildcard_revitalize';
DELETE FROM `spell_script_names` WHERE `spell_id` = 280210 AND `ScriptName` = 'aura_wildcard_three_hammers';
DELETE FROM `spell_script_names` WHERE `spell_id` = 283318 AND `ScriptName` = 'aura_wildcard_supercharged';
DELETE FROM `spell_script_names` WHERE `spell_id` = 284041 AND `ScriptName` = 'aura_wildcard_skillcard_proc';
DELETE FROM `spell_script_names` WHERE `spell_id` = 284042 AND `ScriptName` = 'aura_wildcard_waking_nightmare';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(48545, 'aura_wildcard_revitalize'),
(280210, 'aura_wildcard_three_hammers'),
(283318, 'aura_wildcard_supercharged'),
(284041, 'aura_wildcard_skillcard_proc'),
(284042, 'aura_wildcard_waking_nightmare');
DELETE FROM `spell_bonus_data` WHERE `entry` = 280212;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(280212, 0.325, 0, 0.278, 0, 'Judgement of the Three Hammers - native physical hammer coefficients');
COMMIT;
