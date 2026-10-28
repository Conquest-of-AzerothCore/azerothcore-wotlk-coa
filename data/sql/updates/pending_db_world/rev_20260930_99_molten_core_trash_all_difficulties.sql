-- Molten Core trash SmartAI restricted to Normal (event_flags=2, SMART_EVENT_FLAG_DIFFICULTY_0) on six
-- entries whose only ability rows are the base/Normal entry's own smart_scripts: Molten Giant (11658),
-- Molten Destroyer (11659), Flamewaker (11661), Firewalker (11666), Flameguard (11667) and Firelord
-- (11668). CoA's four difficulty variants reuse the base entry's SmartAI rows (SmartScript::FillScript
-- filters by event_flags against the map's spawn mode), so the flag silently drops every one of these
-- abilities above Normal. Clearing the difficulty bits (event_flags & ~0x1E) lets them run on all four
-- difficulties, matching every other MC trash type that was already difficulty-agnostic. Spell ids and
-- timers are unchanged; only the difficulty gate is removed. Their spells are vanilla (unscaled) where
-- no CoA variant id exists for this creature -- see docs/coa/molten-core.md.
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (11658, 11659, 11661, 11666, 11667, 11668) AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(11658, 0, 0, 0, 0, 0, 100, 0, 6000, 10000, 7000, 10000, 0, 0, 11, 18944, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 'Molten Giant - In Combat - Cast \'Smash\' (Phase 1) (No Repeat) (All Difficulties)'),
(11658, 0, 1, 0, 0, 0, 100, 0, 6000, 11000, 12000, 16000, 0, 0, 11, 18945, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Molten Giant - In Combat - Cast \'Knock Away\' (Phase 1) (No Repeat) (All Difficulties)'),
(11659, 0, 0, 0, 0, 0, 100, 0, 12000, 12000, 10000, 10000, 0, 0, 11, 20276, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Molten Destroyer - In Combat - Cast \'Knockdown\' (Phase 1) (No Repeat) (All Difficulties)'),
(11659, 0, 1, 0, 0, 0, 100, 0, 18000, 18000, 12000, 12000, 0, 0, 11, 19129, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Molten Destroyer - In Combat - Cast \'Massive Tremor\' (Phase 1) (No Repeat) (All Difficulties)'),
(11661, 0, 0, 0, 0, 0, 100, 0, 3000, 8000, 4000, 6000, 0, 0, 11, 19730, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Flamewaker - In Combat - Cast \'Strike\' (Phase 1) (No Repeat) (All Difficulties)'),
(11661, 0, 1, 0, 0, 0, 100, 0, 3000, 6000, 10000, 13000, 0, 0, 11, 20277, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Flamewaker - In Combat - Cast \'Fist of Ragnaros\' (Phase 1) (No Repeat) (All Difficulties)'),
(11661, 0, 2, 0, 0, 0, 100, 0, 4000, 9000, 5000, 8000, 0, 0, 11, 15502, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Flamewaker - In Combat - Cast \'Sunder Armor\' (Phase 1) (No Repeat) (All Difficulties)'),
(11666, 0, 0, 0, 0, 0, 100, 0, 12000, 12000, 8000, 15000, 0, 0, 11, 19635, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Firewalker - In Combat - Cast \'Incite Flames\' (Phase 1) (No Repeat) (All Difficulties)'),
(11666, 0, 1, 0, 0, 0, 100, 0, 8000, 8000, 15000, 15000, 0, 0, 11, 19636, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Firewalker - In Combat - Cast \'Fire Blossom\' (Phase 1) (No Repeat) (All Difficulties)'),
(11667, 0, 0, 0, 0, 0, 100, 0, 12000, 12000, 10000, 10000, 0, 0, 11, 19630, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Flameguard - In Combat - Cast \'Cone of Fire\' (Phase 1) (No Repeat) (All Difficulties)'),
(11667, 0, 1, 0, 0, 0, 100, 0, 8000, 8000, 15000, 15000, 0, 0, 11, 19631, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Flameguard - In Combat - Cast \'Melt Armor\' (Phase 1) (No Repeat) (All Difficulties)'),
(11668, 0, 0, 0, 0, 0, 100, 0, 4000, 6000, 2000, 4000, 0, 0, 11, 19393, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 'Firelord - In Combat - Cast \'Soul Burn\' (Phase 1) (No Repeat) (All Difficulties)'),
(11668, 0, 1, 0, 0, 0, 100, 0, 10000, 15000, 15000, 15000, 0, 0, 11, 19392, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Firelord - In Combat - Cast \'Summon Lava Spawn\' (Phase 1) (No Repeat) (All Difficulties)');
