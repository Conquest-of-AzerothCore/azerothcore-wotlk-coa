-- Legionfall (801899) rolls its proc chance twice: aura_ascension_felsworn_event::Check (case 801899,
-- AscensionFelswornEvents.cpp) calls Chance(player, 801899), which itself rolls roll_chance_f(info->ProcChance)
-- against the DBC's own tooltip percent, before the native proc system separately rolls CalcProcChance against
-- spell_proc.Chance. rev_20260909_05_felsworn_completion.sql inserted Chance = 100 so the native gate would
-- always pass and the script's own roll would be the only probability; rev_20260919_20_coa_proc_chance_parity.sql
-- later zeroed it along with every other CoA spell_proc row, which makes SpellMgr::LoadSpellProcs fall back to
-- the DBC ProcChance for the native gate too, so the effective proc rate becomes ProcChance^2 instead of
-- ProcChance. Restore Chance = 100 for 801899 only; the parity migration's intent is correct for spells whose
-- script does not already rate-gate itself.
START TRANSACTION;
DELETE FROM `spell_proc` WHERE `SpellId` = 801899;
INSERT INTO `spell_proc` (`SpellId`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `Chance`) VALUES
(801899, 1048575, 7, 2, 63, 2, 100);
COMMIT;
