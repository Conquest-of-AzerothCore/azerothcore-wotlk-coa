-- Hero: Victorious State (32215) only procs for a player who knows Victory Rush
DELETE FROM `spell_script_names` WHERE `spell_id` = 32215 AND `ScriptName` = 'aura_wildcard_victorious_state';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(32215, 'aura_wildcard_victorious_state');
