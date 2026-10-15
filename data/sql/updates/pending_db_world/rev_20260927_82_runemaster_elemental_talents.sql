-- Runemaster talents whose Spell.dbc records carry ProcFlags 0: SpellMgr::LoadSpellProcs builds no entry for them,
-- so their proc effects never fire.
-- Elemental Carvings 705618 (#973): each Fist of the Ancients cast (family 38 mask2 0x8000, melee class, cast
-- phase) casts Primeval Carving 712327, which unleashes one random carving.
-- Windsage 705568 (#1005): each Smolder cast (mask0 0x200) casts Windsage 705569; its 3 charges each add a Nature
-- strike worth 75% of a Runeblade hit (mask2 0x40000).
-- Elemental Mastery 806711 (#1025): Runic Brand's weapon damage 712322 (mask0 0x20, triggered) has a 33% chance
-- to cast Alteration Trigger 725391, which transforms Primordial Blast into one random elemental version.
DELETE FROM `spell_proc` WHERE `SpellId` IN (705568, 705569, 705618, 806711);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(705568, 0, 38, 512, 0, 0, 16, 0, 1, 0, 0, 0, 0, 100, 0, 0),
(705569, 0, 38, 0, 0, 262144, 16, 1, 2, 0, 0, 0, 0, 100, 0, 3),
(705618, 0, 38, 0, 0, 32768, 16, 0, 1, 0, 0, 0, 0, 100, 0, 0),
(806711, 0, 38, 32, 0, 0, 16, 1, 2, 0, 2, 0, 0, 33, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` IN (712327, 712356, 705569, 725391, 713003, 717070, 718040,
    721085, 712668, 712858, 713002, 712404) AND `ScriptName` IN ('spell_ascension_runemaster_primeval_carving',
    'spell_ascension_runemaster_earth_carving', 'aura_ascension_runemaster_windsage',
    'spell_ascension_runemaster_alteration_trigger', 'aura_ascension_runemaster_primordial_alteration',
    'spell_ascension_runemaster_primordial_alteration_cast');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(712327, 'spell_ascension_runemaster_primeval_carving'),
(712356, 'spell_ascension_runemaster_earth_carving'),
(705569, 'aura_ascension_runemaster_windsage'),
(725391, 'spell_ascension_runemaster_alteration_trigger'),
(713003, 'aura_ascension_runemaster_primordial_alteration'),
(717070, 'aura_ascension_runemaster_primordial_alteration'),
(718040, 'aura_ascension_runemaster_primordial_alteration'),
(721085, 'aura_ascension_runemaster_primordial_alteration'),
(712668, 'spell_ascension_runemaster_primordial_alteration_cast'),
(712858, 'spell_ascension_runemaster_primordial_alteration_cast'),
(713002, 'spell_ascension_runemaster_primordial_alteration_cast'),
(712404, 'spell_ascension_runemaster_primordial_alteration_cast');
