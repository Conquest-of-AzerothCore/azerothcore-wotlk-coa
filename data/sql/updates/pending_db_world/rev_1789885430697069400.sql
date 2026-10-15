--
-- Earthmother's Protection (#620): activate the authored Hand cost modifier only while Rock Barrier is active.
DELETE FROM `spell_script_names` WHERE `spell_id` IN (503630, 560298) AND `ScriptName` = 'aura_ascension_earthmother_protection_link';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(503630, 'aura_ascension_earthmother_protection_link'),
(560298, 'aura_ascension_earthmother_protection_link');
