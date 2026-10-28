-- CoA #7771: 5282 'The Restless Souls' frees Spectral Citizens (10384) with Egan's
-- Blaster. The citizen only reacted to the periodic trigger (17372), so when the
-- blaster's own aura (17368) was the hit that landed, nothing happened. React to
-- either spell so the Freed Soul (17408) is summoned and the citizen despawns.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 10384 AND `source_type` = 0 AND `id` IN (19, 20);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(10384, 0, 19, 20, 8, 0, 100, 1, 17368, 0, 0, 0, 0, 0, 11, 17408, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Spectral Citizen - On Blaster Aura Hit - Summon Freed Soul'),
(10384, 0, 20, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Spectral Citizen - Linked - Despawn');
