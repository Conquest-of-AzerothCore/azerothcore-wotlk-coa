-- Ancient Core Hound (11673): like the rest of MC trash, only the base (Normal) entry has any
-- smart_scripts rows at all -- 111673/211673/311673 have none, so Lava Breath/Vicious Bite never run
-- above Normal. This replicates the base kit onto all three variants and adds Melt Armor (2105025,
-- SPELL_AURA_MOD_RESISTANCE_PCT, stacks to 5), the kit's real tank-facing armor debuff that was never
-- wired on any difficulty. The "Ancient Despair/Hysteria/Dread/Fury" self-buff family (2105030-33) and
-- the undecoded action-type-88 row are left unchanged -- see docs/coa/molten-core.md.
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (11673, 111673, 211673, 311673) AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(11673, 0, 0, 0, 0, 0, 100, 0, 10000, 10000, 7000, 7000, 0, 0, 11, 19272, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Ancient Core Hound - In Combat - Cast \'Lava Breath\' (Phase 1) (No Repeat) (All Difficulties)'),
(11673, 0, 1, 0, 0, 0, 100, 0, 4000, 4000, 6000, 6000, 0, 0, 11, 19319, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Ancient Core Hound - In Combat - Cast \'Vicious Bite\' (Phase 1) (No Repeat) (All Difficulties)'),
(11673, 0, 2, 0, 0, 0, 100, 512, 15000, 15000, 24000, 24000, 0, 0, 88, 1167300, 1167305, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Ancient Core Hound - In Combat - Run Random Script (Phase 1) (No Repeat) (All Difficulties)'),
(11673, 0, 3, 0, 0, 0, 100, 0, 8000, 8000, 15000, 15000, 0, 0, 11, 2105025, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Ancient Core Hound - In Combat - Cast \'Melt Armor\' (Phase 1) (No Repeat) (All Difficulties)'),
(111673, 0, 0, 0, 0, 0, 100, 0, 10000, 10000, 7000, 7000, 0, 0, 11, 19272, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Ancient Core Hound (1) - In Combat - Cast \'Lava Breath\' (Phase 1) (No Repeat) (All Difficulties)'),
(111673, 0, 1, 0, 0, 0, 100, 0, 4000, 4000, 6000, 6000, 0, 0, 11, 19319, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Ancient Core Hound (1) - In Combat - Cast \'Vicious Bite\' (Phase 1) (No Repeat) (All Difficulties)'),
(111673, 0, 2, 0, 0, 0, 100, 512, 15000, 15000, 24000, 24000, 0, 0, 88, 1167300, 1167305, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Ancient Core Hound (1) - In Combat - Run Random Script (Phase 1) (No Repeat) (All Difficulties)'),
(111673, 0, 3, 0, 0, 0, 100, 0, 8000, 8000, 15000, 15000, 0, 0, 11, 2105025, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Ancient Core Hound (1) - In Combat - Cast \'Melt Armor\' (Phase 1) (No Repeat) (All Difficulties)'),
(211673, 0, 0, 0, 0, 0, 100, 0, 10000, 10000, 7000, 7000, 0, 0, 11, 19272, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Ancient Core Hound (2) - In Combat - Cast \'Lava Breath\' (Phase 1) (No Repeat) (All Difficulties)'),
(211673, 0, 1, 0, 0, 0, 100, 0, 4000, 4000, 6000, 6000, 0, 0, 11, 19319, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Ancient Core Hound (2) - In Combat - Cast \'Vicious Bite\' (Phase 1) (No Repeat) (All Difficulties)'),
(211673, 0, 2, 0, 0, 0, 100, 512, 15000, 15000, 24000, 24000, 0, 0, 88, 1167300, 1167305, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Ancient Core Hound (2) - In Combat - Run Random Script (Phase 1) (No Repeat) (All Difficulties)'),
(211673, 0, 3, 0, 0, 0, 100, 0, 8000, 8000, 15000, 15000, 0, 0, 11, 2105025, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Ancient Core Hound (2) - In Combat - Cast \'Melt Armor\' (Phase 1) (No Repeat) (All Difficulties)'),
(311673, 0, 0, 0, 0, 0, 100, 0, 10000, 10000, 7000, 7000, 0, 0, 11, 19272, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Ancient Core Hound (3) - In Combat - Cast \'Lava Breath\' (Phase 1) (No Repeat) (All Difficulties)'),
(311673, 0, 1, 0, 0, 0, 100, 0, 4000, 4000, 6000, 6000, 0, 0, 11, 19319, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Ancient Core Hound (3) - In Combat - Cast \'Vicious Bite\' (Phase 1) (No Repeat) (All Difficulties)'),
(311673, 0, 2, 0, 0, 0, 100, 512, 15000, 15000, 24000, 24000, 0, 0, 88, 1167300, 1167305, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Ancient Core Hound (3) - In Combat - Run Random Script (Phase 1) (No Repeat) (All Difficulties)'),
(311673, 0, 3, 0, 0, 0, 100, 0, 8000, 8000, 15000, 15000, 0, 0, 11, 2105025, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Ancient Core Hound (3) - In Combat - Cast \'Melt Armor\' (Phase 1) (No Repeat) (All Difficulties)');
