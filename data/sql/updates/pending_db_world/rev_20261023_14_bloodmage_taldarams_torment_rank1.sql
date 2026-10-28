-- Taldaram's Torment rank 1 (800772) was the one rank missing from
-- rev_20260930_01_bloodmage_taldarams_torment_rage.sql, which registered
-- aura_ascension_bloodmage_taldarams_torment for ranks 2-8 (802568-802573, 802580) only.
-- 800772 is the first rank every Bloodmage learns (spell_ranks first_spell_id 800772 rank 1,
-- DBC spellLevel 2) and its effect layout is identical to the registered ranks: EFFECT_0 is
-- aura 3 SPELL_AURA_PERIODIC_DAMAGE (Amplitude 3000, EffectTriggerSpell 0) and EFFECT_1 is
-- aura 308 SPELL_AURA_MOD_CRIT_CHANCE_FOR_CASTER. Without a row the periodic ticks never run
-- the OnEffectPeriodic hook, so the spell deals its damage but generates no Rage. Reported on
-- #8680 by a level-8 Bloodmage, who can only know rank 1.
-- Registering the negative first rank covers the whole chain through ObjectMgr::LoadSpellScriptNames
-- (GetFirstSpellInChain/GetNextRankSpell, after LoadSpellRanks), so no rank can be missed again.
-- The explicit positive rows are removed in the same statement: leaving them would attach the
-- same script twice to ranks 2-8 and double the Rage they generate per tick.
DELETE FROM `spell_script_names` WHERE `spell_id` IN
    (800772, 802568, 802569, 802570, 802571, 802572, 802573, 802580, -800772)
    AND `ScriptName` = 'aura_ascension_bloodmage_taldarams_torment';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(-800772, 'aura_ascension_bloodmage_taldarams_torment');
