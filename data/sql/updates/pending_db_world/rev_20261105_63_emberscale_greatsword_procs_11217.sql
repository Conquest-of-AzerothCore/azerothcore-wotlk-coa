-- Emberscale Greatsword never procced: its equip proc dummy 202030 (tiers 312531, 316531, 320531) carries DBC
-- ProcFlags 0 and the world had no spell_proc row, so Aura::GetProcEffectMask found no entry and the chance roll
-- never ran (#11217). The tooltip promises a chance when dealing melee damage or being struck in melee: grant the
-- landed melee auto attack and the melee damage-class ability, done and taken (60), for damage at the hit phase.
-- The tiers name a 6 sec internal cooldown, the base none. Chance stays 0 so the records' ProcChance (15) applies.
DELETE FROM `spell_proc` WHERE `SpellId` IN (202030, 312531, 316531, 320531);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(202030, 0, 0, 0, 0, 0, 60, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(312531, 0, 0, 0, 0, 0, 60, 1, 2, 0, 0, 0, 0, 0, 6000, 0),
(316531, 0, 0, 0, 0, 0, 60, 1, 2, 0, 0, 0, 0, 0, 6000, 0),
(320531, 0, 0, 0, 0, 0, 60, 1, 2, 0, 0, 0, 0, 0, 6000, 0);
