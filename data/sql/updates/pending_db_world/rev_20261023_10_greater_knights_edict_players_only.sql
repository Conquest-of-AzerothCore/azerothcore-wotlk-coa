-- #4733: Greater Knight's Edict (523510) is a raid area aura, so its 40 yard effect also landed on
-- the caster's Shadowhound and any other guardian. Bind a script that drops non-player targets so the
-- buff reaches raid members only, as the tooltip describes.
DELETE FROM `spell_script_names` WHERE `spell_id` = 523510 AND `ScriptName` = 'spell_ascension_witch_hunter_greater_knights_edict';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(523510, 'spell_ascension_witch_hunter_greater_knights_edict');
