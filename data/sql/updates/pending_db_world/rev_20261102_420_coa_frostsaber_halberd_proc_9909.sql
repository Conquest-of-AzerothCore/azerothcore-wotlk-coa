-- Frostsaber Halberd (#9909): the equip spell 312688 and its tiers 316688, 320688 are SPELL_AURA_PROC_TRIGGER_SPELL
-- passives (Bloodscent) whose Spell.dbc records carry ProcFlags 0, and the world had no spell_proc row, so the
-- "chance when dealing Physical damage over time" never rolled.
-- Grant the done-periodic mask over the physical school at the hit phase; Chance 0 defers to the record's own
-- ProcChance 50.
DELETE FROM `spell_proc` WHERE `SpellId` IN (312688, 316688, 320688);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(312688, 1, 0, 0, 0, 0, 262144, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(316688, 1, 0, 0, 0, 0, 262144, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(320688, 1, 0, 0, 0, 0, 262144, 1, 2, 0, 0, 0, 0, 0, 0, 0);
