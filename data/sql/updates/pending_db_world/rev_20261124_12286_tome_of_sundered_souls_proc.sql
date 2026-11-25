-- Tome of Sundered Souls never procced (#12286): its equip dummies carry Spell.dbc ProcFlags 0 and the world had no
-- spell_proc row, so SpellMgr::LoadSpellProcs skipped them and Aura::GetProcEffectMask never rolled. Tooltip:
-- "Damaging spells", tiers "(20sec. internal cooldown)". Flags 69632 as the merged D1 Magister 3-piece row for
-- "Casting damaging spells". Chance stays 0 so the loader uses each record's own ProcChance.
DELETE FROM `spell_proc` WHERE `SpellId` IN (304096, 313152, 317152, 321152);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
  `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
  `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(304096, 0, 0, 0, 0, 0, 69632, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(313152, 0, 0, 0, 0, 0, 69632, 1, 2, 0, 0, 0, 0, 0, 20000, 0),
(317152, 0, 0, 0, 0, 0, 69632, 1, 2, 0, 0, 0, 0, 0, 20000, 0),
(321152, 0, 0, 0, 0, 0, 69632, 1, 2, 0, 0, 0, 0, 0, 20000, 0);
