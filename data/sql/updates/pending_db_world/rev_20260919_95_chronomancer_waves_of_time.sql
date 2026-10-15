-- Waves of Time (801277): "Blast enemies in a frontal cone with time fractals, knocking them back
-- slightly. The knockback repeats 1 additional time after 2 sec." Two knockbacks are promised; one
-- ships. Effect 0 is Effect=183 SPELL_EFFECT_ASCENSION_TRIGGER_SPELL_DELAYED, BasePoints 1999
-- (die 1 => a 2000 ms delay), Trigger 802600, TargetA 1 (caster): Spell::EffectAscensionTriggerSpellDelayed
-- schedules exactly one delayed cast, so this is the "repeats 1 additional time after 2 sec" half and
-- it works. Effect 1 is Effect=64 SPELL_EFFECT_TRIGGER_SPELL, TargetA 24 TARGET_UNIT_CONE_ENEMY_24,
-- Trigger 65633 - Arcane Cast Visual, SpellFamilyName 3, a single SPELL_EFFECT_DUMMY with no handler
-- and no script anywhere in src/ - so nothing at all happens at cast time.
-- 802600 is the knockback itself: Effect=98 SPELL_EFFECT_KNOCK_BACK, BasePoints 69, Misc 150,
-- TargetA 24 with radius index 13 (10 yd). It selects its own cone, which is why the delayed half
-- casts it once on the caster rather than once per enemy.
-- spell_ascension_waves_of_time casts 802600 the same way at cast time, restoring the first knockback.
-- A spell_dbc override repointing effect 1's trigger from 65633 to 802600 is deliberately not used:
-- effect 1 is cone-targeted, so 802600 would be cast once per enemy in the cone and each enemy would
-- take one knockback per enemy hit.
DELETE FROM `spell_script_names` WHERE `spell_id` = 801277 AND `ScriptName` = 'spell_ascension_waves_of_time';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(801277, 'spell_ascension_waves_of_time');
