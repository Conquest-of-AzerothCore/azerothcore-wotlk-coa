--
-- Torn to Shreds (#792): Totemic Smash and Rylak's Bite apply the two-stack bleed.
DELETE FROM `spell_proc` WHERE `SpellId` = 500294;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(500294, 0, 37, 0, 0, 80, 16, 1, 2, 3, 2, 0, 0, 100, 0, 0);

-- The active tooltip promises 4.5% AP over four three-second ticks.
DELETE FROM `spell_bonus_data` WHERE `entry` = 560313;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`)
VALUES (560313, 0, 0, 0, 0.01125, 'Primalist Torn to Shreds: 4.5% AP over four ticks');
