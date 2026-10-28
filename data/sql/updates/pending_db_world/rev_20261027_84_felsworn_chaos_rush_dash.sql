--
-- Chaos Rush Jump 802028 skips its native forced-facing charge spline whenever the caster already holds a
-- movement key, applying a run-speed surge instead so the caster's own steered movement carries them the
-- intended distance in the direction they are actually moving, rather than a shorter, facing-only forced
-- displacement (#9397, #9404).
DELETE FROM `spell_script_names` WHERE `spell_id` = 802028 AND `ScriptName` = 'spell_ascension_felsworn_chaos_rush';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (802028, 'spell_ascension_felsworn_chaos_rush');
