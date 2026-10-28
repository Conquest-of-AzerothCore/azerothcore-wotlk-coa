-- Runic Obliteration 705560 (#2734, PARTIAL FIX): "Using Elemental Burst now has a 20% chance to transform your
-- next Primordial Blast into Runic Obliteration for [duration]." Effect0 is SPELL_AURA_PROC_TRIGGER_SPELL,
-- ProcChance 20 (matches "20%"), trigger 805742 (the transform buff, a bare SPELL_AURA_DUMMY), but Spell.dbc
-- ProcFlags is 0 and no spell_proc row exists, so casting Elemental Burst never grants 805742. Elemental Burst
-- (802202/502828/502838) is family 38, SpellFamilyFlags2 131072 (0x20000), SPELL_EFFECT_SCHOOL_DAMAGE on the
-- enemy (harmful), DmgClass magic: at cast phase Spell.cpp only sets PROC_FLAG_DONE_SPELL_MAGIC_DMG_CLASS_NEG
-- (0x10000) for a harmful magic-class cast, so ProcFlags 0x10000 with SpellPhaseMask 1 (cast) fires on casting
-- Elemental Burst specifically; Chance 0 keeps the Spell.dbc 20%.
-- This only restores the transform buff grant. 805742 has no registered AuraScript and nothing currently
-- intercepts the next Primordial Blast cast to redirect it into 805794/Runic Obliteration; that redirect is a
-- separate C++ implementation left to a maintainer decision on the transform mechanism. Refs #2734.
DELETE FROM `spell_proc` WHERE `SpellId` = 705560;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(705560, 0, 38, 0, 0, 131072, 0x00010000, 0, 0x1, 0, 0, 0, 0, 0, 0, 0);
