-- Blood Frenzy: give the proc a target it can actually use.
--
-- 707899 promises that casting Harvest Time with an enemy targeted within 20 yds unleashes
-- Blood Frenzy. Its record carries ProcTypeMask 0, so rev_20260920_17 gave it a spell_proc
-- row, and rev_20260921_20 widened that row's flags to the ones a beneficial self-cast
-- raises - without which it could not fire at all, because Harvest Time is a buff the Reaper
-- puts on themselves.
--
-- Firing is not enough on its own. That event names the caster as both actor and action
-- target, while the spell the talent triggers - 803039, a Shadow damage-over-time written
-- for an enemy - has nowhere to land. The generic list script cannot help: it only decides
-- whether the spell was the right one. So 707899 moves to its own script, which keeps the
-- Harvest Time check and casts 803039 at the enemy the player has selected, when that enemy
-- is one they may attack and is inside the 20 yds the tooltip states.
--
-- The spell_proc row rev_20260920_17 wrote stays exactly as it is.

DELETE FROM `spell_script_names` WHERE `spell_id` = 707899;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(707899, 'aura_ascension_reaper_blood_frenzy');
