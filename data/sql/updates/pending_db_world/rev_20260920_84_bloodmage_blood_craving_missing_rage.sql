-- Blood Craving (800780, #649): "You crave blood for 12 sec, for the duration you cannot be interrupted or
-- silenced, and you regain 5% of your maximum health and 15% of your missing Rage every 2 sec."
-- Spell.dbc gives 800780 DurationIndex 29 (12000 ms) with effects 0 and 2 = aura 77
-- (SPELL_AURA_MECHANIC_IMMUNITY) with MiscValue 9 (MECHANIC_SILENCE) and 26 (MECHANIC_INTERRUPT) - the
-- "cannot be interrupted or silenced" half, fully native - and effect 1 = aura 23
-- (SPELL_AURA_PERIODIC_TRIGGER_SPELL) at Amplitude 2000 triggering 805985, i.e. six ticks.
-- 805985 effect 0 = SPELL_EFFECT_HEAL_PCT, base 4 -> 5%: Spell::EffectHealPct heals
-- CountPctFromMaxHealth, which is exactly what the tooltip promises. That half is native and untouched.
-- 805985 effect 1 = SPELL_EFFECT_ENERGIZE_PCT, MiscValue 1 (POWER_RAGE), MiscValueB 1, base 14 -> 15%.
-- Spell::EffectEnergizePct computes CalculatePct(unitTarget->GetMaxPower(power), damage) - a percentage of
-- *maximum* Rage, where the Description, the AuraDescription and the reference tooltip all say *missing*
-- Rage. MiscValueB is not read by that handler and there is no Ascension "energize missing pct" effect.
-- spell_ascension_bloodmage_blood_craving replaces that one effect with CalculatePct(max - current, 15).
-- The 15% is the record's own value; nothing is introduced.
START TRANSACTION;
DELETE FROM `spell_script_names` WHERE `spell_id` = 805985
    AND `ScriptName` = 'spell_ascension_bloodmage_blood_craving';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(805985, 'spell_ascension_bloodmage_blood_craving');
COMMIT;
