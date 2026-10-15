-- Azzinoth's Assault (803472) never casts its own Inner Demon duration-extend helper (803089), and 803089's
-- SPELL_EFFECT_ASCENSION_MODIFY_AURA_DURATION effect (misc value 804216, base 2999 + AP*0.4) had no registered
-- handler anywhere in src/server/coa, unlike the equivalent custom effect on Reaper/Witch Hunter/Venomancer.
-- Bind spell_ascension_felsworn_ability to 803089 so AscensionFelswornAbilities.cpp's new ExtendInnerDemon
-- effect handler (registered for this spell id) actually runs.
START TRANSACTION;
DELETE FROM `spell_script_names` WHERE `spell_id` = 803089 AND `ScriptName` = 'spell_ascension_felsworn_ability';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (803089, 'spell_ascension_felsworn_ability');
COMMIT;
