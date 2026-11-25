-- Thunderfall Wand never procced (#11844, #12627, #13173, #12286): its equip dummies carry Spell.dbc ProcFlags 0
-- and the world had no spell_proc row, so SpellMgr::LoadSpellProcs skipped them and Aura::GetProcEffectMask never
-- rolled. Tooltip: "magic damage" (base and the two top tiers) and "direct magic damage" (312845). The narrower
-- direct reading is used, spells only (no wand shots), as Spark of Infernus and Stormwitch Staff; whether periodic
-- ticks should count is left to the maintainers. No cooldown in any tooltip. Chance stays 0 so the loader uses each
-- record's own ProcChance.
DELETE FROM `spell_proc` WHERE `SpellId` IN (303048, 312845, 316845, 320845);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
  `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
  `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(303048, 0, 0, 0, 0, 0, 65536, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(312845, 0, 0, 0, 0, 0, 65536, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(316845, 0, 0, 0, 0, 0, 65536, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(320845, 0, 0, 0, 0, 0, 65536, 1, 2, 0, 0, 0, 0, 0, 0, 0);
