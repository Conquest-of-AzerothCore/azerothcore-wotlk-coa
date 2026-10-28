-- Stratholme: Grand Crusader Dathrohan.
--
-- Melee hits half as hard on every difficulty. Fierce Blow (975011, 200 % weapon damage) follows
-- the weapon, so it halves with it (it hit for about 6k).
UPDATE `creature_template` SET `DamageModifier` = 4.3   WHERE `entry` = 10812;   -- was 8.6
UPDATE `creature_template` SET `DamageModifier` = 8.985 WHERE `entry` = 110812;  -- was 17.97
UPDATE `creature_template` SET `DamageModifier` = 20.18 WHERE `entry` = 210812;  -- was 40.36

-- Hour of Judgement at 66 % health instead of 50 %.
UPDATE `smart_scripts` SET `event_param2` = 66
WHERE `entryorguid` = 10812 AND `source_type` = 0 AND `id` = 9010;

-- At 40 % the switch to Balnazzar starts at once. The transform cast now interrupts whatever he
-- is casting (castFlags 3 = interrupt previous + triggered; with 2 alone SmartAI waited until a
-- running Hour of Judgement had finished), and the 1.5 s until the entry changes run in phase 3,
-- where none of Dathrohan's spells fire.
UPDATE `smart_scripts` SET `action_param2` = 3
WHERE `entryorguid` = 10812 AND `source_type` = 0 AND `id` = 5;
UPDATE `smart_scripts` SET `link` = 18
WHERE `entryorguid` = 10812 AND `source_type` = 0 AND `id` = 6;
UPDATE `smart_scripts` SET `event_phase_mask` = 0
WHERE `entryorguid` = 10812 AND `source_type` = 0 AND `id` = 7;

DELETE FROM `smart_scripts` WHERE `entryorguid` = 10812 AND `source_type` = 0 AND `id` = 18;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(10812, 0, 18, 0, 61, 0, 100, 512, 0, 0, 0, 0, 0, 0, 22, 3, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Grand Crusader Dathrohan - Between 0-40% Health - Set Event Phase 3 (no spells until Balnazzar)');
