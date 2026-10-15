--
-- Tectonic Resonance (#643): apply the extra slow only to Earthquake's slow helper.
SET @ScriptName = 'aura_ascension_tectonic_resonance_slow';
DELETE FROM `spell_script_names` WHERE `spell_id` = 520696 AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (520696, @ScriptName);
