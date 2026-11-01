START TRANSACTION;
DELETE FROM `spell_proc` WHERE `SpellId` IN (272989, 277485, 280055, 281110);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(272989, 0, 6, 0, 65536, 0, 17408, 2, 2, 3, 2, 6, 0, 100, 0, 0),
(277485, 0, 9, 0, 0, 0, 332116, 1, 2, 3, 2, 6, 0, 100, 0, 0),
(280055, 0, 0, 0, 0, 0, 87312, 7, 1, 0, 0, 6, 0, 100, 0, 1),
(281110, 0, 0, 0, 0, 0, 87312, 7, 1, 0, 0, 6, 0, 100, 0, 0);
DELETE FROM `spell_script_names` WHERE `spell_id` = 272989 AND `ScriptName` = 'spell_ascension_mystic_renewed_through_absolution';
DELETE FROM `spell_script_names` WHERE `spell_id` = 277485 AND `ScriptName` = 'aura_wildcard_clean_pass';
DELETE FROM `spell_script_names` WHERE `spell_id` IN (280055, 281110) AND `ScriptName` = 'aura_wildcard_cast_reaction';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(272989, 'spell_ascension_mystic_renewed_through_absolution'),
(277485, 'aura_wildcard_clean_pass'),
(280055, 'aura_wildcard_cast_reaction'),
(281110, 'aura_wildcard_cast_reaction');
DELETE FROM `spell_bonus_data` WHERE `entry` IN (272993, 277486);
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(272993, 0.2, 0, 0.04, 0, 'Renewed Through Absolution - native heal coefficients'),
(277486, 0, 0, 0, 0, 'Clean Pass - forwarded remaining bleed damage');
COMMIT;
