-- Ancient Sea-dweller Charm never procced (#13498): its equip dummies carry Spell.dbc ProcFlags 0 and the world had
-- no spell_proc row, so SpellMgr::LoadSpellProcs skipped them and Aura::GetProcEffectMask never rolled. Tooltip:
-- "Your healing over time effects", tiers "(30sec. internal cooldown)". Flags 262144 (done periodic) for heals
-- only. Chance stays 0 so the loader uses each record's own ProcChance.
DELETE FROM `spell_proc` WHERE `SpellId` IN (304004, 312973, 316973, 320973);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
  `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
  `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(304004, 0, 0, 0, 0, 0, 262144, 2, 2, 0, 0, 0, 0, 0, 0, 0),
(312973, 0, 0, 0, 0, 0, 262144, 2, 2, 0, 0, 0, 0, 0, 30000, 0),
(316973, 0, 0, 0, 0, 0, 262144, 2, 2, 0, 0, 0, 0, 0, 30000, 0),
(320973, 0, 0, 0, 0, 0, 262144, 2, 2, 0, 0, 0, 0, 0, 30000, 0);
