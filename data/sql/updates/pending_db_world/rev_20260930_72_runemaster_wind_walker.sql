-- Runemaster Wind Walker (807376) ticks only while Runic Tattoos: Air (802630) is active; its helpers reduce the
-- remaining cooldown of the Rune spells named by their Ascension effect 192.
DELETE FROM `spell_script_names` WHERE `spell_id` IN (807376, 807529, 807746, 807991) AND `ScriptName` IN
    ('aura_ascension_runemaster_wind_walker', 'spell_ascension_the_bieko_effect');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(807376, 'aura_ascension_runemaster_wind_walker'),
(807529, 'spell_ascension_the_bieko_effect'),
(807746, 'spell_ascension_the_bieko_effect'),
(807991, 'spell_ascension_the_bieko_effect');
