-- Reborn Astral Shift (1151474, 1151478, 1151479) did not reach the stock absorb scripts, so its 10/20/30% damage
-- reduction while stunned, feared or silenced absorbed a flat 10/20/30 points instead. Bind them as stock -51474.
DELETE FROM `spell_script_names` WHERE `spell_id` IN (1151474, 1151478, 1151479) AND `ScriptName` IN ('spell_sha_astral_shift', 'spell_sha_astral_shift_aura');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(1151474, 'spell_sha_astral_shift'),
(1151474, 'spell_sha_astral_shift_aura'),
(1151478, 'spell_sha_astral_shift'),
(1151478, 'spell_sha_astral_shift_aura'),
(1151479, 'spell_sha_astral_shift'),
(1151479, 'spell_sha_astral_shift_aura');
