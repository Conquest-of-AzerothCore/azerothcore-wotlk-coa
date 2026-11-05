-- Wand Master (524962), the helper Time Is A Circle casts, has three effect 177 slots that extend Paradox Cannon,
-- Flux Emitter and Aether Compression, so Singularity Core (804438) had no slot (#11228): a script extends it too.
DELETE FROM `spell_script_names` WHERE `spell_id` = 524962 AND `ScriptName` = 'spell_ascension_time_is_a_circle';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(524962, 'spell_ascension_time_is_a_circle');
