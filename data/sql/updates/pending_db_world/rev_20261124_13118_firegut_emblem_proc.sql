-- Firegut Emblem never procced (#13118): its equip dummies carry Spell.dbc ProcFlags 0 and the world had no
-- spell_proc row, so SpellMgr::LoadSpellProcs skipped them and Aura::GetProcEffectMask never rolled. Tooltip:
-- "Taking melee damage", tiers "(5sec. internal cooldown)". Flags 40 (taken melee auto attacks and melee abilities)
-- as the merged Mok'rash's Circlet row. The record's 5% is kept. Chance stays 0 so the loader uses each record's
-- own ProcChance.
DELETE FROM `spell_proc` WHERE `SpellId` IN (201178, 312480, 316480, 320480);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
  `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
  `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(201178, 0, 0, 0, 0, 0, 40, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(312480, 0, 0, 0, 0, 0, 40, 1, 2, 0, 0, 0, 0, 0, 5000, 0),
(316480, 0, 0, 0, 0, 0, 40, 1, 2, 0, 0, 0, 0, 0, 5000, 0),
(320480, 0, 0, 0, 0, 0, 40, 1, 2, 0, 0, 0, 0, 0, 5000, 0);
