-- Runemaster Glyph of Disappearance (560037, #1229): a Phase Out (500671) cast opens the DBC window 561059, whose
-- effect 0 clears the cooldown for 15 sec; the window script restores the deferred cooldown when it ends unused.
DELETE FROM `spell_script_names`
WHERE `spell_id` = 561059 AND `ScriptName` = 'spell_ascension_runemaster_disappearance_window';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(561059, 'spell_ascension_runemaster_disappearance_window');

-- Runemaster Earthen Codex (707460, #1266) and Magebreaker (804061, #1286): Spell.dbc carries ProcFlags 0, so
-- SpellMgr::LoadSpellProcs generates no entry and their SPELL_AURA_PROC_TRIGGER_SPELL effects never fire.
-- Earthen Codex: casting any Palm Sigil (SpellFamilyName 38, mask2 0x2000) grants 707730 (+100% critical strike
-- chance, +20% Magic critical damage, 10 sec); 707730 lasts for the next 3 direct damage attacks.
-- Magebreaker: each damaging Hurricane strike (645437, SpellFamilyName 38 mask2 0x4, unique in the family, a
-- triggered melee-class spell) casts 704430: dispel one harmful magic effect from the Runemaster and reduce the
-- target's Magic damage dealt by 15% for 8 sec.
DELETE FROM `spell_proc` WHERE `SpellId` IN (707460, 707730, 804061);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(707460, 0, 38, 0, 0, 8192, 87040, 0, 1, 0, 0, 0, 0, 100, 0, 0),
(707730, 0, 0, 0, 0, 0, 69972, 1, 2, 0, 2, 0, 0, 100, 0, 3),
(804061, 0, 38, 0, 0, 4, 16, 1, 2, 0, 2, 0, 0, 100, 0, 0);
