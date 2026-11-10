-- Icon of Khan Maraudos (item 354206) never procced Rage of Maurados (#10583): its equip proc dummy 304120
-- carries DBC ProcFlags 0 and the world had no spell_proc row, so the aura never registered a proc handler.
-- The tooltip promises a chance on dealing damage with melee or ranged attacks: grant the landed done masks
-- for melee and ranged auto attacks and melee/ranged damage-class spells (340) at the hit phase, with the
-- DBC ProcChance of 10%.
DELETE FROM `spell_proc` WHERE `SpellId` = 304120;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(304120, 0, 0, 0, 0, 0, 340, 1, 2, 0, 0, 0, 0, 10, 0, 0);
