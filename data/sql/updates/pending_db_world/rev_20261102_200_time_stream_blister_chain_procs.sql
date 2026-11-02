-- Time Stream Slasher and Blister Chain never procced: their equip proc dummies carry DBC ProcFlags 0 and the
-- world had no spell_proc row, so Aura::GetProcEffectMask found no entry and the chance roll never ran (#10732).
--
-- Time Stream Slasher (515740 -> 202053; tiers 1379546/1381546 -> 312573, 1383546/1385546/1393546 -> 316573,
-- 1387546 -> 320573): "Your melee attacks and direct damaging spells have a chance to slash a temporal wound".
-- Grant the landed melee auto attack and the done-spell masks of the melee, ranged, none and magic damage
-- classes (69908) for damage spells at the hit phase. The tiers name a 5 sec internal cooldown, the base none.
--
-- Blister Chain (515797 -> 304158; tiers 1379570/1381570/1389091 -> 313273, 1383570/1385570/1393570 -> 317273,
-- 1387570 -> 321273): "your attacks have a chance to blister the target". Grant the landed melee and ranged
-- auto attacks and the melee and ranged damage-class abilities (340) for damage at the hit phase. The tiers name
-- a 25 sec internal cooldown, the base none.
--
-- Chance stays 0 so SpellMgr::LoadSpellProcs defers to the records' own ProcChance (7 and 25). Periodic ticks
-- are not proc events.
DELETE FROM `spell_proc` WHERE `SpellId` IN (202053, 312573, 316573, 320573, 304158, 313273, 317273, 321273);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(202053, 0, 0, 0, 0, 0, 69908, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(312573, 0, 0, 0, 0, 0, 69908, 1, 2, 0, 0, 0, 0, 0, 5000, 0),
(316573, 0, 0, 0, 0, 0, 69908, 1, 2, 0, 0, 0, 0, 0, 5000, 0),
(320573, 0, 0, 0, 0, 0, 69908, 1, 2, 0, 0, 0, 0, 0, 5000, 0),
(304158, 0, 0, 0, 0, 0, 340, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(313273, 0, 0, 0, 0, 0, 340, 1, 2, 0, 0, 0, 0, 0, 25000, 0),
(317273, 0, 0, 0, 0, 0, 340, 1, 2, 0, 0, 0, 0, 0, 25000, 0),
(321273, 0, 0, 0, 0, 0, 340, 1, 2, 0, 0, 0, 0, 0, 25000, 0);
