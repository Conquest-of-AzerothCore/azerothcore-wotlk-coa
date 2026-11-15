-- Explorer's Last Wish never procced: its equip proc dummy 202046 (tiers 312563, 316563, 320563) carries DBC
-- ProcFlags 0 and the world had no spell_proc row, so Aura::GetProcEffectMask found no entry and the chance roll
-- never ran (#11218). The tooltip promises a chance to gain Explorer's Health Buffer whenever you take damage: grant
-- PROC_FLAG_TAKEN_DAMAGE (1048576) as the stock taken-damage rows do. No internal cooldown is named. Chance stays 0
-- so the records' own ProcChance applies.
DELETE FROM `spell_proc` WHERE `SpellId` IN (202046, 312563, 316563, 320563);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(202046, 0, 0, 0, 0, 0, 1048576, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(312563, 0, 0, 0, 0, 0, 1048576, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(316563, 0, 0, 0, 0, 0, 1048576, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(320563, 0, 0, 0, 0, 0, 1048576, 0, 0, 0, 0, 0, 0, 0, 0, 0);
