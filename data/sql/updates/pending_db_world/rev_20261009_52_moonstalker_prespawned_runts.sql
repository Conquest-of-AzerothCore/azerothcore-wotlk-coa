-- Spawn two runts before combat and preserve owner-specific death cleanup (#4348; depends on #4347).
-- A creature loaded from the creature table runs SMART_EVENT_RESPAWN twice (SmartAI::InitializeAI, then the first
-- Creature::Update), and every pass resets the script. The summon is armed by an event phase that survives resets
-- (phase reset is switched off at AI initialisation): the first pass summons and disarms it, the second finds it
-- disarmed, and the matriarch's death arms it again for its next life.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 2071 AND `source_type` = 0;
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(2071, 0, 0, 3, 11, 1, 100, 0, 0, 0, 0, 0, 0, 0,
    12, 2070, 6, 30000, 0, 0, 0, 202, 3, 2, 1, 0, 0, 0, 0, 0,
    'Moonstalker Matriarch - On Respawn - Summon Two Moonstalker Runts'),
(2071, 0, 1, 4, 6, 0, 100, 0, 0, 0, 0, 0, 0, 0,
    41, 0, 0, 0, 0, 0, 0, 204, 2070, 0, 0, 0, 0, 0, 0, 0,
    'Moonstalker Matriarch - On Death - Despawn Own Moonstalker Runts'),
(2071, 0, 2, 0, 17, 0, 100, 0, 2070, 0, 0, 0, 0, 0,
    89, 10, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0,
    'Moonstalker Matriarch - On Summoned Moonstalker Runt - Wander'),
(2071, 0, 3, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0,
    22, 2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    'Moonstalker Matriarch - Link - Disarm The Respawn Summon'),
(2071, 0, 4, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0,
    22, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    'Moonstalker Matriarch - Link - Arm The Respawn Summon'),
(2071, 0, 5, 6, 37, 0, 100, 0, 0, 0, 0, 0, 0, 0,
    211, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    'Moonstalker Matriarch - On AI Init - Keep The Event Phase Across Resets'),
(2071, 0, 6, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0,
    22, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    'Moonstalker Matriarch - Link - Arm The Respawn Summon');
