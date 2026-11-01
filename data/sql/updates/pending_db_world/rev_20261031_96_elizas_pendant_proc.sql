-- Eliza's Pendant's equip line never procced: its proc dummies carry DBC ProcFlags 0 and the world had no
-- spell_proc row, so Aura::GetProcEffectMask found no entry and the 5% roll never happened (#9883).
--
-- The tooltips promise a "$h%" chance on dealing magic damage to reduce the struck creature's movement speed
-- by 50/50/58/65% for 5 sec. Grant the landed done-spell mask of the magic damage class at the hit phase
-- (PROC_FLAG_DONE_SPELL_MAGIC_DMG_CLASS_NEG, ProcFlags 65536) over every school and every spell family;
-- Chance is left 0 so SpellMgr::LoadSpellProcs defers to the record's own ProcChance 5, and Cooldown stays 0
-- because none of the tooltips names an internal cooldown. Periodic ticks are not proc events (the records
-- name damage dealt, and the sibling item-proc repairs exclude periodic as well).
--
-- Covers the base item's dummy (303050) and the dungeon/Zul'Gurub and higher worldforged tiers (312849,
-- 316849, 320849), which trigger 303051/312850/316850/320850 Gravechill.
DELETE FROM `spell_proc` WHERE `SpellId` IN (303050, 312849, 316849, 320849);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(303050, 0, 0, 0, 0, 0, 65536, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(312849, 0, 0, 0, 0, 0, 65536, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(316849, 0, 0, 0, 0, 0, 65536, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(320849, 0, 0, 0, 0, 0, 65536, 1, 2, 0, 0, 0, 0, 0, 0, 0);
