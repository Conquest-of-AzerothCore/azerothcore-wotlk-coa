-- Kirin Tor Agent 705634 (#2767): "Casting Eye of the Beholder now rapidly reduces the cooldown of your Rune
-- spells and Phase Out for the duration." Effect0 is SPELL_AURA_PROC_TRIGGER_SPELL, ProcChance 100, trigger
-- 706422, but Spell.dbc ProcFlags is 0 and no spell_proc row exists, so it never fires. Eye of the Beholder
-- (500121, the Runemaster family 38 record, not the stock farsight/creation-item spells of the same name) is
-- family 38, SpellFamilyFlags1 4, a positive self-buff (ADD_PCT_MODIFIER on the caster: crit chance and
-- Glyphic Ruin/Primordial Blast damage, per runemaster-eye-of-the-beholder.json): at cast phase Spell.cpp only
-- sets PROC_FLAG_DONE_SPELL_MAGIC_DMG_CLASS_POS (0x4000) for a beneficial magic-class cast, so ProcFlags 0x4000
-- with SpellPhaseMask 1 (cast) fires on casting Eye of the Beholder specifically; Chance 0 keeps the Spell.dbc
-- 100%.
DELETE FROM `spell_proc` WHERE `SpellId` = 705634;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(705634, 0, 38, 0, 4, 0, 0x00004000, 0, 0x1, 0, 0, 0, 0, 0, 0, 0);
