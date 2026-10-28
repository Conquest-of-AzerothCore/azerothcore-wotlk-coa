-- Nomad's Scroll 707653 (#3148): "Swapping to Runic Tattoos: Air now instantly dispels 1 movement slowing
-- effect on you." Effect0 is SPELL_AURA_PROC_TRIGGER_SPELL, ProcChance 100, trigger 712452
-- (SPELL_EFFECT_DISPEL_MECHANIC, MiscValue 11 = MECHANIC_SNARE, matching "movement slowing effect"), but
-- Spell.dbc's own ProcFlags (4, PROC_FLAG_KILL) is unrelated to the tooltip and no spell_proc row exists, so
-- it never fires. Runic Tattoos: Air (802630) is family 38, SpellFamilyFlags2 32, a positive self-buff
-- (movement speed and slow resistance, per rev_20260921_01_runemaster_tattoo_exclusivity.sql's stack-rule-1
-- "swap" group), DmgClass magic: at cast phase Spell.cpp only sets PROC_FLAG_DONE_SPELL_MAGIC_DMG_CLASS_POS
-- (0x4000) for a beneficial magic-class cast, so ProcFlags 0x4000 with SpellPhaseMask 1 (cast) fires on
-- casting/swapping to Runic Tattoos: Air specifically; Chance 0 keeps the Spell.dbc 100%.
DELETE FROM `spell_proc` WHERE `SpellId` = 707653;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(707653, 0, 38, 0, 0, 32, 0x00004000, 0, 0x1, 0, 0, 0, 0, 0, 0, 0);
