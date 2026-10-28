DELETE FROM `spell_proc` WHERE `SpellId` = 271403;
INSERT INTO `spell_proc` (
  `SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`,
  `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`,
  `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`
) VALUES
(271403, 0, 0, 0, 0, 0, 20, 1, 2, 3, 0, 0, 0, 100, 0, 0);
DELETE FROM `spell_script_names` WHERE `spell_id` IN (271403)
AND `ScriptName` = 'aura_ascension_wildcard_corrupted_bear';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(271403, 'aura_ascension_wildcard_corrupted_bear');
DELETE FROM `spell_script_names` WHERE `spell_id` IN (5487, 9634)
AND `ScriptName` = 'aura_ascension_wildcard_corrupted_bear_form';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(5487, 'aura_ascension_wildcard_corrupted_bear_form'),
(9634, 'aura_ascension_wildcard_corrupted_bear_form');
