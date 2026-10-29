-- Hammer of Life (803973): Aura::GetProcEffectMask drops any triggered, non-auto-attack proc spell unless
-- PROC_ATTR_TRIGGERED_CAN_PROC is set. Wildclaw's offhand copy (504240) is cast via EffectTriggerSpell, so it
-- was silently excluded even though it is melee damage dealt by the Wildwalker, matching the tooltip (#8775).
UPDATE `spell_proc` SET `AttributesMask` = `AttributesMask` | 2 WHERE `SpellId` = 803973;
