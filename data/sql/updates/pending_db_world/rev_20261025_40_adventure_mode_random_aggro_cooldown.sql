-- Adventurer Mode Random Aggro (888071) was part of live Adventure Mode (#9031): restore the pulse and honor its
-- 2-minute RecoveryTime, which the triggering difficulty auras otherwise bypass.
DELETE FROM `disables` WHERE `sourceType` = 0 AND `entry` = 888071;
DELETE FROM `spell_script_names` WHERE `spell_id` = 888071 AND `ScriptName` = 'spell_ascension_adventure_mode_random_aggro';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(888071, 'spell_ascension_adventure_mode_random_aggro');
