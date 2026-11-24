-- Dusty Priest Cloak never procced (#13497): its equip dummies carry Spell.dbc ProcFlags 0 and the world had no
-- spell_proc row, so SpellMgr::LoadSpellProcs skipped them and Aura::GetProcEffectMask never rolled. Tooltip: "Your
-- heal over time effects", tiers "(10sec. internal cooldown)". Flags 262144 (done periodic) for heals only. The
-- dummies' second effect (a root, 303039/312833/316833/320833) is not in the tooltip; it is disabled
-- (DisableEffectsMask 2) by the PR author's ruling. Chance stays 0 so the loader uses each record's own ProcChance.
DELETE FROM `spell_proc` WHERE `SpellId` IN (303041, 312832, 316832, 320832);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
  `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
  `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(303041, 0, 0, 0, 0, 0, 262144, 2, 2, 0, 0, 2, 0, 0, 0, 0),
(312832, 0, 0, 0, 0, 0, 262144, 2, 2, 0, 0, 2, 0, 0, 10000, 0),
(316832, 0, 0, 0, 0, 0, 262144, 2, 2, 0, 0, 2, 0, 0, 10000, 0),
(320832, 0, 0, 0, 0, 0, 262144, 2, 2, 0, 0, 2, 0, 0, 10000, 0);
