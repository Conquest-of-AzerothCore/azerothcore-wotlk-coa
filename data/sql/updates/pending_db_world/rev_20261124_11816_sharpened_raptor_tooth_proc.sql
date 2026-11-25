-- Sharpened Raptor Tooth never procced (#11816, #13060): its equip dummies carry Spell.dbc ProcFlags 0 and the
-- world had no spell_proc row, so SpellMgr::LoadSpellProcs skipped them and Aura::GetProcEffectMask never rolled.
-- Tooltip: "Your melee hits", tiers "(45sec. internal cooldown)". Flags 20 (melee auto attacks and melee abilities)
-- as the merged Lightforge 3-piece row. Chance stays 0 so the loader uses each record's own ProcChance.
DELETE FROM `spell_proc` WHERE `SpellId` IN (304002, 312969, 316969, 320969);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
  `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
  `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(304002, 0, 0, 0, 0, 0, 20, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(312969, 0, 0, 0, 0, 0, 20, 1, 2, 0, 0, 0, 0, 0, 45000, 0),
(316969, 0, 0, 0, 0, 0, 20, 1, 2, 0, 0, 0, 0, 0, 45000, 0),
(320969, 0, 0, 0, 0, 0, 20, 1, 2, 0, 0, 0, 0, 0, 45000, 0);
