-- Ninja's Focus (#10946): each enchanted weapon's proc aura 968716 had no cooldown, so both buffs procced almost
-- constantly. Its equip spell casts 968894 "Ninja's Focus Equip ICD", a 35 s marker aura, the only cooldown the
-- data records; by the PR author's ruling it becomes a 35 s cooldown, tracked per weapon. The row keeps the values
-- the loader generated from Spell.dbc (ProcFlags 65808, every spell type, hit phase, the record's 25% chance).
DELETE FROM `spell_proc` WHERE `SpellId` = 968716;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
  `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
  `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(968716, 0, 0, 0, 0, 0, 65808, 7, 2, 0, 0, 0, 0, 0, 35000, 0);
