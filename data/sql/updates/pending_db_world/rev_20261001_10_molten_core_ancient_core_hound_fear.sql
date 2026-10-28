-- Ancient Core Hound (11673): add a fear ability on Mythic/Ascended only, modeled on Magmadar's
-- own fear. Magmadar's body casts real fear in live play as Panic (2105309, SPELL_AURA_MOD_FEAR,
-- self + area-enemy target), not the vanilla donor id (19408) its C++ still runs, and not the
-- never-fired Bellowing Roar/Ancient Despair-Fury-Hysteria-Dread family (2105308/2105310-13) --
-- see .agents/plans/mc-restoration/research-H3.md. The hound's own kit has no fear id on any
-- difficulty (action-type-88's random pool is Ground Stomp/Cauterizing Flames/Withering
-- Heat/Ancient Despair/Ancient Hysteria/Ancient Dread -- Confuse and stat debuffs, not Fear).
-- This fork gates MC trash by difficulty via separate creature_template entries (11673/111673/
-- 211673/311673), so adding the new row only to 211673 (Mythic) and 311673 (Ascended) -- leaving
-- 11673/111673 untouched -- is sufficient to restrict it to Mythic+Ascended; no event_flags
-- difficulty bit is needed on top of the per-entry split. Cadence (first ~8s, repeat 40s flat) is
-- designed, borrowed from Magmadar's own measured ~40s-flat Panic cadence -- no corpus evidence
-- exists for the hound's own fear timing, since it has never cast one.
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (211673, 311673) AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(211673, 0, 0, 0, 0, 0, 100, 0, 10000, 10000, 7000, 7000, 0, 0, 11, 19272, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Ancient Core Hound (2) - In Combat - Cast \'Lava Breath\' (Phase 1) (No Repeat) (All Difficulties)'),
(211673, 0, 1, 0, 0, 0, 100, 0, 4000, 4000, 6000, 6000, 0, 0, 11, 19319, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Ancient Core Hound (2) - In Combat - Cast \'Vicious Bite\' (Phase 1) (No Repeat) (All Difficulties)'),
(211673, 0, 2, 0, 0, 0, 100, 512, 15000, 15000, 24000, 24000, 0, 0, 88, 1167300, 1167305, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Ancient Core Hound (2) - In Combat - Run Random Script (Phase 1) (No Repeat) (All Difficulties)'),
(211673, 0, 3, 0, 0, 0, 100, 0, 8000, 8000, 15000, 15000, 0, 0, 11, 2105025, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Ancient Core Hound (2) - In Combat - Cast \'Melt Armor\' (Phase 1) (No Repeat) (All Difficulties)'),
(211673, 0, 4, 0, 0, 0, 100, 0, 8000, 8000, 40000, 40000, 0, 0, 11, 2105309, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Ancient Core Hound (2) - In Combat - Cast \'Panic\' Fear (Phase 1) (No Repeat) (Mythic Only)'),
(311673, 0, 0, 0, 0, 0, 100, 0, 10000, 10000, 7000, 7000, 0, 0, 11, 19272, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Ancient Core Hound (3) - In Combat - Cast \'Lava Breath\' (Phase 1) (No Repeat) (All Difficulties)'),
(311673, 0, 1, 0, 0, 0, 100, 0, 4000, 4000, 6000, 6000, 0, 0, 11, 19319, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Ancient Core Hound (3) - In Combat - Cast \'Vicious Bite\' (Phase 1) (No Repeat) (All Difficulties)'),
(311673, 0, 2, 0, 0, 0, 100, 512, 15000, 15000, 24000, 24000, 0, 0, 88, 1167300, 1167305, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Ancient Core Hound (3) - In Combat - Run Random Script (Phase 1) (No Repeat) (All Difficulties)'),
(311673, 0, 3, 0, 0, 0, 100, 0, 8000, 8000, 15000, 15000, 0, 0, 11, 2105025, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Ancient Core Hound (3) - In Combat - Cast \'Melt Armor\' (Phase 1) (No Repeat) (All Difficulties)'),
(311673, 0, 4, 0, 0, 0, 100, 0, 8000, 8000, 40000, 40000, 0, 0, 11, 2105309, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Ancient Core Hound (3) - In Combat - Cast \'Panic\' Fear (Phase 1) (No Repeat) (Ascended Only)');
