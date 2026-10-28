DELETE FROM `spell_proc` WHERE `SpellId` = 504886;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`,
`ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(504886, 0, 0, 0, 0, 0, 262144, 1, 2, 0, 0, 0, 0, 15, 0, 0);

DELETE FROM `spell_bonus_data` WHERE `entry` = 560966;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(560966, 0, 0, 0.3, 0, 'Ranger: Quills deals 30% attack power damage');

DELETE FROM `spell_ranks` WHERE `spell_id` = 567544;
INSERT INTO `spell_ranks` (`first_spell_id`, `spell_id`, `rank`) VALUES
(801292, 567544, 9);
