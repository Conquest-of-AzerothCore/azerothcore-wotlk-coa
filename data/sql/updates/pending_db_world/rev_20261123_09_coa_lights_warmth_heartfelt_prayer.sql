-- Light's Warmth (175056): choosing "<You chant a brief prayer.>" credited the prayer at once. The realm made the
-- player cast Heartfelt Prayer (365036, 2 s) on the refugee and credited it when the cast landed
-- (pEoiXrErJ6w 3:15:52-3:16:18, five casts). The human (164068) and dwarf (164541) refugees share the script.
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (164068, 164541) AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
    `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
    `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`,
    `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`,
    `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(164068, 0, 0, 1, 62, 0, 100, 0, 9997000, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Exhausted Refugee - On Gossip Option 0 Selected - Close Gossip'),
(164068, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 134, 365036, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Exhausted Refugee - On Link - Invoker Cast Heartfelt Prayer'),
(164068, 0, 2, 3, 8, 0, 100, 0, 365036, 0, 0, 0, 0, 0, 33, 164068, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Exhausted Refugee - On Spellhit Heartfelt Prayer - Quest Credit Prayers offered'),
(164068, 0, 3, 4, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 83, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Exhausted Refugee - On Link - Remove Gossip Flag'),
(164068, 0, 4, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 67, 1, 60000, 60000, 0, 0, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Exhausted Refugee - On Link - Create Timed Event 1'),
(164068, 0, 5, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0, 0, 82, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Exhausted Refugee - On Timed Event 1 - Add Gossip Flag'),
(164541, 0, 0, 1, 62, 0, 100, 0, 9997000, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Exhausted Refugee - On Gossip Option 0 Selected - Close Gossip'),
(164541, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 134, 365036, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Exhausted Refugee - On Link - Invoker Cast Heartfelt Prayer'),
(164541, 0, 2, 3, 8, 0, 100, 0, 365036, 0, 0, 0, 0, 0, 33, 164068, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Exhausted Refugee - On Spellhit Heartfelt Prayer - Quest Credit Prayers offered'),
(164541, 0, 3, 4, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 83, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Exhausted Refugee - On Link - Remove Gossip Flag'),
(164541, 0, 4, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 67, 1, 60000, 60000, 0, 0, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Exhausted Refugee - On Link - Create Timed Event 1'),
(164541, 0, 5, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0, 0, 82, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Exhausted Refugee - On Timed Event 1 - Add Gossip Flag');
