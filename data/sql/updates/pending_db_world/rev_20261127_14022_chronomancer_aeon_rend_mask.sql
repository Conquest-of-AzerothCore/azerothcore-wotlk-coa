-- #14022: Aeon Rend (583248) shared SpellFamilyMask1 = 4096 (0x1000) with Shifting Chaos AoE (801269).
-- Because SpellInfo::IsAffected checks any matching bit and rev_20261126_13614 enabled PROC_ATTR_TRIGGERED_CAN_PROC,
-- Shifting Chaos AoE hits procced Aeon Rend, casting Chromatic Shard and re-triggering Shifting Chaos in an exponential loop.
-- SpellFamilyFlags[2] = 33554432 (0x02000000) is unique to all 9 Chromatic Shard ranks in Spell.dbc.
DELETE FROM `spell_proc` WHERE `SpellId` = 583248;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(583248, 0, 28, 0, 0, 33554432, 65536, 1, 2, 0, 2, 0, 0, 25, 0, 0);
