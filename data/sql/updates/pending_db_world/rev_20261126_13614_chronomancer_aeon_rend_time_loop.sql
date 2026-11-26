-- #13614: Aeon Rend (583248) did not proc on Chromatic Shards fired by Pure Chaos's Time Loop (807571 -> 807989)
-- because Time Loop casts the owned Chromatic Shard rank as a triggered spell and 583248 had AttributesMask 0.
-- Live CoA logs (2026-08-15-11.24.03) show Aeon Rend restriking Chromatic Shards during Time Loop.
-- Add PROC_ATTR_TRIGGERED_CAN_PROC (2); Aeon Rend's own restrike cannot chain-proc because Restrike passes
-- triggeredByAura (blocked by SpellAuras.cpp:2245) and retains TRIGGERED_DISALLOW_PROC_EVENTS.
DELETE FROM `spell_proc` WHERE `SpellId` = 583248;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(583248, 0, 28, 0, 4096, 33554432, 65536, 1, 2, 0, 2, 0, 0, 25, 0, 0);
