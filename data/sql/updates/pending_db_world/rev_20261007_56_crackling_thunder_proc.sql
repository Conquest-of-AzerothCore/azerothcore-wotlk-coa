DELETE FROM `spell_proc` WHERE `SpellId` = 283571;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(283571, 0, 4, 0x80, 0, 0, 0x100, 0x1, 0x2, 0, 0, 0, 0, 0, 1, 0);

DELETE FROM `spell_bonus_data` WHERE `entry` = 283572;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(283572, 0, 0.07, 0, 0.07, 'Crackling Thunder: 7% SP and AP per periodic tick');
