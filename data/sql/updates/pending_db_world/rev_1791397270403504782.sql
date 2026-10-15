DELETE FROM `spell_proc` WHERE `SpellId` = 954814;
INSERT INTO `spell_proc` (
  `SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`,
  `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`,
  `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`
) VALUES
(954814, 1, 0, 0, 0, 0, 16, 1, 2, 3, 0, 0, 0, 100, 0, 0);
DELETE FROM `spell_script_names` WHERE `spell_id` IN (954815)
AND `ScriptName` = 'aura_ascension_wildcard_bloodbath_damage';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(954815, 'aura_ascension_wildcard_bloodbath_damage');
DELETE FROM `spell_bonus_data` WHERE `entry` = 954815;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(954815, 0, 0, 0, 0.026, 'Bloodbath: total bleed damage before division across periodic ticks');
