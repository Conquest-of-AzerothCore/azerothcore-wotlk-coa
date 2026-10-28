DELETE FROM `spell_script_names` WHERE `spell_id` IN (274515, 274544, 274545, 274546, 274547, 274548, 274549,
  274550, 274551, 274552, 274553, 274554)
AND `ScriptName` = 'spell_ascension_wildcard_solar_strike';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(274515, 'spell_ascension_wildcard_solar_strike'),
(274544, 'spell_ascension_wildcard_solar_strike'),
(274545, 'spell_ascension_wildcard_solar_strike'),
(274546, 'spell_ascension_wildcard_solar_strike'),
(274547, 'spell_ascension_wildcard_solar_strike'),
(274548, 'spell_ascension_wildcard_solar_strike'),
(274549, 'spell_ascension_wildcard_solar_strike'),
(274550, 'spell_ascension_wildcard_solar_strike'),
(274551, 'spell_ascension_wildcard_solar_strike'),
(274552, 'spell_ascension_wildcard_solar_strike'),
(274553, 'spell_ascension_wildcard_solar_strike'),
(274554, 'spell_ascension_wildcard_solar_strike');
DELETE FROM `spell_bonus_data` WHERE `entry` = 274532;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(274532, 0, 0.02, 0, 0.02, 'Solar Burn: two percent AP and SP per periodic tick');
