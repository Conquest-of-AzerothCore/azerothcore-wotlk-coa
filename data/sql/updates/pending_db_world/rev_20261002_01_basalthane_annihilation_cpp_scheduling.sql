-- Annihilation Strike's cast scheduling moved from SmartAI to C++ (see
-- spell_basalthane.cpp's annihilationNextCast handling in
-- allcreaturescript_basalthane_cleanup::OnAllCreatureUpdate). This is the only
-- way Cracked Armor's real "extends Annihilation Strike/Eruption cooldowns by
-- 20s" interaction (found via WeakAuras decode) can actually nudge the timer -
-- AzerothCore's SmartScript::GetEvents() only exposes a const reference, there
-- is no public API to adjust a running SmartAI timer from outside.
--
-- Cadence is unchanged (18-24s random, same range for opener and every
-- repeat, matching this row's own event_param1-4), only *what drives it*
-- changes. Idempotent: DELETE is naturally safe to replay.
DELETE FROM `smart_scripts`
WHERE `entryorguid` = 10189 AND `source_type` = 0 AND `id` = 21 AND `action_param1` = 2108206;
