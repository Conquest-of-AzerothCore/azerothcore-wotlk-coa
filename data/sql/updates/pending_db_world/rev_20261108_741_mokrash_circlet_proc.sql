-- Mok'rash's Circlet never procced on being struck: its equip dummies carry DBC ProcFlags 0 and the world had no
-- spell_proc row, so Aura::GetProcEffectMask found no entry and the Frost wave never fired (#11662).
--
-- The tooltips read "When struck in combat by melee attacks you have a chance to inflict ... Frost damage to all
-- enemies within ... yards". Grant the taken melee auto attack and taken melee damage-class spell masks
-- (PROC_FLAG_TAKEN_MELEE_AUTO_ATTACK 0x8 | PROC_FLAG_TAKEN_SPELL_MELEE_DMG_CLASS 0x20, ProcFlags 40) for damage at
-- the hit phase. No ranged or spell masks: the text says melee. HitMask 0 leaves the taken default of normal and
-- critical hits, so a dodged, parried or missed swing is not a strike. Chance is left 0 so
-- SpellMgr::LoadSpellProcs defers to the record's own ProcChance 100.
--
-- Cooldown: the three worldforged tier tooltips (312980, 316980, 320980) state "(3sec. internal cooldown)", so
-- they carry 3000. The base dummy 304007's tooltip and DBC name no cooldown, so it keeps 0 rather than borrowing
-- the tiers' value; the cooldown on 304007 is left to the maintainers.
--
-- Covers the base dummy (304007) and the tiers 312980/316980/320980, which trigger the Water Wave records
-- 304008/312981/316981/320981.
DELETE FROM `spell_proc` WHERE `SpellId` IN (304007, 312980, 316980, 320980);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(304007, 0, 0, 0, 0, 0, 40, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(312980, 0, 0, 0, 0, 0, 40, 1, 2, 0, 0, 0, 0, 0, 3000, 0),
(316980, 0, 0, 0, 0, 0, 40, 1, 2, 0, 0, 0, 0, 0, 3000, 0),
(320980, 0, 0, 0, 0, 0, 40, 1, 2, 0, 0, 0, 0, 0, 3000, 0);
