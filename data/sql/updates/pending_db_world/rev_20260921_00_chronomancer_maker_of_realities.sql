-- Maker of Realities (#3151): Hasten grants its caster the existing healing cast-time buff 712454.
-- Hasten is positive MAGIC: DONE_SPELL_MAGIC_DMG_CLASS_POS (16384), family 28, word-0 bit 0x10000000.
-- ALLOW_CAST_WHILE_CASTING makes even ordinary Hasten casts IsTriggered(), so the CAST phase is skipped.
-- Use FINISH (4) and TRIGGERED_CAN_PROC (2), with Maker's DBC chance of 100% and native aura-42 payload.
DELETE FROM `spell_proc` WHERE `SpellId` = 707656;
INSERT INTO `spell_proc`
(`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`,
 `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`,
 `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
(707656, 0, 28, 268435456, 0, 0, 16384, 4, 4, 0, 2, 0, 0, 100, 0, 0);
