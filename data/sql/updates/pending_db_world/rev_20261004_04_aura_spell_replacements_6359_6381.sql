DELETE FROM `spell_script_names` WHERE `spell_id` = 805742 AND `ScriptName` = 'aura_ascension_runemaster_primordial_alteration';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (805742, 'aura_ascension_runemaster_primordial_alteration');

DELETE FROM `spell_script_names` WHERE `spell_id` = 805794 AND `ScriptName` = 'spell_ascension_runemaster_primordial_alteration_cast';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (805794, 'spell_ascension_runemaster_primordial_alteration_cast');

DELETE FROM `spell_script_names` WHERE `spell_id` = 807014 AND `ScriptName` = 'spell_ascension_runemaster_runic_obliteration_glyph';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (807014, 'spell_ascension_runemaster_runic_obliteration_glyph');

DELETE FROM `spell_script_names` WHERE `spell_id` = 802272 AND `ScriptName` = 'aura_ascension_witch_hunter_trap_launcher';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (802272, 'aura_ascension_witch_hunter_trap_launcher');

DELETE FROM `spell_script_names` WHERE `spell_id` IN (680376, 681562, 681563, 681564) AND `ScriptName` = 'spell_ascension_witch_hunter_summon';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(680376, 'spell_ascension_witch_hunter_summon'),
(681562, 'spell_ascension_witch_hunter_summon'),
(681563, 'spell_ascension_witch_hunter_summon'),
(681564, 'spell_ascension_witch_hunter_summon');

DELETE FROM `spell_bonus_data` WHERE `entry` = 807014;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(807014, 0.44, 0, 0, 0, 'Runic Obliteration: 44% spell power per missile');
