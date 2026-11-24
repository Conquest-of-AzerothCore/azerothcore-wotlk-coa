-- Idol of the Brooding Shadow never procced (#13088): its equip dummies carry Spell.dbc ProcFlags 0 and the world
-- had no spell_proc row, so SpellMgr::LoadSpellProcs skipped them and Aura::GetProcEffectMask never rolled.
-- Tooltip: "when you critically strike with a melee attack", tiers "(25sec. internal cooldown)". Flags 20 (melee
-- auto attacks and melee abilities) with HitMask 2 (critical). Chance stays 0 so the loader uses each record's own
-- ProcChance.
DELETE FROM `spell_proc` WHERE `SpellId` IN (304092, 313145, 317145, 321145);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
  `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
  `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(304092, 0, 0, 0, 0, 0, 20, 1, 2, 2, 0, 0, 0, 0, 0, 0),
(313145, 0, 0, 0, 0, 0, 20, 1, 2, 2, 0, 0, 0, 0, 25000, 0),
(317145, 0, 0, 0, 0, 0, 20, 1, 2, 2, 0, 0, 0, 0, 25000, 0),
(321145, 0, 0, 0, 0, 0, 20, 1, 2, 2, 0, 0, 0, 0, 25000, 0);
