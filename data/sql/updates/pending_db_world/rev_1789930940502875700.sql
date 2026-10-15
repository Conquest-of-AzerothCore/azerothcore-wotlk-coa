--
-- Elemental Cascade (#1916): Wildclaw critical hits heal around the caster.
DELETE FROM `spell_proc` WHERE `SpellId` = 504196;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(504196, 0, 37, 1, 0, 0, 16, 1, 2, 2, 0, 0, 0, 100, 0, 0);
DELETE FROM `spell_bonus_data` WHERE `entry` = 570051;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`)
VALUES (570051, 0.1, 0, 0.1, 0, 'Elemental Cascade: 10% healing power and 10% attack power');
