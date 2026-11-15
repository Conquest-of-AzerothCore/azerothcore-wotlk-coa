-- #12049: Scythe Sweep 500489 (SPELL_ATTR0_SCALES_WITH_CREATURE_LEVEL, spell level 20) is cast by the Reaper's
-- Spectral Scythe guardian. The core skips creature-level scaling for player-controlled casters, so it hit for its
-- level-20 value at every level; live logs (2026-08-04, level 55-60 Reaper) show 104-237 per hit.
DELETE FROM `spell_script_names` WHERE `spell_id` = 500489 AND `ScriptName` = 'spell_ascension_reaper_scythe_sweep';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(500489, 'spell_ascension_reaper_scythe_sweep');
