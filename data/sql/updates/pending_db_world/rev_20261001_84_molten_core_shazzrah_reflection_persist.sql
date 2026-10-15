-- Reflection of Shazzrah (11504, rev_20261001_05) now persists for the whole encounter
-- (boss_shazzrah_coa.cpp summons it with TEMPSUMMON_MANUAL_DESPAWN and the instance script despawns
-- every tracked reflection once DATA_SHAZZRAH leaves IN_PROGRESS) instead of clearing itself a few
-- seconds after spawning, and casts Mirrored Arcane Explosion (2105650) on a repeating cadence rather
-- than once. A real spawn's GetEntry() never becomes a difficulty_entry_1..3 variant
-- (rev_20261001_14/_15's base-entry rule), so only the base entry's smart_scripts row is ever read;
-- this replaces it in place and leaves the already-dead 111504/211504/311504 rows from rev_20261001_05
-- untouched. Cadence: Shazzrah's own measured Arcane Explosion schedule row
-- (03_boss_schedule.sql, 2105601, first 3600ms/period 8400ms) -- the 54-log corpus (74 pulls on entry
-- 11504) never captured a cast interval of its own for 2105650 (every pull logs "casts: 0" for it), so
-- no reflection-specific cadence exists to measure and the boss's own is reused as-is, unstaggered.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 11504 AND `source_type` = 0;
INSERT INTO `smart_scripts`
  (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
     `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
     `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
     `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
     `target_z`, `target_o`, `comment`)
VALUES
(11504, 0, 0, 0, 1, 0, 100, 0, 3600, 3600, 8400, 8400, 0, 0, 11, 2105650, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
 'Reflection of Shazzrah - Out of Combat - Cast \'Mirrored Arcane Explosion\' (repeat)');
