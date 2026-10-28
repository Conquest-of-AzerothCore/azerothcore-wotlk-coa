-- Molten Core boss kit completions: Lucifron's Impending Doom and Suppressing Shadows landing
-- spell, Golemagg's Magma Splash/Molten Armor/Cave In. Sources: coa_boss_schedule (measured, 42
-- Ascension logs) for existing rows; CoA's creature.json kit export for the spell ids each boss
-- actually carries; the live server-data Spell.dbc and SpellDifficulty.dbc (parsed directly this
-- session, /srv/coa/server-data/dbc) for effect/aura/target/duration and per-difficulty families;
-- mc-addons-report.md's DBM-Warmane vanilla cross-check for Lucifron's "Doom" timer. No timer
-- exists in the 42 logs for any row added here; each such row is tagged [designed] or [dbm].
--
-- SpellDifficulty.dbc already carries every family this file needs (rows 2093, 2095, 2105, 2122,
-- 2125 verified live: 2105201->02->03->04, 2105219->20->21->22, 2105411->12->13->14,
-- 2105802->03->04->05, 2105825->26->27->28) -- no new spelldifficulty_dbc row is required.
--
-- Not changed here (reported, not fixed):
-- - Gehennas 12259: Unquenchable Flames (2105411-14) is not a missing cast -- Rain of Fire
--   (2105407, already scheduled) triggers it itself via its own EffectTriggerSpell (effect
--   slot 1). Curse of Gehennas's mana-burn-on-dispel pair (2105423/2105424) is a dispel proc,
--   not a plain timed cast; the schedule engine (CoaBossAI.cpp) has no proc hook, so no row
--   is added for it.
-- - Golemagg 11988: Yank (2105852, effect type 124, a chain-pull mechanic) has no plain cast/aura
--   reading; not addable through coa_boss_schedule without inventing engine behaviour, so no row
--   is added.
-- - Cindermaw 11672 (Golemagg's add): kit spell Stress (2105858, a self-stacking damage/attack-
--   speed aura) exists, but 11672's creature_template.ScriptName is npc_core_rager
--   (boss_golemagg.cpp, a full ScriptedAI CreatureScript), which always wins AI resolution over
--   SmartAI -- smart_scripts rows for 11672 would be inert. No SmartAI data is added; this is a
--   C++-scope item for whoever owns boss_golemagg.cpp.

DELETE FROM `coa_boss_schedule` WHERE (`entry` = 12118 AND `idx` = 3) OR (`entry` = 12118 AND `idx` = 4)
  OR (`entry` = 11988 AND `idx` = 3) OR (`entry` = 11988 AND `idx` = 4) OR (`entry` = 11988 AND `idx` = 5);
INSERT INTO `coa_boss_schedule`
  (`entry`, `idx`, `spell_d0`, `spell_d1`, `spell_d2`, `spell_d3`, `effect`, `first_ms`, `period_ms`, `hp_pct`, `target`, `comment`)
VALUES
-- Lucifron (12118): idx3 already existed (measured); only its `effect` column changes, from 0 to
-- the Suppressing Shadows damage family's base id (2105219, already difficulty-resolved by
-- SpellDifficulty.dbc row 2095) -- the logs recorded the debuff cast but never its landing hit.
(12118, 3, 2105218, 2105218, 2105218, 2105218, 2105219, 29200, 25100, 0, 3, 'Suppressing Shadows [designed: landing spell]'),
-- idx4 is new: Impending Doom (2105201, SpellDifficulty row 2093) was never seen in any of the 5
-- probe/legacy runs sampled for Lucifron and has no row at all in the base schedule file --
-- structurally absent, not a sampling gap. Timer taken from DBM-Warmane's vanilla Lucifron "Doom"
-- (19702, CD 20s, first cast 7s) as the nearest evidenced analogue; effect fires the dummy's own
-- EffectTriggerSpell payload (2105205) the moment the cast completes, same pattern as every other
-- dummy-plus-effect row in this table.
(12118, 4, 2105201, 2105201, 2105201, 2105201, 2105205, 7000, 20000, 0, 3, 'Impending Doom [dbm]'),
-- Golemagg (11988): three kit spells with no schedule row at any difficulty. All three read as
-- plain targeted casts from Spell.dbc (no proc/passive framing fits their EffectImplicitTargetA);
-- families are clean ascending siblings already covered by SpellDifficulty.dbc rows 2122/2125.
-- No log ever recorded any of these -- timers are [designed], picked to not collide with the
-- boss's existing Fierce Blow/Lava Burst/Massive Stomp cadence.
(11988, 3, 2105802, 2105802, 2105802, 2105802, 0, 10000, 18000, 0, 0, 'Magma Splash [designed]'),
(11988, 4, 2105806, 2105806, 2105806, 2105806, 0, 16000, 32000, 0, 0, 'Molten Armor [designed]'),
(11988, 5, 2105825, 2105825, 2105825, 2105825, 0, 35000, 55000, 0, 3, 'Cave In [designed]');
