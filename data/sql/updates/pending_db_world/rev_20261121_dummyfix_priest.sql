-- Priest-family spells whose behaviour lived in an unhandled dummy effect (tools/dummy_census/fix-batches/priest-*.md);
-- scripts in src/server/coa/AscensionDummyFixPriest.cpp. Glyphs, Mind Core, Fingers of Death, Blinding Dispersion,
-- Biting Cold and the Temporal Shield damage count are UnitScript hooks there (no binding).

DELETE FROM `spell_script_names` WHERE `ScriptName` LIKE 'spell_dummyfix_priest_%';
-- Spirit Frost 271323: the generic enchant rule (rev_20261024_14) granted Spirit Frost on every cast after the
-- first and never re-applied the blocker; spell_dummyfix_priest_spirit_frost replaces it (and its spell_proc row)
DELETE FROM `spell_script_names` WHERE `spell_id` = 271323 AND `ScriptName` = 'spell_ascension_mystic_enchant_proc';
DELETE FROM `coa_mystic_enchant_proc` WHERE `enchant_spell` = 271323;
DELETE FROM `spell_script_names` WHERE (`spell_id`, `ScriptName`) IN ((285052, 'spell_dummyfix_priest_shadow_word_gore'), (983021, 'spell_dummyfix_priest_shadow_word_gore'), (1588841, 'spell_dummyfix_priest_shadow_word_gore'), (92779, 'spell_dummyfix_priest_beacon_of_shadow_cast'), (92779, 'spell_dummyfix_priest_beacon_of_shadow'), (283386, 'spell_dummyfix_priest_temporal_shield'), (954268, 'spell_dummyfix_priest_temporal_shield'), (1584443, 'spell_dummyfix_priest_temporal_shield'), (92778, 'spell_dummyfix_priest_vampire_lord'), (954522, 'spell_dummyfix_priest_void_shift'), (2304522, 'spell_dummyfix_priest_void_shift'), (285134, 'spell_dummyfix_priest_devour_mind_extend'), (1180523, 'spell_dummyfix_priest_power_word_barrier'), (965738, 'spell_dummyfix_priest_mind_blast_reset'), (965739, 'spell_dummyfix_priest_mind_blast_reset'), (86381, 'spell_dummyfix_priest_leap_of_faith'), (1186381, 'spell_dummyfix_priest_leap_of_faith'), (278561, 'spell_dummyfix_priest_angel_bolt'), (278562, 'spell_dummyfix_priest_angel_bolt'), (271323, 'spell_dummyfix_priest_spirit_frost'), (276250, 'spell_dummyfix_priest_prayer_of_preservation'), (888571, 'spell_dummyfix_priest_prayer_of_preservation'), (1576669, 'spell_dummyfix_priest_prayer_of_preservation'), (572302, 'spell_dummyfix_priest_tentacle_madness'), (982440, 'spell_dummyfix_priest_screams_of_the_past'), (81522, 'spell_dummyfix_priest_frost_reserve'));
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Shadow Word: Gore: +8% per other own bleed on the target at application (max 40%)
(285052, 'spell_dummyfix_priest_shadow_word_gore'),
(983021, 'spell_dummyfix_priest_shadow_word_gore'),
(1588841, 'spell_dummyfix_priest_shadow_word_gore'),
-- Beacon of Shadow: not on self, one per caster; Shadow Bolt heals it (hook)
(92779, 'spell_dummyfix_priest_beacon_of_shadow_cast'),
(92779, 'spell_dummyfix_priest_beacon_of_shadow'),
-- Temporal Shield: full duration restores 75% of the damage taken while shielded
(283386, 'spell_dummyfix_priest_temporal_shield'),
(954268, 'spell_dummyfix_priest_temporal_shield'),
(1584443, 'spell_dummyfix_priest_temporal_shield'),
-- Vampire Lord: Shadow damage heals the caster and nearby allies
(92778, 'spell_dummyfix_priest_vampire_lord'),
-- Void Shift: swap health percentages (floor 25% / 10%); Void Instability blocks it
(954522, 'spell_dummyfix_priest_void_shift'),
(2304522, 'spell_dummyfix_priest_void_shift'),
-- Devour Mind: each channel tick extends the disease
(285134, 'spell_dummyfix_priest_devour_mind_extend'),
-- Power Word: Barrier: the barrier area aura at the target location
(1180523, 'spell_dummyfix_priest_power_word_barrier'),
-- Mind Shock / Darkness: reset the Mind Blast cooldown
(965738, 'spell_dummyfix_priest_mind_blast_reset'),
(965739, 'spell_dummyfix_priest_mind_blast_reset'),
-- Leap of Faith: not on a Weak-spirited target
(86381, 'spell_dummyfix_priest_leap_of_faith'),
(1186381, 'spell_dummyfix_priest_leap_of_faith'),
-- Angel of Death / Angel of Light: damage-scaled bolt
(278561, 'spell_dummyfix_priest_angel_bolt'),
(278562, 'spell_dummyfix_priest_angel_bolt'),
-- Spirit Frost: every other Frostbolt / Frostfire Bolt / Ice Lance cast grants Spirit Frost (blocker alternation)
(271323, 'spell_dummyfix_priest_spirit_frost'),
-- Prayer of Preservation: the last tick of the channel gains the final-tick healing buff
(276250, 'spell_dummyfix_priest_prayer_of_preservation'),
(888571, 'spell_dummyfix_priest_prayer_of_preservation'),
(1576669, 'spell_dummyfix_priest_prayer_of_preservation'),
-- Madness of the Old Gods: summoning a Tentacle of the Old Gods grants Madness of the Old Gods
(572302, 'spell_dummyfix_priest_tentacle_madness'),
-- Screams of the Past (enchant): teaches Screams of the Past when Psychic Scream is known
(982440, 'spell_dummyfix_priest_screams_of_the_past'),
-- Frost Reserve (enchant): direct Frost hits spend a Water Shield charge (bonus in the unit hook)
(81522, 'spell_dummyfix_priest_frost_reserve');

DELETE FROM `spell_proc` WHERE `SpellId` IN (92778, 278561, 278562, 271323, 81522);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Vampire Lord: own Shadow spell damage, direct or periodic; triggered spells too (Mind Flay ticks). The script keeps
-- single-target direct damage and all periodic ticks
(92778, 32, 0, 0x0, 0x0, 0x0, 0x50000, 0x1, 0x2, 0x0, 0x2, 0, 0, 100, 0, 0),
-- Angel of Light: direct Smite (0x80) / Holy Fire (0x100000) hits; Holy Fire's ticks are periodic and excluded
(278561, 0, 6, 0x100080, 0x0, 0x0, 0x10000, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Angel of Death: own periodic Shadow damage
(278562, 32, 0, 0x0, 0x0, 0x0, 0x40000, 0x1, 0x2, 0x0, 0x2, 0, 0, 100, 0, 0),
-- Spirit Frost: own Frostbolt (0x20) / Ice Lance (0x20000) / Frostfire Bolt (0x1000 word 1) casts, not triggered copies
(271323, 0, 3, 0x20020, 0x1000, 0x0, 0x10000, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Frost Reserve: own direct Frost spell damage (the script requires a SCHOOL_DAMAGE effect: no periodic ticks)
(81522, 16, 0, 0x0, 0x0, 0x0, 0x10000, 0x1, 0x2, 0x0, 0x2, 0, 0, 100, 0, 0);
