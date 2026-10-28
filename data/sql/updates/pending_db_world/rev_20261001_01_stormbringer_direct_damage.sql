-- Stormbringer (273056): procs from direct damage only, as its tooltip says. The Lightning Strike ground effects
-- (273058, 273060) of its Lightning Blast (273057) hit without damage and re-triggered the aura, which can proc
-- from procs, for every enemy standing in them until the stack overflowed.
DELETE FROM `spell_proc` WHERE `SpellId` = 273056;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(273056, 0, 0, 0, 0, 0, 0x00010110, 0x1, 0x2, 0, 0, 0, 0, 0, 0, 0);
