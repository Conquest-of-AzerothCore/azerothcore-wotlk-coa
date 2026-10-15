-- Runemaster Palm Sigils (805380 chain) hold one charge, so Elements of Fury (707413, SPELLMOD_CHARGES +1) lets them
-- affect one additional instance of damage.
DELETE FROM `spell_proc` WHERE `SpellId` = -805380;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(-805380, 126, 0, 0, 0, 0, 332116, 1, 2, 3, 2, 6, 0, 100, 0, 1);
