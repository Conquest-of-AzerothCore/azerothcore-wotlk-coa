-- Shadowhide Claw (item 450572) applied Shadowhide Infusion (303084) but never dealt its Shadow damage (#10585):
-- the aura carries DBC ProcFlags 0 and the world had no spell_proc row, so it never registered a proc handler,
-- and Shadowhide Strike (303085) had no coefficients. The tooltip says the infusion causes abilities to deal
-- additional Shadow damage scaling with 10% of spell power and 10% of attack power: grant the landed done-spell
-- masks of every damage class (69904) for damage spells at the hit phase, without auto attacks, and add the
-- tooltip's coefficients to the strike.
DELETE FROM `spell_proc` WHERE `SpellId` = 303084;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(303084, 0, 0, 0, 0, 0, 69904, 1, 2, 0, 0, 0, 0, 100, 0, 0);
DELETE FROM `spell_bonus_data` WHERE `entry` = 303085;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(303085, 0.1, 0, 0.1, 0, 'Shadowhide Strike - Shadowhide Claw');
