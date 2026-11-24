-- Leyline Conduit never procced (#12334, #12464, #12542): its equip dummies carry Spell.dbc ProcFlags 0 and the
-- world had no spell_proc row, so SpellMgr::LoadSpellProcs skipped them and Aura::GetProcEffectMask never rolled.
-- Tooltip: "Your harmful spells have a chance". Stock records with that sentence (64714, 38319, 65005, 37295,
-- 37619) carry ProcFlags 65536 in Spell.dbc; the same flags are used. No cooldown in the tooltip. Chance stays 0 so
-- the loader uses each record's own ProcChance.
DELETE FROM `spell_proc` WHERE `SpellId` IN (355105);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
  `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
  `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(355105, 0, 0, 0, 0, 0, 65536, 1, 2, 0, 0, 0, 0, 0, 0, 0);
