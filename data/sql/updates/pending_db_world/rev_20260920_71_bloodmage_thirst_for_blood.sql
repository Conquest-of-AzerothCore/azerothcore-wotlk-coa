-- Thirst for Blood (570023): "Between 1-5 stacks of Thirst: Spell haste increased by $570024s1%.
-- Between 6-10 stacks of Thirst: The bonus damage dealt by spell critical strikes is increased by
-- $570025s1%." Both of the record's effects are aura 4 (SPELL_AURA_DUMMY) with Amplitude 500 and a
-- TriggerSpell (570025 on effect 0, 570024 on effect 1). Aura 4 never ticks - only aura 226
-- (SPELL_AURA_PERIODIC_DUMMY) is wired into AuraEffect::PeriodicTick - and a TriggerSpell on a dummy
-- aura is inert data that nothing forwards, so neither tier was ever applied. The module converts
-- effect 0 to aura 226, keeping the record's own 500 ms amplitude, and this script reads the live
-- Thirst (706613) stack count on every tick. The amounts stay in the payloads: 570024 "Sated" is
-- SPELL_AURA_HASTE_SPELLS 10%, 570025 "Ravenous" is SPELL_AURA_MOD_CRIT_DAMAGE_BONUS 100% plus its own
-- SPELL_EFFECT_REMOVE_AURA on 570024, which is what keeps the two tiers mutually exclusive.
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'aura_ascension_bloodmage_thirst_for_blood';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(570023, 'aura_ascension_bloodmage_thirst_for_blood');
