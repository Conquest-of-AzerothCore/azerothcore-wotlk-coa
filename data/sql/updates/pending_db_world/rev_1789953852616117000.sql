--
-- Douse (#3681): Seismic damage triggers the Frost AP hit and native Doused debuff.
DELETE FROM `spell_proc` WHERE `SpellId` = 807558;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(807558, 0, 37, 80, 4194560, 263168, 332048, 1, 2, 3, 2, 0, 0, 100, 0, 0);
DELETE FROM `spell_bonus_data` WHERE `entry` = 807559;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(807559, 0, 0, 0.08, 0, 'Douse: active tooltip eight percent attack power');
