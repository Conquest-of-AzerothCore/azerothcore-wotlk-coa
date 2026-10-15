--
-- Infusion of Neptulon (#1751): critical heals grant 15% AP for three melee attacks.
DELETE FROM `spell_proc` WHERE `SpellId` IN (300731, 300735);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(300731, 0, 0, 0, 0, 0, 16384, 2, 2, 2, 0, 0, 0, 100, 0, 0),
(300735, 0, 0, 0, 0, 0, 20, 1, 2, 3, 0, 0, 0, 100, 0, 3);
