-- Wildcard Frostfall 284664 ticks 284665 every second for 8 s. 284665 is SPELL_EFFECT_DUMMY on enemies within 20 yd
-- whose value (BasePoints 983374 + 1) names the star 983375, exactly like Firefall's 284679 -> 983370, but no script
-- was bound, so the dummy did nothing. Bind the Starfall scripts Firefall already uses: two LOS targets per tick
-- (16 stars over 8 ticks) and a splash 983377 that skips the star's own target.
DELETE FROM `spell_script_names` WHERE `spell_id` = 284665 AND `ScriptName` = 'spell_dru_starfall_dummy';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(284665, 'spell_dru_starfall_dummy');
DELETE FROM `spell_script_names` WHERE `spell_id` = 983377 AND `ScriptName` = 'spell_dru_starfall_aoe';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(983377, 'spell_dru_starfall_aoe');
