-- Registers spell_basalthane.cpp's SpellScripts against their spell ids.
-- Without these rows, RegisterSpellScript's ScriptMgr lookup never finds a
-- script for these spells, so Annihilation Strike/Inferno Trail/Eruption
-- (all bare SPELL_EFFECT_DUMMY in Spell.dbc) do nothing, and the
-- inferno-trail-hit-visual-only override never suppresses the hit spells'
-- native damage. Was only ever applied by hand via mysql CLI on the live
-- dev DB, never saved as a migration until now.

DELETE FROM `spell_script_names` WHERE `spell_id` IN (2105077,2105078,2105079,2105080,2108206,2108217,2108219,2108220,2108221,2108222,2108227);
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (2105077, 'spell_basalthane_eruption_explosion'),
    (2105078, 'spell_basalthane_eruption_explosion'),
    (2105079, 'spell_basalthane_eruption_explosion'),
    (2105080, 'spell_basalthane_eruption_explosion'),
    (2108206, 'spell_basalthane_annihilation_strike'),
    (2108217, 'spell_basalthane_inferno_trail'),
    (2108219, 'spell_basalthane_inferno_trail_hit_visual_only'),
    (2108220, 'spell_basalthane_inferno_trail_hit_visual_only'),
    (2108221, 'spell_basalthane_inferno_trail_hit_visual_only'),
    (2108222, 'spell_basalthane_inferno_trail_hit_visual_only'),
    (2108227, 'spell_basalthane_eruption');
