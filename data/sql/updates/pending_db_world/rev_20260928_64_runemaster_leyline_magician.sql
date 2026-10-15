-- Leyline Magician 706823 (#3100): "Casting Primordial Blast now reduces the cooldown of Primordial Pulse by 5
-- sec." Effect0 is SPELL_AURA_PROC_TRIGGER_SPELL, ProcChance 100, trigger 520146 (SPELL_EFFECT_ASCENSION_MODIFY_
-- COOLDOWN, -5000ms on Primordial Pulse 300578, matching the tooltip exactly), but Spell.dbc ProcFlags is 0 and
-- no spell_proc row exists, so it never fires. Primordial Blast (502823-502827, 800732) is family 38,
-- SpellFamilyFlags0/1/2 4194304/1048576/64, SPELL_EFFECT_SCHOOL_DAMAGE on the enemy (harmful), DmgClass magic:
-- at cast phase Spell.cpp only sets PROC_FLAG_DONE_SPELL_MAGIC_DMG_CLASS_NEG (0x10000) for a harmful magic-class
-- cast, so ProcFlags 0x10000 with SpellPhaseMask 1 (cast) fires on casting Primordial Blast specifically; Chance
-- 0 keeps the Spell.dbc 100%.
DELETE FROM `spell_proc` WHERE `SpellId` = 706823;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(706823, 0, 38, 4194304, 1048576, 64, 0x00010000, 0, 0x1, 0, 0, 0, 0, 0, 0, 0);
