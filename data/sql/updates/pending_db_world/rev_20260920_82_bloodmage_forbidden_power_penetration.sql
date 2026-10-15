-- Forbidden Power (500445, #651): "Increases your spell critical strike rating by 30% of your Agility and
-- spell hit rating by 5% of your Agility. In addition, you now gain Spell Penetration equal to your Armor
-- Penetration Rating." The two Agility conversions are native and untouched here: effects 0 and 1 are aura
-- 220 (SPELL_AURA_MOD_RATING_FROM_STAT) with MiscValue 1024/128 and MiscValueB 1 (Agility), base points
-- 29/4 -> 30%/5%. Effect 2 is aura 23 (SPELL_AURA_PERIODIC_TRIGGER_SPELL), Amplitude 3000,
-- TriggerSpell 500447. 500447 has DurationIndex 28 (5000 ms, so the 3 s refresh keeps it up) and a single
-- effect: aura 123 (SPELL_AURA_MOD_TARGET_RESISTANCE), MiscValue 124 (SPELL_SCHOOL_MASK_SPELL, i.e. every
-- school except Physical and Holy), raw EffectBasePoints -1 with DieSides 1 -> an amount of 0. The third
-- clause therefore applied a zero-valued aura every three seconds and nothing ever computed the amount.
-- The refresh cycle is what makes a script sufficient: Unit::_TryStackingOrRefreshingExistingAura ->
-- Aura::ModStackAmount -> Aura::SetStackAmount re-runs AuraEffect::CalculateAmount, which calls the
-- script's DoEffectCalcAmount handler, so the amount tracks the current rating every three seconds.
-- The ratio is stated by the tooltip (equal to the Armor Penetration *Rating*), so no value is invented.
-- Spell penetration is a negative amount on this aura: Unit::CalcAbsorbResist adds
-- GetTotalAuraModifierByMiscMask(SPELL_AURA_MOD_TARGET_RESISTANCE, schoolMask) to the victim's resistance,
-- and stock "Increased Spell Penetration 10" (25975) carries EffectBasePoints -11 -> -10.
START TRANSACTION;
DELETE FROM `spell_script_names` WHERE `spell_id` = 500447
    AND `ScriptName` = 'aura_ascension_bloodmage_forbidden_power';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(500447, 'aura_ascension_bloodmage_forbidden_power');
COMMIT;
