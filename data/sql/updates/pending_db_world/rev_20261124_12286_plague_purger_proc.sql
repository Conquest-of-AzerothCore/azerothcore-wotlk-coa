-- Plague Purger never procced (#12286): its equip dummies carry Spell.dbc ProcFlags 0 and the world had no
-- spell_proc row, so SpellMgr::LoadSpellProcs skipped them and Aura::GetProcEffectMask never rolled. Tooltip:
-- "Dealing spell damage to undead". Flags 69632 (harmful magic and none damage class spells) as the merged D1
-- Magister 3-piece row for "Casting damaging spells". The undead limit is the burn's own TargetCreatureType 32
-- (202135/312727/316727/320727). No cooldown in any tooltip. Chance stays 0 so the loader uses each record's own
-- ProcChance.
DELETE FROM `spell_proc` WHERE `SpellId` IN (202136, 312726, 316726, 320726);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
  `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
  `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(202136, 0, 0, 0, 0, 0, 69632, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(312726, 0, 0, 0, 0, 0, 69632, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(316726, 0, 0, 0, 0, 0, 69632, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(320726, 0, 0, 0, 0, 0, 69632, 1, 2, 0, 0, 0, 0, 0, 0, 0);
