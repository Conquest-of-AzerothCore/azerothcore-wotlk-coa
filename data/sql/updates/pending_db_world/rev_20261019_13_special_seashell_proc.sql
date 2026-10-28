-- The Special Seashell item line never procced: its proc dummies carry DBC ProcFlags 0 and the world
-- had no spell_proc rows, so the auras never registered a proc handler (#8192). The tooltips promise a 12%
-- chance on dealing direct Frost or Nature damage with a 30 second internal cooldown: grant the landed
-- done-spell masks of the damage classes that can carry those schools (melee, ranged, none and magic),
-- restricted to damage spells of the Frost and Nature schools at the hit phase, 12% chance, 30000 ms cooldown.
-- Periodic ticks are deliberately not proc events (the tooltips say direct). Covers the base item (304014),
-- the dungeon and Zul'Gurub tiers (312991), and the higher worldforged tiers (316991, 320991).
DELETE FROM `spell_proc` WHERE `SpellId` = 312991;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(312991, 24, 0, 0, 0, 0, 69904, 1, 2, 0, 0, 0, 0, 12, 30000, 0);
DELETE FROM `spell_proc` WHERE `SpellId` = 304014;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(304014, 24, 0, 0, 0, 0, 69904, 1, 2, 0, 0, 0, 0, 12, 30000, 0);
DELETE FROM `spell_proc` WHERE `SpellId` = 316991;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(316991, 24, 0, 0, 0, 0, 69904, 1, 2, 0, 0, 0, 0, 12, 30000, 0);
DELETE FROM `spell_proc` WHERE `SpellId` = 320991;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(320991, 24, 0, 0, 0, 0, 69904, 1, 2, 0, 0, 0, 0, 12, 30000, 0);
