-- Amped Flow (806411) has ProcFlags 0, so its SPELL_AURA_PROC_TRIGGER_SPELL never applied 567556.
-- The Stormflow channel aura now carries the companion buff for as long as it channels, on every rank.
DELETE FROM `spell_script_names` WHERE `spell_id` IN (567555, 572861, 572862, 572863, 572864, 572865, 572866, 572867) AND `ScriptName` = 'aura_ascension_stormflow';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(567555, 'aura_ascension_stormflow'),
(572861, 'aura_ascension_stormflow'),
(572862, 'aura_ascension_stormflow'),
(572863, 'aura_ascension_stormflow'),
(572864, 'aura_ascension_stormflow'),
(572865, 'aura_ascension_stormflow'),
(572866, 'aura_ascension_stormflow'),
(572867, 'aura_ascension_stormflow');

-- Unstable (707222) is SPELLMOD_ACTIVATION_TIME, which AuraEffect::CalculatePeriodic only reads when the
-- periodic data is derived; the script re-derives the running Stormflow tick period on apply and on expiry.
DELETE FROM `spell_script_names` WHERE `spell_id` = 707222 AND `ScriptName` = 'aura_ascension_unstable';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (707222, 'aura_ascension_unstable');
