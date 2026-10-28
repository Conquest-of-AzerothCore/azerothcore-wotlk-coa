-- Frost Lich (273191): procs from direct damage once every 9 seconds, as its tooltip says. Without an entry it
-- procced from every spell type with no cooldown, its own Bone Chill slow (273193) included.
DELETE FROM `spell_proc` WHERE `SpellId` = 273191;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(273191, 0, 0, 0, 0, 0, 0x00010110, 0x1, 0x2, 0, 0, 0, 0, 0, 9000, 0);
