-- Bloodmail 3-piece never procced (#12204): its equip dummies carry Spell.dbc ProcFlags 0 and the world had no
-- spell_proc row, so SpellMgr::LoadSpellProcs skipped them and Aura::GetProcEffectMask never rolled. Tooltip:
-- "Damaging melee abilities have a chance". The Valor 3-piece (823738) has the same wording and its merged row uses
-- flags 16 (melee abilities, no auto attacks); the same row is used. Chance stays 0 so the loader uses each
-- record's own ProcChance.
DELETE FROM `spell_proc` WHERE `SpellId` IN (823732);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
  `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
  `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(823732, 0, 0, 0, 0, 0, 16, 1, 2, 0, 0, 0, 0, 0, 0, 0);
