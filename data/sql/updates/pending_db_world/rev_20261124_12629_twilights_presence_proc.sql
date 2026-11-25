-- Twilight's Presence never procced (#12629): its equip dummies carry Spell.dbc ProcFlags 0 and the world had no
-- spell_proc row, so SpellMgr::LoadSpellProcs skipped them and Aura::GetProcEffectMask never rolled. Tooltip:
-- "Dealing periodic Shadow or Fire damage". Flags 262144 (done periodic) with SchoolMask 36 (Shadow and Fire),
-- damage only. No cooldown in any tooltip. Chance stays 0 so the loader uses each record's own ProcChance.
DELETE FROM `spell_proc` WHERE `SpellId` IN (202100, 312643, 316643, 320643);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
  `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
  `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(202100, 36, 0, 0, 0, 0, 262144, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(312643, 36, 0, 0, 0, 0, 262144, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(316643, 36, 0, 0, 0, 0, 262144, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(320643, 36, 0, 0, 0, 0, 262144, 1, 2, 0, 0, 0, 0, 0, 0, 0);
