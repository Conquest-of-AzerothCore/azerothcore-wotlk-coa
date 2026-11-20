-- Freedom to Ruul (6482): Ruul Snowhoof (12818) keeps faction 714 during the escort, which is neutral to the
-- Thistlefur ambushers (faction 82), so IsValidAttackTarget rejects them and he never fights.
-- Switch him to the Horde active escortee faction 232 (FACTION_ESCORTEE_H_NEUTRAL_ACTIVE) on accept and restore
-- the template faction on respawn.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 12818 AND `source_type` = 0 AND `id` IN (20, 21);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
    `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
    `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`,
    `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`,
    `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(12818, 0, 20, 0, 19, 0, 100, 512, 6482, 0, 0, 0, 0, 0, 2, 232, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    'Ruul Snowhoof - On Quest \'Freedom to Ruul\' Taken - Set Faction 232'),
(12818, 0, 21, 0, 11, 0, 100, 512, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    'Ruul Snowhoof - On Respawn - Restore Template Faction');
