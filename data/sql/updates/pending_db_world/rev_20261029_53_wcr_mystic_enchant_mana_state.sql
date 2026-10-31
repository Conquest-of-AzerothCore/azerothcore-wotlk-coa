-- Pendulum and Higher Power: the periodic dummy keeps the buff for the player's mana side (above or below 50%).
DELETE FROM `spell_script_names` WHERE `spell_id` IN (1580989, 81324, 281794, 1581566) AND `ScriptName` = 'spell_ascension_mystic_mana_state';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(1580989, 'spell_ascension_mystic_mana_state'),
(81324, 'spell_ascension_mystic_mana_state'),
(281794, 'spell_ascension_mystic_mana_state'),
(1581566, 'spell_ascension_mystic_mana_state');
