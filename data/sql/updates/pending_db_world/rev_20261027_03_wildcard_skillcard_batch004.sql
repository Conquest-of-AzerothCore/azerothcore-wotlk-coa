START TRANSACTION;
DELETE FROM `spell_proc` WHERE `SpellId` IN (277609, 283090, 284460);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(277609, 0, 8, 8388608, 0, 1073741824, 256, 1, 2, 2, 2, 0, 0, 100, 0, 0),
(283090, 0, 5, 128, 0, 0, 65536, 1, 2, 3, 2, 0, 0, 100, 0, 0),
(284460, 0, 0, 0, 0, 0, 332116, 1, 2, 2, 2, 0, 0, 100, 0, 0);
DELETE FROM `spell_script_names` WHERE `spell_id` = 277609 AND `ScriptName` = 'aura_wildcard_critical_serration';
DELETE FROM `spell_script_names` WHERE `spell_id` = 283090 AND `ScriptName` = 'spell_ascension_mystic_apply_corruption';
DELETE FROM `spell_script_names` WHERE `spell_id` = 284460 AND `ScriptName` = 'aura_wildcard_tribal_rage';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(277609, 'aura_wildcard_critical_serration'),
(283090, 'spell_ascension_mystic_apply_corruption'),
(284460, 'aura_wildcard_tribal_rage');
COMMIT;
