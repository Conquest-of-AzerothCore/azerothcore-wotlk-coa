-- Runemaster proc talents whose Spell.dbc records carry ProcFlags 0: SpellMgr::LoadSpellProcs generates no entry
-- for them, so their proc auras never fire.
-- Ancient Warrior 520755 (#1300): casting Runeblade (family 38 mask2 0x40000) or Primordial Blast (mask1 0x100000)
-- casts 520757, which reduces the cooldown of Fist of the Ancients by 2 sec. ProcFlags 0x10010 covers the melee
-- Runeblade and the magic Primordial Blast; SpellPhaseMask 1 fires once per cast.
-- Decoder 706523 (#1320): Elemental Burst (mask2 0x20000) and Runeblade damage have the record's 20% chance to
-- trigger the Runemaster's active Weapon Engravings on the target.
-- Sigilist 705586 (#1340): casting a Palm Sigil (mask2 0x2000) casts 706525, +20% crowd control duration for
-- 5 sec. Effects 1 and 2 are the native cast time and duration modifiers and do not proc.
-- Leyfrost 712308 (#1373): a critical Hoarfrost tick casts 712464; the aura script limits the periodic event to
-- Hoarfrost. 712464 treats the target of Primordial Blast, Smolder, Ice Rune, Permafrost Rune and Runic
-- Obliteration as Frozen and is spent by the next of those spells.
DELETE FROM `spell_proc` WHERE `SpellId` IN (520755, 706523, 705586, 712308, 712464);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(520755, 0, 38, 0, 1048576, 262144, 65552, 0, 1, 0, 0, 0, 0, 0, 0, 0),
(706523, 0, 38, 0, 0, 393216, 65552, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(705586, 0, 38, 0, 0, 8192, 87040, 0, 1, 0, 0, 6, 0, 0, 0, 0),
(712308, 0, 0, 0, 0, 0, 262144, 1, 2, 2, 0, 0, 0, 0, 0, 0),
(712464, 0, 38, 4194818, 67108864, 0, 69648, 0, 4, 0, 0, 0, 0, 0, 0, 1);

DELETE FROM `spell_script_names` WHERE `spell_id` IN (520757, 706523, 712308) AND `ScriptName` IN
    ('spell_ascension_runemaster_ancient_warrior', 'aura_ascension_runemaster_decoder',
    'aura_ascension_runemaster_leyfrost');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(520757, 'spell_ascension_runemaster_ancient_warrior'),
(706523, 'aura_ascension_runemaster_decoder'),
(712308, 'aura_ascension_runemaster_leyfrost');
