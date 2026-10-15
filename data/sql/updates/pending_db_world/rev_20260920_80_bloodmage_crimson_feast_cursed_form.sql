-- Crimson Feast (804602, #3413): "Every 5 second you remain in a Cursed Form now reduces the cooldown of your
-- Bloodsurge by 5 sec." Spell.dbc gives 804602 Attributes 0x1c0 (SPELL_ATTR0_PASSIVE), DurationIndex 21 (-1,
-- infinite) and Stances 0x0, with effect 0 = aura 23 (SPELL_AURA_PERIODIC_TRIGGER_SPELL), Amplitude 5000,
-- TriggerSpell 804603. The triggered half already works with no script: 804603 carries effect 165
-- (SPELL_EFFECT_ASCENSION_MODIFY_COOLDOWN) with MiscValue 553267 (Bloodsurge, RecoveryTime 180000) and raw
-- EffectBasePoints -5001, i.e. -5000 ms, which Spell::EffectAscensionModifyCooldown applies natively.
-- What is missing is the condition: nothing binds the tick to a Cursed Form, so the passive shortened
-- Bloodsurge permanently, out of combat and out of form. Stances is 0, so the native shapeshift gate cannot
-- express it either; the Bloodmage's forms are ordinary auras enumerated by the module's CursedForms[] list.
-- aura_ascension_bloodmage_crimson_feast prevents the periodic default action unless one of those auras is
-- active on the caster. No value is introduced here: the -5000 ms still comes from 804603.
START TRANSACTION;
DELETE FROM `spell_script_names` WHERE `spell_id` = 804602
    AND `ScriptName` = 'aura_ascension_bloodmage_crimson_feast';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(804602, 'aura_ascension_bloodmage_crimson_feast');
COMMIT;
