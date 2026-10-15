-- Timeguard (804441): "Place a magical guard on an ally for $d, causing the next 3 instances of direct
-- damage that deal more than 20% of their total health or reduce the target below 35% health to deal
-- $s3% less damage." Effect 0 is aura 69 SPELL_AURA_SCHOOL_ABSORB with EffectBasePoints 1 (die 1 =>
-- an absorb of 2 points) - a placeholder on a 2-minute, 3-charge defensive cooldown. Effects 1 and 2 are
-- SPELL_AURA_DUMMY carrying the tooltip's two numbers, EffectBasePoints 34 (die 1 => 35, the health
-- threshold) and 49 (die 1 => 50, the reduction), and neither had a `spell_script_names` row nor any
-- reference in src/ or modules/, so both did nothing. The record's ProcCharges 3 is the "next 3
-- instances" budget, but with no isTriggerAura effect SpellMgr::LoadSpellProcs generates no proc entry
-- for it, so nothing consumed the charges as a proc - only the 2-point shield could, on the first hit of
-- any size.
-- spell_ascension_timeguard makes effect 0's absorb unbounded (amount -1, the core's "let the script
-- decide" sentinel, which also stops Unit::CalcAbsorbResist from draining and removing the aura) and
-- absorbs effect 2's percent of a direct-damage instance only when that instance clears effect 1's
-- threshold or the tooltip's 20%-of-maximum-health clause, dropping exactly one charge each time. The
-- 20% figure exists only in the description text; no Spell.dbc field carries it.
-- No `spell_proc` row is added: one would override Aura::CalcMaxCharges with the proc entry's own
-- Charges column and take the 3-instance budget away.
DELETE FROM `spell_script_names` WHERE `spell_id` = 804441 AND `ScriptName` = 'spell_ascension_timeguard';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(804441, 'spell_ascension_timeguard');
