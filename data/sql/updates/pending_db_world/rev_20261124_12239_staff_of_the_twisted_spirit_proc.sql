-- Staff of the Twisted Spirit never procced (#12239, #12599, #13336): its equip dummies carry Spell.dbc ProcFlags 0
-- and the world had no spell_proc row, so SpellMgr::LoadSpellProcs skipped them and Aura::GetProcEffectMask never
-- rolled. Tooltip: "Your periodic Shadow damage". Flags 262144 (done periodic) with SchoolMask 32 (Shadow), damage
-- only. No cooldown in any tooltip. Chance stays 0 so the loader uses each record's own ProcChance.
DELETE FROM `spell_proc` WHERE `SpellId` IN (202082, 312614, 316614, 320614);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
  `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
  `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(202082, 32, 0, 0, 0, 0, 262144, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(312614, 32, 0, 0, 0, 0, 262144, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(316614, 32, 0, 0, 0, 0, 262144, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(320614, 32, 0, 0, 0, 0, 262144, 1, 2, 0, 0, 0, 0, 0, 0, 0);
