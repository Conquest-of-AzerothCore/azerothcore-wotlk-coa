-- Coagulation (706258, #587): "Your Blood Shield now also dispels 1 bleed effect from you every 5 sec."
-- Spell.dbc gives 706258 Attributes 0x800001C0 (includes 0x40 SPELL_ATTR0_PASSIVE), DurationIndex 21
-- (infinite) and effect 0 = aura 23 (SPELL_AURA_PERIODIC_TRIGGER_SPELL), Amplitude 5000, TriggerSpell 504102.
-- 504102 carries a single effect 108 (SPELL_EFFECT_DISPEL_MECHANIC) with MiscValue 15 (MECHANIC_BLEED) and
-- TargetA 1 (TARGET_UNIT_CASTER). Two halves of the tooltip had no implementation:
--   1. "1 bleed effect": Spell::EffectDispelMechanic only stops after the first match when the effect's raw
--      EffectBasePoints are exactly 1, and Spell.dbc ships 0, so the whole dispel list came off every tick.
--      That is corrected in the module's spell contract hook, not here, because this core has no
--      `spell_dbc` row for the CoA custom range and the guard reads the raw base points.
--   2. "Your Blood Shield": the passive is permanent and its tick was unconditional, so the Bloodmage
--      cleansed bleeds every 5 seconds with or without Blood Shield. Blood Shield is 504296 (SpellFamilyName
--      26, the only family-26 spell of that name in Spell.dbc, granted to class 20 at level 4 by
--      AscensionCustomClassData.h and self-cast: its effects all use TargetA 1). It has no rank chain.
-- aura_ascension_bloodmage_coagulation prevents the periodic default action unless 504296 is on the caster.
START TRANSACTION;
DELETE FROM `spell_script_names` WHERE `spell_id` = 706258
    AND `ScriptName` = 'aura_ascension_bloodmage_coagulation';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(706258, 'aura_ascension_bloodmage_coagulation');
COMMIT;
