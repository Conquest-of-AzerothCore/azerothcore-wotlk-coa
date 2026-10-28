-- Explosive Augmentation (653237) triggers its splash explosion (653238) on ranged hits. Gatling Gun's own
-- shot (500577) is dispatched through a native periodic-trigger-spell aura with a triggered cast, and
-- Aura::GetProcEffectMask refuses to let a non-PROC_ATTR_TRIGGERED_CAN_PROC aura react to any triggered spell
-- unless it is an auto-attack, kill or death event. Mark 653237 as able to proc off a triggered spell, matching
-- the other ranged attacks (Scrap Shot, direct casts) it already procs from.
UPDATE `spell_proc` SET `AttributesMask` = `AttributesMask` | 2 WHERE `SpellId` = 653237;
-- Battleweaver (300733) hits the same Aura::GetProcEffectMask gate: Hammer of Life's heal (806073) is cast
-- as a triggered spell (#9412), so Battleweaver also needs PROC_ATTR_TRIGGERED_CAN_PROC to react to it.
UPDATE `spell_proc` SET `AttributesMask` = `AttributesMask` | 2 WHERE `SpellId` = 300733;
