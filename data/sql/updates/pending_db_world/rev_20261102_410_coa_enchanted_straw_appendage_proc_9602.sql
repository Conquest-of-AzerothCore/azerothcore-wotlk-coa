-- Enchanted Straw Appendage (#9602): the equip spell 303023 and its tiers 312819, 316819, 320819 are
-- SPELL_AURA_PROC_TRIGGER_SPELL passives whose Spell.dbc records carry ProcFlags 0, and the world had no
-- spell_proc row, so the "chance upon dealing direct magic damage" never rolled.
-- Grant the landed done-spell mask of the magic damage class at the hit phase over every school and spell family;
-- Chance 0 defers to the record's own ProcChance 2. The tiers' tooltips name a 90 sec internal cooldown, the base
-- tooltip names none.
DELETE FROM `spell_proc` WHERE `SpellId` IN (303023, 312819, 316819, 320819);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(303023, 0, 0, 0, 0, 0, 65536, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(312819, 0, 0, 0, 0, 0, 65536, 1, 2, 0, 0, 0, 0, 0, 90000, 0),
(316819, 0, 0, 0, 0, 0, 65536, 1, 2, 0, 0, 0, 0, 0, 90000, 0),
(320819, 0, 0, 0, 0, 0, 65536, 1, 2, 0, 0, 0, 0, 0, 90000, 0);
