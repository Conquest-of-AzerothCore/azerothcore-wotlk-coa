--
-- Raging Earth (#637): create one fissure per Quake cast, independent of the number of enemies hit.
DELETE FROM `spell_proc` WHERE `SpellId` = 706622;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(706622, 0, 37, 0, 0, 256, 16, 0, 1, 0, 2, 0, 0, 100, 0, 0);

DELETE FROM `spell_bonus_data` WHERE `entry` = 681089;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(681089, 0, 0, 0, 0.08, 'Primalist - Raging Earth: 8 percent AP per tick');
