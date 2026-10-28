-- Chaotic (681376) rolls its proc chance twice, same mechanism as rev_20260928_95_felsworn_legionfall_proc_chance.sql:
-- aura_ascension_felsworn_event::Check (case 681376, AscensionFelswornEvents.cpp) calls Chance(player, 681376),
-- which rolls roll_chance_f(info->ProcChance) itself, before the native proc system separately rolls
-- CalcProcChance against spell_proc.Chance. rev_20260919_20_coa_proc_chance_parity.sql zeroed Chance for 681376
-- along with every other CoA spell_proc row, which makes the native gate fall back to the DBC's 8% ProcChance
-- too, so the effective rate becomes ~0.64% instead of 8%. Restore Chance = 100 for 681376 only.
START TRANSACTION;
DELETE FROM `spell_proc` WHERE `SpellId` = 681376;
INSERT INTO `spell_proc` (`SpellId`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `Chance`) VALUES
(681376, 1048575, 7, 2, 63, 2, 100);
COMMIT;
