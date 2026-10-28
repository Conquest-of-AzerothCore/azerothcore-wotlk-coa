-- Ancient Core Hound (11673) fear never fires on a real spawn: Creature::UpdateEntry always
-- `SetEntry(Entry)` to the base template id (Creature.cpp) -- only `m_creatureInfo` switches to the
-- difficulty_entry_1..3 variant for stats, so `GetEntry()` stays 11673 on every difficulty forever.
-- SmartScript::GetScript falls back to `GetScript((int32)me->GetEntry())` (SmartScript.cpp), so a real
-- spawn only ever loads the base entry's own smart_scripts rows, regardless of instance difficulty.
-- rev_20261001_10_molten_core_ancient_core_hound_fear.sql put its Panic (2105309) row on the Mythic/
-- Ascended creature_template entries (211673/311673) only -- dead code on a real spawn. The earlier
-- in-game "pass" used `.npc add temp 311673`, which spawns a temporary creature whose entry really is
-- 311673, so it never exercises this fallback at all -- a flawed test, not a working fix.
-- rev_20261001_03_molten_core_core_hound_melt_armor.sql has the same flaw for rows 0-3 (Lava Breath/
-- Vicious Bite/Random Script/Melt Armor), duplicated onto 111673/211673/311673 as dead, byte-for-byte
-- copies of the base entry's own rows, which already apply on every difficulty (event_flags = 0). Both
-- sets of variant-keyed rows are removed here; the kit (rows 0-3, unchanged) plus the new Panic cast
-- (row 4) are re-asserted on the base entry (11673) alone, with the Panic row gated to Mythic+Ascended
-- via event_flags (SMART_EVENT_FLAG_DIFFICULTY_2 | SMART_EVENT_FLAG_DIFFICULTY_3 = 0x18,
-- SmartScriptMgr.h) -- the pattern already used for difficulty-gated behaviour elsewhere in MC, and the
-- only one that actually reaches a real spawn (SmartScript::FillScript, SmartScript.cpp).
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (111673, 211673, 311673) AND `source_type` = 0;
DELETE FROM `smart_scripts` WHERE `entryorguid` = 11673 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(11673, 0, 0, 0, 0, 0, 100, 0, 10000, 10000, 7000, 7000, 0, 0, 11, 19272, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Ancient Core Hound - In Combat - Cast \'Lava Breath\' (Phase 1) (No Repeat) (All Difficulties)'),
(11673, 0, 1, 0, 0, 0, 100, 0, 4000, 4000, 6000, 6000, 0, 0, 11, 19319, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Ancient Core Hound - In Combat - Cast \'Vicious Bite\' (Phase 1) (No Repeat) (All Difficulties)'),
(11673, 0, 2, 0, 0, 0, 100, 512, 15000, 15000, 24000, 24000, 0, 0, 88, 1167300, 1167305, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Ancient Core Hound - In Combat - Run Random Script (Phase 1) (No Repeat) (All Difficulties)'),
(11673, 0, 3, 0, 0, 0, 100, 0, 8000, 8000, 15000, 15000, 0, 0, 11, 2105025, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Ancient Core Hound - In Combat - Cast \'Melt Armor\' (Phase 1) (No Repeat) (All Difficulties)'),
(11673, 0, 4, 0, 0, 0, 100, 24, 8000, 8000, 40000, 40000, 0, 0, 11, 2105309, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Ancient Core Hound - In Combat - Cast \'Panic\' Fear (Phase 1) (No Repeat) (Mythic+Ascended Only)');
