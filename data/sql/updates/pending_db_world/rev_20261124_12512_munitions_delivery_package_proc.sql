-- Munitions Delivery Package never procced (#12512, #13063): its equip dummies carry Spell.dbc ProcFlags 0 and the
-- world had no spell_proc row, so SpellMgr::LoadSpellProcs skipped them and Aura::GetProcEffectMask never rolled.
-- Tooltip: "Your ranged attacks", tiers "(5sec. internal cooldown)". Flags 320 (ranged auto attacks and ranged
-- abilities) as the merged T1 Hunter 6-piece row. Chance stays 0 so the loader uses each record's own ProcChance.
DELETE FROM `spell_proc` WHERE `SpellId` IN (303056, 312863, 316863, 320863);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
  `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
  `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(303056, 0, 0, 0, 0, 0, 320, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(312863, 0, 0, 0, 0, 0, 320, 1, 2, 0, 0, 0, 0, 0, 5000, 0),
(316863, 0, 0, 0, 0, 0, 320, 1, 2, 0, 0, 0, 0, 0, 5000, 0),
(320863, 0, 0, 0, 0, 0, 320, 1, 2, 0, 0, 0, 0, 0, 5000, 0);
