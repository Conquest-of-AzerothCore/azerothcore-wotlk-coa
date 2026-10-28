-- `spell_script_names` for Basalthane's custom spells (Annihilation Strike, Eruption,
-- Inferno Trail, their hidden hit/explosion spells) was never actually inserted on this
-- DB - rev_20260930_02 only ever ran against `acore_world`, not `acore_world2`, and the
-- gap went unnoticed because nothing exercised the pillar-shatter/tank-debuff path in a
-- way that made the missing logic obvious until now. Without these rows, AzerothCore
-- never invokes the matching SpellScript at all - the visible SPELL_EFFECT_DUMMY cast
-- still plays (that part is native DBC behavior), but none of the real hit damage,
-- debuffs, or pillar-shatter logic inside HandleDummy ever runs.
INSERT IGNORE INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
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

-- Stale pre-C++-rewrite SmartAI rows at the per-difficulty entries (10190/91/92 -
-- Heroic/Mythic/Ascended) for Annihilation Strike/Eruption/Inferno Trail. Each of these
-- three abilities was moved from SmartAI to C++ scheduling at various points, but that
-- work only ever touched the base entry (10189) - smart_scripts is looked up by the
-- CURRENTLY ACTIVE difficulty-swapped entry, not just the spawn's base entry, so the
-- 10190-92 copies (old timings: Annihilation every 17s, Inferno Trail every 10s,
-- Eruption 39s/56s - all superseded by confirmed-from-logs/C++ values) kept firing
-- unnoticed on every difficulty except Normal. Idempotent: DELETE is naturally safe to
-- replay.
DELETE FROM `smart_scripts`
WHERE `entryorguid` IN (10190, 10191, 10192) AND `source_type` = 0 AND `id` IN (1, 2, 21)
  AND `action_param1` IN (2108217, 2108227, 2108206);
