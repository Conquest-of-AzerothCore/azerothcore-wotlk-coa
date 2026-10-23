DELETE FROM `spell_script_names`
WHERE (`spell_id` = 1954833 AND `ScriptName` = 'spell_ascension_summoned_effect_ally_area')
   OR (`spell_id` IN (1954834, 1955063, 1955064, 1955065, 1955066, 1955067, 1955068)
       AND `ScriptName` = 'aura_ascension_summoned_effect_tick')
   OR (`spell_id` IN (1954868, 1954869, 1954870, 1954871, 1954872, 1954873)
       AND `ScriptName` = 'spell_ascension_summoned_effect_ally_area');

INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(1954833, 'spell_ascension_summoned_effect_ally_area'),
(1954834, 'aura_ascension_summoned_effect_tick'),
(1955063, 'aura_ascension_summoned_effect_tick'),
(1955064, 'aura_ascension_summoned_effect_tick'),
(1955065, 'aura_ascension_summoned_effect_tick'),
(1955066, 'aura_ascension_summoned_effect_tick'),
(1955067, 'aura_ascension_summoned_effect_tick'),
(1955068, 'aura_ascension_summoned_effect_tick'),
(1954868, 'spell_ascension_summoned_effect_ally_area'),
(1954869, 'spell_ascension_summoned_effect_ally_area'),
(1954870, 'spell_ascension_summoned_effect_ally_area'),
(1954871, 'spell_ascension_summoned_effect_ally_area'),
(1954872, 'spell_ascension_summoned_effect_ally_area'),
(1954873, 'spell_ascension_summoned_effect_ally_area');
