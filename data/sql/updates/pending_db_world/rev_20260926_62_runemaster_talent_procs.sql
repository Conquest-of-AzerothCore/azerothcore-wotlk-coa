-- Runemaster proc talents whose Spell.dbc records carry ProcFlags 0: SpellMgr::LoadSpellProcs generates
-- no entry for them, so their SPELL_AURA_PROC_TRIGGER_SPELL effects can never fire.
-- Glyphs of Power (#498): direct damage dealt (melee/ranged autos, melee/ranged/none/magic spell hits
-- with damage) has a 10% chance to cast 706528, restoring 3% of maximum mana.
-- Runebound Surge (#532): casting Runeshroud (SpellFamilyName 38, mask0 0x8000, unique to 500288)
-- casts 707426, +75% movement speed for 3 sec. ProcFlags 0x1400 covers a DmgClass NONE spell of
-- either positivity; SpellPhaseMask 1 fires once per cast.
DELETE FROM `spell_proc` WHERE `SpellId` IN (520145, 707423);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(520145, 0, 0, 0, 0, 0, 69972, 1, 2, 0, 0, 0, 0, 10, 0, 0),
(707423, 0, 38, 32768, 0, 0, 5120, 0, 1, 0, 0, 0, 0, 100, 0, 0);
