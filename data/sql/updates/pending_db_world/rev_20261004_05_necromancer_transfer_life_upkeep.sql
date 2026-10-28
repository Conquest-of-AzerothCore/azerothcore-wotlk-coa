DELETE FROM `spell_script_names` WHERE `spell_id` = 801530
AND `ScriptName` IN ('spell_ascension_necromancer_transfer_life', 'aura_ascension_necromancer_transfer_life');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(801530, 'aura_ascension_necromancer_transfer_life');
