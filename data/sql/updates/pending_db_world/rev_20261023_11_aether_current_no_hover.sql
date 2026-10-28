-- #5335: Aether Current (531512) stacks FEATHER_FALL, HOVER and WATER_WALK. HOVER puts the client in
-- altitude-hold physics, so the caster cannot steer the fall the tooltip promises. Bind the script that
-- suppresses the HOVER effect while keeping feather fall and water walking.
DELETE FROM `spell_script_names` WHERE `spell_id` = 531512 AND `ScriptName` = 'spell_ascension_stormbringer_aether_current';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(531512, 'spell_ascension_stormbringer_aether_current');
