-- Icon of Blood never procced (#13174, #12236): its equip dummies carry Spell.dbc ProcFlags 0 and the world had no
-- spell_proc row, so SpellMgr::LoadSpellProcs skipped them and Aura::GetProcEffectMask never rolled. Tooltip:
-- "Melee and ranged abilities", tiers "(30sec. internal cooldown)". Flags 272 (melee and ranged abilities) as the
-- merged Shadowcraft and Beaststalker 3-piece rows. Chance stays 0 so the loader uses each record's own ProcChance.
DELETE FROM `spell_proc` WHERE `SpellId` IN (202027, 312524, 316524, 320524);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
  `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
  `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(202027, 0, 0, 0, 0, 0, 272, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(312524, 0, 0, 0, 0, 0, 272, 1, 2, 0, 0, 0, 0, 0, 30000, 0),
(316524, 0, 0, 0, 0, 0, 272, 1, 2, 0, 0, 0, 0, 0, 30000, 0),
(320524, 0, 0, 0, 0, 0, 272, 1, 2, 0, 0, 0, 0, 0, 30000, 0);
