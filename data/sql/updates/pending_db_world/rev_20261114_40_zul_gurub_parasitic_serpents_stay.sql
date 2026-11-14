-- Parasitic Serpents stay until killed so Corpse Explosion finds their corpses (tester round 7, 2026-11-14): the stock
-- Parasitic Serpent proc (23867 -> 23865) made each serpent evade and despawn on its first hit. Only the CoA
-- Poisonous Fangs row from rev_20261025_88 stays.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 14884 AND `source_type` = 0;
INSERT INTO `smart_scripts` (
    `entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`,
    `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`,
    `target_z`, `target_o`, `comment`
) VALUES
(14884, 0, 4, 0, 25, 0, 100, 0, 0, 0, 0, 0, 0, 0, 11,
    2118075, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
    'Parasitic Serpent - On Reset - Cast \'Poisonous Fangs\'');
