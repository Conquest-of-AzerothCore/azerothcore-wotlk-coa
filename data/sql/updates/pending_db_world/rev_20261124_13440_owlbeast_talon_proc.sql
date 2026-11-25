-- Owlbeast Talon never procced (#13440): its equip dummies carry Spell.dbc ProcFlags 0 and the world had no
-- spell_proc row, so SpellMgr::LoadSpellProcs skipped them and Aura::GetProcEffectMask never rolled. Tooltip:
-- "Damaging spells and abilities", tiers "(10sec. internal cooldown)". Flags 69904 (melee, ranged, magic and none
-- damage class harmful spells, no auto attacks) as the merged Stormrage 6-piece row for "a harmful ability". Chance
-- stays 0 so the loader uses each record's own ProcChance.
DELETE FROM `spell_proc` WHERE `SpellId` IN (202152, 312761, 316761, 320761);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
  `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
  `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(202152, 0, 0, 0, 0, 0, 69904, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(312761, 0, 0, 0, 0, 0, 69904, 1, 2, 0, 0, 0, 0, 0, 10000, 0),
(316761, 0, 0, 0, 0, 0, 69904, 1, 2, 0, 0, 0, 0, 0, 10000, 0),
(320761, 0, 0, 0, 0, 0, 69904, 1, 2, 0, 0, 0, 0, 0, 10000, 0);
